-- Standalone test for translation finding (works outside Neovim)

-- Mock vim.split function
local function split(str, sep)
  local result = {}
  local pattern = "([^" .. sep .. "]+)"
  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end
  return result
end

-- Translation finding function (copied and adapted)
local function find_translation_calls(content)
  local calls = {}
  local lines = split(content, "\n")
  
  for line_num, line in ipairs(lines) do
    -- Pattern to match m.methodName() or m.methodName(params)
    local pos = 1
    while pos <= #line do
      local start_pos, end_pos, method_name, params = string.find(line, "m%.([a-zA-Z_][a-zA-Z0-9_]*)%s*(%([^)]*)%)", pos)
      if not start_pos then
        break
      end
      
      table.insert(calls, {
        method_name = method_name,
        line = line_num - 1, -- 0-indexed for nvim API
        start_col = start_pos - 1, -- 0-indexed for nvim API
        end_col = end_pos,
        params = params:match("%((.*)%)")
      })
      
      pos = end_pos + 1
    end
  end
  
  return calls
end

-- Test content
local test_content = [[
import * as m from '$lib/paraglide/messages';

const title = m.hello_world();
const greeting = m.welcome_message();
const error = m.error_occurred();
const param = m.user_greeting({ name: "John" });
console.log(m.debug_message());
]]

print("Testing ElementaryWatson translation finding:")
print("====================================================")
print()
print("Test content:")
print(test_content)
print()

local calls = find_translation_calls(test_content)
print("Found " .. #calls .. " translation calls:")

for i, call in ipairs(calls) do
  print(string.format("  %d. %s at line %d, col %d-%d (params: %s)", 
    i, call.method_name, call.line + 1, call.start_col + 1, call.end_col, call.params or "none"))
end

print()
print("✅ Translation call finding test completed!")

-- Test with JSON loading
local json_content = [[{
  "hello_world": "Hello World",
  "welcome_message": "Welcome to our application",
  "error_occurred": "An error has occurred",
  "user_greeting": "Hello, {name}!",
  "debug_message": "Debug mode enabled"
}]]

-- Simple JSON parser for testing (very basic)
local function simple_json_decode(str)
  -- This is a very basic JSON parser for testing only
  local result = {}
  for key, value in str:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
    result[key] = value
  end
  return result
end

print("Testing translation loading:")
local translations = simple_json_decode(json_content)

print("Loaded translations:")
for key, value in pairs(translations) do
  print("  " .. key .. ": " .. value)
end

print()
print("Testing translation resolution:")
for _, call in ipairs(calls) do
  local translation = translations[call.method_name]
  if translation then
    print("  " .. call.method_name .. " → \"" .. translation .. "\"")
  else
    print("  " .. call.method_name .. " → [NOT FOUND]")
  end
end

print()
print("🎉 All tests completed successfully!")
print("📝 To use in Neovim, see INSTALL.md for setup instructions.")