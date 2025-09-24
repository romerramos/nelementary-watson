-- Simplified text extraction module
local words = require("nelementary-watson.words")
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")
local Range = require("u.range")

local M = {}

-- Get selected text from visual mode
function M.get_visual_selection()
	local range = Range.from_vtext()
	if range:is_empty() then
		return nil
	end
	return range:text()
end

-- Add translation using vim functions (preserves formatting better)
function M.add_translation_to_file(file_path, key, value)
	-- Create directory if it doesn't exist
	local dir = vim.fn.fnamemodify(file_path, ":h")
	vim.fn.mkdir(dir, "p")

	-- Read existing content or create empty object
	local translations = {}
	if utils.file_exists(file_path) then
		local content = utils.read_file(file_path)
		if content and content ~= "" then
			local success, data = pcall(vim.json.decode, content)
			if success and data then
				translations = data
			end
		end
	end

	-- Add new translation
	translations[key] = value

	-- Write back with basic formatting
	local json_content = vim.json.encode(translations)
	-- Simple formatting: add newlines and indentation
	json_content = json_content:gsub(',"', ',\n  "'):gsub("^{", "{\n  "):gsub("}$", "\n}")

	vim.fn.writefile(vim.split(json_content, "\n"), file_path)
end

-- Replace selected text in buffer
function M.replace_selection(replacement)
	local range = Range.from_vtext()
	if range:is_empty() then
		return
	end
	range:replace(replacement)
end

-- Main extraction function
function M.extract_text()
	-- Get workspace root
	local workspace_root = utils.get_workspace_root()
	if not workspace_root then
		print("ElementaryWatson: No workspace found")
		return
	end

	-- Get selected text
	local selected_text = M.get_visual_selection()
	if not selected_text or selected_text == "" then
		print("ElementaryWatson: No text selected")
		return
	end

	-- Trim whitespace
	selected_text = selected_text:match("^%s*(.-)%s*$")

	-- Generate unique key
	local key = words.generate_unique_key(workspace_root)

	-- Get translation file path
	local current_locale = locale.get_current_locale(workspace_root)
	local translation_path = locale.resolve_translation_path(workspace_root, current_locale)

	-- Add to translation file
	local success, err = pcall(M.add_translation_to_file, translation_path, key, selected_text)
	if not success then
		print("ElementaryWatson: Error adding translation: " .. err)
		return
	end

	-- Present format options to user
	local format_options = {
		"m." .. key .. "()",
		"{m." .. key .. "()}",
	}

	vim.ui.select(format_options, {
		prompt = "Choose replacement format:",
	}, function(choice)
		if choice then
			M.replace_selection(choice)
			print("ElementaryWatson: Extracted '" .. selected_text .. "' as '" .. key .. "'")
		end
	end)
end

return M
