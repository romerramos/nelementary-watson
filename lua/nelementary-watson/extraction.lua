-- Text extraction and replacement module
local words = require("nelementary-watson.words")
local translation = require("nelementary-watson.translation")
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")
local config = require("nelementary-watson.config")

local M = {}

-- Get the currently selected text in visual mode
function M.get_visual_selection()
	-- Get the start and end positions of the visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- Extract line and column numbers (1-indexed)
	local start_line = start_pos[2] - 1 -- Convert to 0-indexed
	local start_col = start_pos[3] - 1 -- Convert to 0-indexed
	local end_line = end_pos[2] - 1 -- Convert to 0-indexed
	local end_col = end_pos[3] -- End column is inclusive in visual mode

	-- Get the selected lines
	local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)

	if #lines == 0 then
		return nil, nil, nil
	end

	-- Handle single line selection
	if #lines == 1 then
		local selected_text = lines[1]:sub(start_col + 1, end_col)
		return selected_text, { start_line, start_col }, { end_line, end_col }
	end

	-- Handle multi-line selection
	local selected_text = {}
	for i, line in ipairs(lines) do
		if i == 1 then
			-- First line: from start_col to end
			table.insert(selected_text, line:sub(start_col + 1))
		elseif i == #lines then
			-- Last line: from beginning to end_col
			table.insert(selected_text, line:sub(1, end_col))
		else
			-- Middle lines: entire line
			table.insert(selected_text, line)
		end
	end

	return table.concat(selected_text, "\n"), { start_line, start_col }, { end_line, end_col }
end

-- Determine the appropriate replacement text based on file type
function M.get_replacement_text(key, file_path)
	-- Get file extension
	local ext = file_path:match("%.([^%.]+)$")

	if ext == "ts" or ext == "js" then
		-- TypeScript/JavaScript: direct function call
		return "m." .. key .. "()"
	elseif ext == "svelte" then
		-- Svelte: template interpolation
		return "{m." .. key .. "()}"
	else
		-- For other file types, ask user
		return M.prompt_for_replacement_format(key)
	end
end

-- Prompt user for replacement format for unknown file types
function M.prompt_for_replacement_format(key)
	local choices = {
		"Direct: m." .. key .. "()",
		"Template: {m." .. key .. "()}",
		"Custom format"
	}

	local choice = nil
	vim.ui.select(choices, {
		prompt = "Choose replacement format:",
	}, function(selected)
		choice = selected
	end)

	-- Wait for the selection (this is a simple blocking approach)
	vim.wait(5000, function()
		return choice ~= nil
	end)

	if not choice then
		return "m." .. key .. "()" -- Default fallback
	end

	if choice:match("^Direct:") then
		return "m." .. key .. "()"
	elseif choice:match("^Template:") then
		return "{m." .. key .. "()}"
	else
		-- Custom format - prompt for input
		local custom = vim.fn.input("Enter custom format (use KEY as placeholder): ")
		if custom and custom ~= "" then
			return custom:gsub("KEY", key)
		else
			return "m." .. key .. "()" -- Fallback
		end
	end
end

-- Add a new translation entry to the JSON file
function M.add_translation_entry(workspace_root, key, value)
	local current_locale = locale.get_current_locale(workspace_root)
	local translation_path = locale.resolve_translation_path(workspace_root, current_locale)

	-- Load existing translations
	local translations = translation.load_translations(workspace_root, current_locale) or {}

	-- Add new entry
	translations[key] = value

	-- Convert to JSON
	local json_content = vim.json.encode(translations)

	-- Format JSON nicely (basic indentation)
	json_content = M.format_json(json_content)

	-- Write to file
	local file = io.open(translation_path, "w")
	if not file then
		error("Could not open translation file for writing: " .. translation_path)
	end

	file:write(json_content)
	file:close()

	if config.options.debug then
		print("ElementaryWatson: Added translation '" .. key .. "' = '" .. value .. "' to " .. translation_path)
	end
end

-- Basic JSON formatting (add indentation)
function M.format_json(json_str)
	-- This is a simple formatter - just add newlines and indentation
	local formatted = json_str:gsub("{", "{\n")
	formatted = formatted:gsub("}", "\n}")
	formatted = formatted:gsub(",", ",\n")

	-- Add indentation
	local lines = vim.split(formatted, "\n")
	local indented_lines = {}
	local indent_level = 0

	for _, line in ipairs(lines) do
		local trimmed = line:match("^%s*(.-)%s*$")

		-- Decrease indent for closing braces
		if trimmed:match("^}") then
			indent_level = math.max(0, indent_level - 1)
		end

		-- Add appropriate indentation
		local indent = string.rep("  ", indent_level)
		table.insert(indented_lines, indent .. trimmed)

		-- Increase indent for opening braces
		if trimmed:match("{$") then
			indent_level = indent_level + 1
		end
	end

	return table.concat(indented_lines, "\n")
end

-- Replace the selected text with the function call
function M.replace_selection(start_pos, end_pos, replacement_text)
	local start_line, start_col = start_pos[1], start_pos[2]
	local end_line, end_col = end_pos[1], end_pos[2]

	-- For single line replacement
	if start_line == end_line then
		local line = vim.api.nvim_buf_get_lines(0, start_line, start_line + 1, false)[1]
		local new_line = line:sub(1, start_col) .. replacement_text .. line:sub(end_col + 1)
		vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { new_line })
	else
		-- Multi-line replacement
		local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
		local first_line = lines[1]:sub(1, start_col) .. replacement_text
		local last_line = lines[#lines]:sub(end_col + 1)
		local new_line = first_line .. last_line

		vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, { new_line })
	end
end

-- Main extraction function
function M.extract_text_to_translation()
	-- Get workspace root
	local workspace_root = utils.get_workspace_root()
	if not workspace_root then
		print("ElementaryWatson: No workspace found")
		return
	end

	-- Get visual selection
	local selected_text, start_pos, end_pos = M.get_visual_selection()
	if not selected_text or selected_text == "" then
		print("ElementaryWatson: No text selected")
		return
	end

	-- Trim whitespace
	selected_text = selected_text:match("^%s*(.-)%s*$")

	-- Generate unique key
	local key = words.generate_unique_key(workspace_root)

	-- Get current file path
	local file_path = vim.api.nvim_buf_get_name(0)

	-- Determine replacement text based on file type
	local replacement_text = M.get_replacement_text(key, file_path)

	-- Add translation entry
	local success, err = pcall(M.add_translation_entry, workspace_root, key, selected_text)
	if not success then
		print("ElementaryWatson: Error adding translation: " .. err)
		return
	end

	-- Replace selected text
	M.replace_selection(start_pos, end_pos, replacement_text)

	print("ElementaryWatson: Extracted '" .. selected_text .. "' as '" .. key .. "'")
end

return M