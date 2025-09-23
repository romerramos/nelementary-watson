-- Simplified text extraction module
local words = require("nelementary-watson.words")
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")

local M = {}

-- Get selected text from visual mode
function M.get_visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	if start_pos[2] == 0 or end_pos[2] == 0 then
		return nil
	end

	local start_line, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_line, end_col = end_pos[2] - 1, end_pos[3] - 1

	local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)

	if #lines == 0 then return nil end

	if #lines == 1 then
		return lines[1]:sub(start_col + 1, end_col + 1)
	else
		lines[1] = lines[1]:sub(start_col + 1)
		lines[#lines] = lines[#lines]:sub(1, end_col + 1)
		return table.concat(lines, "\n")
	end
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
	json_content = json_content:gsub(',"', ',\n  "'):gsub('^{', '{\n  '):gsub('}$', '\n}')

	vim.fn.writefile(vim.split(json_content, '\n'), file_path)
end

-- Replace selected text in buffer
function M.replace_selection(replacement)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local start_line, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_line, end_col = end_pos[2] - 1, end_pos[3] - 1

	if start_line == end_line then
		local line = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]
		local new_line = line:sub(1, start_col) .. replacement .. line:sub(end_col + 2)
		vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, {new_line})
	else
		local first_line = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]
		local last_line = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1]
		local new_line = first_line:sub(1, start_col) .. replacement .. last_line:sub(end_col + 2)
		vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, {new_line})
	end
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
		"{m." .. key .. "()}"
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

