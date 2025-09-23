# NElementary Watson - Neovim Paraglide Plugin

A Neovim plugin for displaying inline translation values from Paraglide JS i18n method calls. Shows actual translation text next to `m.methodName()` calls using virtual text.

Inspired by the VSCode ElementaryWatson extension, this is a simple, focused Neovim implementation that provides essential translation preview functionality.

## Features

- **Inline Translation Display**: Shows translation values as virtual text next to `m.methodName()` calls
- **Text Extraction**: Extract hard-coded strings to translation keys with `<leader>i` (visual mode)
- **inlang Project Support**: Automatically detects and uses inlang project configuration
- **Multi-language Support**: Works with multiple locales with easy switching
- **Real-time Updates**: Updates translations as you type (configurable)
- **Flexible Configuration**: Configurable locale, styling, and update behavior
- **Lightweight**: Pure Lua implementation with minimal dependencies

## Requirements

- Neovim 0.5+ (for virtual text support)
- JavaScript/TypeScript/Svelte project with Paraglide JS setup
- Translation files in JSON format

## Quick Demo

```bash
# Clone and test the plugin
cd nelementary-watson
lua test/standalone_test.lua  # Test core functionality
./demo.sh                    # View plugin structure and test files
```

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "romerramos/nelementary-watson",
  config = function()
    require("nelementary-watson").setup({
      default_locale = "en",
      update_in_insert = true,
      -- other options...
    })
  end,
}
```

## Configuration

```lua
require("nelementary-watson").setup({
  -- Default locale to display (fallback if not found in inlang settings)
  default_locale = "en",
  
  -- Whether to update translations while typing in insert mode
  update_in_insert = true,
  
  -- Debounce delay for updates (milliseconds)
  update_delay = 300,
  
  -- Virtual text highlighting group
  hl_group = "Comment",
  
  -- Enable debug logging
  debug = false,
})
```

## Supported File Types

- JavaScript (`.js`)
- TypeScript (`.ts`)
- Svelte (`.svelte`)

## Project Structure Support

### inlang Projects (Recommended)

The plugin automatically reads `project.inlang/settings.json` to:
- Use the `pathPattern` from `plugin.inlang.messageFormat` for locating translation files
- Use the `baseLocale` as the default display locale

### Simple Messages Directory (Fallback)

If no inlang configuration is found, falls back to:
- `./messages/{locale}.json` structure
- "en" as the default locale

## How It Works

1. Scans for `m.methodName()` calls in supported file types
2. Loads translation files based on inlang configuration or fallback structure
3. Displays translation values as virtual text with configurable styling
4. Updates in real-time as you edit the code

## Example

```javascript
import * as m from '$lib/paraglide/messages';

const title = m.hello_world();        // → "Hello World"
const greeting = m.welcome_message(); // → "Welcome, User"
```

## Text Extraction

### Usage
1. Select text in visual mode
2. Press `<leader>i` to extract to translation key
3. Plugin generates unique snake_case key (e.g., `blue_mountain_swift_river`)
4. Adds entry to current locale's JSON file (e.g., `messages/en.json`)
5. Replaces selected text with appropriate function call

### Smart Replacement
- **JS/TS files**: `m.generated_key()`
- **Svelte files**: `{m.generated_key()}`
- **Other files**: Prompts for format choice

### Commands
- `<leader>i` (visual mode): Extract selected text
- `:ElementaryWatsonExtract`: Alternative extraction command
- `:ElementaryWatsonChangeLocale`: Change display locale

## License

MIT
