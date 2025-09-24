-- Translation processing module
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")

local M = {}

-- Find all m.methodName() calls in text
-- Returns array of { method_name, line, start_col, end_col }
function M.find_translation_calls(content)
	local calls = {}
	local lines = vim.split(content, "\n")

	for line_num, line in ipairs(lines) do
		-- Pattern to match m.methodName() or m.methodName(params)
		-- Using pattern to find method calls
		local pos = 1
		while pos <= #line do
			local start_pos, end_pos, method_name, params =
				string.find(line, "m%.([a-zA-Z_][a-zA-Z0-9_]*)%s*(%([^)]*)%)", pos)
			if not start_pos then
				break
			end

			table.insert(calls, {
				method_name = method_name,
				line = line_num - 1, -- 0-indexed for nvim API
				start_col = start_pos - 1, -- 0-indexed for nvim API
				end_col = end_pos,
				params = params:match("%((.*)%)"),
			})

			pos = end_pos + 1
		end
	end

	return calls
end

-- Load translations for a specific locale
function M.load_translations(workspace_root, locale_code)
	local translation_path = locale.resolve_translation_path(workspace_root, locale_code)

	if not utils.file_exists(translation_path) then
		return nil
	end

	local content = utils.read_file(translation_path)
	if not content then
		return nil
	end

	-- Parse JSON
	local success, translations = pcall(vim.json.decode, content)
	if not success then
		return nil
	end

	return translations
end

-- Get translation value for a specific key
function M.get_translation_value(translations, key)
	if not translations or not translations[key] then
		return nil
	end

	local value = translations[key]

	-- Case 1: Simple string value
	if type(value) == "string" then
		return value
	end

	-- Case 2: Paraglide variant array (simplified handling)
	if type(value) == "table" and value[1] and value[1].match then
		local first_variant = value[1]
		local match_values = {}

		for _, v in pairs(first_variant.match) do
			table.insert(match_values, v)
		end

		if #match_values > 0 then
			return match_values[1] .. "*" -- Mark as variant with asterisk
		end
	end

	return nil
end

-- Process translation calls with translations
function M.process_translation_calls(calls, translations)
	local results = {}

	for _, call in ipairs(calls) do
		local value = M.get_translation_value(translations, call.method_name)
		if value then
			table.insert(results, {
				line = call.line,
				start_col = call.start_col,
				end_col = call.end_col,
				method_name = call.method_name,
				translation_value = value,
			})
		end
	end

	return results
end

-- Check which locales are missing a translation for a specific key
function M.get_missing_locales_for_key(workspace_root, available_locales, key)
	local missing = {}

	for _, locale_code in ipairs(available_locales) do
		local translations = M.load_translations(workspace_root, locale_code)
		if not translations or not M.get_translation_value(translations, key) then
			table.insert(missing, locale_code)
		end
	end

	return missing
end

-- Process translation calls with missing locales information
function M.process_translation_calls_with_missing(calls, translations, workspace_root, available_locales, current_locale)
	local results = {}

	for _, call in ipairs(calls) do
		local value = M.get_translation_value(translations, call.method_name)
		if value then
			local missing_locales = M.get_missing_locales_for_key(workspace_root, available_locales, call.method_name)
			-- Filter out current locale from missing list
			local filtered_missing = {}
			for _, locale in ipairs(missing_locales) do
				if locale ~= current_locale then
					table.insert(filtered_missing, locale)
				end
			end

			table.insert(results, {
				line = call.line,
				start_col = call.start_col,
				end_col = call.end_col,
				method_name = call.method_name,
				translation_value = value,
				missing_locales = filtered_missing,
			})
		end
	end

	return results
end

return M

