-- Simple test script for the plugin
-- Run this in Neovim with :luafile test/test_plugin.lua

print("Testing ElementaryWatson Plugin")
print("======================================")

-- Add plugin to path
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":p:h:h")
package.path = package.path .. ";" .. plugin_path .. "/lua/?.lua"

-- Initialize plugin
local plugin = require("nelementary-watson")

-- Setup with test configuration
plugin.setup({
  default_locale = "en",
  update_in_insert = true,
  update_delay = 100, -- Faster for testing
  hl_group = "Comment",
  debug = true,
})

print("Plugin initialized with test configuration")

-- Test translation finding
local translation = require("nelementary-watson.translation")

local test_content = [[
import * as m from '$lib/paraglide/messages';

const title = m.hello_world();
const greeting = m.welcome_message();
const error = m.error_occurred();
]]

print("\nTesting translation call finding:")
local calls = translation.find_translation_calls(test_content)
print("Found " .. #calls .. " translation calls:")

for i, call in ipairs(calls) do
  print(string.format("  %d. %s at line %d, col %d-%d", 
    i, call.method_name, call.line + 1, call.start_col + 1, call.end_col))
end

-- Test locale functionality
local locale = require("nelementary-watson.locale")
local workspace_root = plugin_path .. "/test"

print("\nTesting locale functionality:")
print("Workspace root: " .. workspace_root)

local current_locale = locale.get_current_locale(workspace_root)
print("Current locale: " .. current_locale)

local available_locales = locale.get_available_locales(workspace_root)
print("Available locales: " .. table.concat(available_locales, ", "))

-- Test translation loading
print("\nTesting translation loading:")
local translations = translation.load_translations(workspace_root, current_locale)

if translations then
  print("Loaded translations for " .. current_locale .. ":")
  local count = 0
  for key, value in pairs(translations) do
    count = count + 1
    if count <= 5 then -- Show first 5
      print("  " .. key .. ": " .. value)
    end
  end
  if count > 5 then
    print("  ... and " .. (count - 5) .. " more")
  end
else
  print("Failed to load translations")
end

print("\nTest completed! Open test/sample.js or test/sample.svelte to see the plugin in action.")
print("Use :ElementaryWatsonChangeLocale to switch between locales.")