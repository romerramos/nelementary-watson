-- Simple text extraction and replacement module
local words = require("nelementary-watson.words")
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")

local M = {}

-- Simple function to get selected text when command is triggered
function M.get_simple_selection()
	-- Get visual selection positions
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Check if we have valid positions
	if start_pos[2] == 0 or end_pos[2] == 0 then
		return nil
	end

	-- Get the lines (convert to 0-indexed for API)
	local start_line = start_pos[2] - 1
	local end_line = end_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_col = end_pos[3] - 1

	-- Get selected lines
	local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)

	if #lines == 0 then
		return nil
	end

	-- Handle single line
	if #lines == 1 then
		return lines[1]:sub(start_col + 1, end_col + 1)
	end

	-- Handle multiple lines
	local result = {}
	for i, line in ipairs(lines) do
		if i == 1 then
			table.insert(result, line:sub(start_col + 1))
		elseif i == #lines then
			table.insert(result, line:sub(1, end_col + 1))
		else
			table.insert(result, line)
		end
	end

	return table.concat(result, "\n")
end

-- Simple function to add key/value to JSON file
function M.add_to_json_file(file_path, key, value)
	local translations = {}

	-- Read existing file if it exists
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*a")
		file:close()

		if content and content ~= "" then
			local success, data = pcall(vim.json.decode, content)
			if success and data then
				translations = data
			end
		end
	end

	-- Add new translation
	translations[key] = value

	-- Write back to file
	local json_string = vim.json.encode(translations)

	file = io.open(file_path, "w")
	if not file then
		error("Could not open file for writing: " .. file_path)
	end

	file:write(json_string)
	file:close()
end

-- Simple function to replace selected text in current buffer
function M.replace_text_in_buffer(replacement_text)
	-- Get positions again
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line = start_pos[2] - 1
	local end_line = end_pos[2] - 1
	local start_col = start_pos[3] - 1
	local end_col = end_pos[3] - 1

	-- Simple replacement
	if start_line == end_line then
		-- Single line
		local line = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]
		local new_line = line:sub(1, start_col) .. replacement_text .. line:sub(end_col + 2)
		vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { new_line })
	else
		-- Multiple lines - replace with single line
		local first_line = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]
		local last_line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]

		local new_line = first_line:sub(1, start_col) .. replacement_text .. last_line:sub(end_col + 2)
		vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, { new_line })
	end
end

-- Determine replacement format based on file extension
function M.get_replacement_format(key, file_path)
	local ext = file_path:match("%.([^%.]+)$")

	if ext == "ts" or ext == "js" then
		return "m." .. key .. "()"
	elseif ext == "svelte" then
		return "{m." .. key .. "()}"
	else
		return "m." .. key .. "()" -- default
	end
end

-- Main extraction function - simple and straightforward
function M.extract_text_to_translation()
	-- 1. Get workspace root
	local workspace_root = utils.get_workspace_root()
	if not workspace_root then
		print("ElementaryWatson: No workspace found")
		return
	end

	-- 2. Capture selection
	local selected_text = M.get_simple_selection()
	if not selected_text or selected_text == "" then
		print("ElementaryWatson: No text selected")
		return
	end

	-- Trim whitespace
	selected_text = selected_text:match("^%s*(.-)%s*$")

	-- 3. Generate key
	local key = words.generate_unique_key(workspace_root)

	-- 4. Get current file path and determine replacement format
	local file_path = vim.api.nvim_buf_get_name(0)
	local replacement_text = M.get_replacement_format(key, file_path)

	-- 5. Add to JSON file
	local current_locale = locale.get_current_locale(workspace_root)
	local translation_path = locale.resolve_translation_path(workspace_root, current_locale)

	local success, err = pcall(M.add_to_json_file, translation_path, key, selected_text)
	if not success then
		print("ElementaryWatson: Error adding translation: " .. err)
		return
	end

	-- 6. Replace text in buffer
	M.replace_text_in_buffer(replacement_text)

	-- 7. Done!
	print("ElementaryWatson: Extracted '" .. selected_text .. "' as '" .. key .. "'")
end

return M

