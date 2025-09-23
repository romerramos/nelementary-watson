-- ElementaryWatson - Main module
local M = {}

-- Import submodules
local config = require("nelementary-watson.config")
local translation = require("nelementary-watson.translation")
local locale = require("nelementary-watson.locale")
local decorator = require("nelementary-watson.decorator")
local utils = require("nelementary-watson.utils")

-- Plugin state
local timer = nil
local attached_buffers = {}

-- Setup function called by user
function M.setup(opts)
	config.setup(opts or {})

	if config.options.debug then
		print("ElementaryWatson: Plugin initialized")
	end
end

-- Attach to current buffer
function M.attach_to_buffer()
	local buf = vim.api.nvim_get_current_buf()

	-- Skip if already attached
	if attached_buffers[buf] then
		return
	end

	-- Mark as attached
	attached_buffers[buf] = true

	-- Process immediately
	M.process_buffer(buf)

	-- Set up buffer autocommands
	local group = vim.api.nvim_create_augroup("NElementaryWatsonBuffer" .. buf, { clear = true })

	-- Process on text changes (with debouncing)
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = buf,
		callback = function()
			M.schedule_update(buf)
		end,
	})

	-- Process on save
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		buffer = buf,
		callback = function()
			M.process_buffer(buf)
		end,
	})

	-- Clean up when buffer is deleted
	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		buffer = buf,
		callback = function()
			attached_buffers[buf] = nil
			decorator.clear_buffer(buf)
		end,
	})

	if config.options.debug then
		print("ElementaryWatson: Attached to buffer " .. buf)
	end
end

-- Schedule an update with debouncing
function M.schedule_update(buf)
	-- Cancel existing timer
	if timer then
		timer:stop()
		timer:close()
	end

	-- Don't update in insert mode if disabled
	local mode = vim.api.nvim_get_mode().mode
	if mode == "i" and not config.options.update_in_insert then
		return
	end

	-- Create new timer
	timer = vim.loop.new_timer()
	timer:start(
		config.options.update_delay,
		0,
		vim.schedule_wrap(function()
			M.process_buffer(buf)
			timer:close()
			timer = nil
		end)
	)
end

-- Process a buffer to find and display translations
function M.process_buffer(buf)
	-- Ensure buffer is valid
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Find translation calls
	local calls = translation.find_translation_calls(content)

	if #calls == 0 then
		decorator.clear_buffer(buf)
		return
	end

	-- Get workspace root
	local workspace_root = utils.get_workspace_root(buf)
	if not workspace_root then
		if config.options.debug then
			print("ElementaryWatson: No workspace root found")
		end
		return
	end

	-- Get current locale
	local current_locale = locale.get_current_locale(workspace_root)

	-- Load translations
	local translations = translation.load_translations(workspace_root, current_locale)
	if not translations then
		if config.options.debug then
			print("ElementaryWatson: No translations found for locale " .. current_locale)
		end
		decorator.clear_buffer(buf)
		return
	end

	-- Process calls and create decorations
	local results = {}
	for _, call in ipairs(calls) do
		local value = translation.get_translation_value(translations, call.method_name)
		if value then
			table.insert(results, {
				line = call.line,
				col = call.end_col,
				text = '"' .. value .. '"',
				method_name = call.method_name,
			})
		end
	end

	-- Apply decorations
	decorator.apply_decorations(buf, results)

	if config.options.debug then
		print(string.format("ElementaryWatson: Processed %d translation calls, displayed %d", #calls, #results))
	end
end

-- Command to change locale
function M.change_locale()
	local workspace_root = utils.get_workspace_root()
	if not workspace_root then
		print("ElementaryWatson: No workspace found")
		return
	end

	local current_locale = locale.get_current_locale(workspace_root)
	local available_locales = locale.get_available_locales(workspace_root)

	if #available_locales == 0 then
		print("ElementaryWatson: No locales found")
		return
	end

	vim.ui.select(available_locales, {
		prompt = "Select locale (current: " .. current_locale .. "):",
	}, function(choice)
		if choice and choice ~= current_locale then
			locale.set_current_locale(choice)
			-- Refresh all attached buffers
			for buf, _ in pairs(attached_buffers) do
				if vim.api.nvim_buf_is_valid(buf) then
					M.process_buffer(buf)
				end
			end
			print("ElementaryWatson: Locale changed to " .. choice)
		end
	end)
end

-- Create user commands
vim.api.nvim_create_user_command("ElementaryWatsonChangeLocale", M.change_locale, {
	desc = "Change translation locale",
})

return M

