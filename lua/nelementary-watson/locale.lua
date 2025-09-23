-- Locale management module
local config = require("nelementary-watson.config")
local utils = require("nelementary-watson.utils")

local M = {}

-- Current locale override (set via command)
local current_locale_override = nil

-- Load inlang project settings
function M.load_inlang_settings(workspace_root)
	local settings_path = workspace_root .. "/project.inlang/settings.json"

	if not utils.file_exists(settings_path) then
		return nil
	end

	local content = utils.read_file(settings_path)
	if not content then
		return nil
	end

	local success, settings = pcall(vim.json.decode, content)
	if not success then
		return nil
	end

	return settings
end

-- Get translation path pattern from inlang settings
function M.get_translation_path_pattern(workspace_root)
	local settings = M.load_inlang_settings(workspace_root)

	if settings and settings["plugin.inlang.messageFormat"] and settings["plugin.inlang.messageFormat"].pathPattern then
		return settings["plugin.inlang.messageFormat"].pathPattern
	end

	-- Fallback pattern
	return "./messages/{locale}.json"
end

-- Resolve translation file path for a locale
function M.resolve_translation_path(workspace_root, locale_code)
	local pattern = M.get_translation_path_pattern(workspace_root)

	-- Replace {locale} placeholder
	local relative_path = pattern:gsub("{locale}", locale_code)

	-- Handle relative paths
	if relative_path:sub(1, 2) == "./" then
		relative_path = relative_path:sub(3)
	elseif relative_path:sub(1, 1) == "/" then
		relative_path = relative_path:sub(2)
	end

	return workspace_root .. "/" .. relative_path
end

-- Get current locale with priority order
function M.get_current_locale(workspace_root)
	-- 1. Check manual override
	if current_locale_override then
		return current_locale_override
	end

	-- 2. Check inlang settings base locale
	local settings = M.load_inlang_settings(workspace_root)
	if settings and settings.baseLocale then
		return settings.baseLocale
	end

	-- 3. Use configured default
	return config.options.default_locale
end

-- Set current locale override
function M.set_current_locale(locale_code)
	current_locale_override = locale_code
end

-- Get available locales from inlang settings or by scanning directory
function M.get_available_locales(workspace_root)
	local locales = {}

	-- First try inlang settings
	local settings = M.load_inlang_settings(workspace_root)
	if settings and settings.locales then
		return settings.locales
	end

	-- Fallback: scan messages directory
	local pattern = M.get_translation_path_pattern(workspace_root)
	local dir_path = pattern:gsub("/{locale}%.json$", "")

	if dir_path:sub(1, 2) == "./" then
		dir_path = workspace_root .. "/" .. dir_path:sub(3)
	else
		dir_path = workspace_root .. "/" .. dir_path
	end

	-- Use vim.loop to scan directory
	local handle = vim.loop.fs_scandir(dir_path)
	if handle then
		while true do
			local name, type = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			if type == "file" and name:match("%.json$") then
				local locale = name:gsub("%.json$", "")
				table.insert(locales, locale)
			end
		end
	end

	-- Sort locales
	table.sort(locales)

	return locales
end

return M

