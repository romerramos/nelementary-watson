-- Utility functions
local M = {}

-- Check if file exists
function M.file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "file"
end

-- Read file content
function M.read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()

	return content
end

-- Get workspace root for buffer
function M.get_workspace_root(buf)
	buf = buf or vim.api.nvim_get_current_buf()

	-- Get buffer path
	local buf_path = vim.api.nvim_buf_get_name(buf)
	if buf_path == "" then
		return nil
	end

	-- Find git root or use vim's current directory
	local git_root = vim.fn.systemlist(
		"git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(buf_path, ":h")) .. " rev-parse --show-toplevel 2>/dev/null"
	)[1]

	if git_root and git_root ~= "" then
		return git_root
	end

	-- Fallback to current working directory
	return vim.fn.getcwd()
end

-- Debug print helper
function M.debug_print(msg)
	local config = require("nelementary-watson.config")
	if config.options.debug then
		print("ElementaryWatson: " .. msg)
	end
end

return M

