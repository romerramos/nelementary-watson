# Installation Guide

## Prerequisites

- Neovim 0.5 or later (for virtual text support)
- A JavaScript/TypeScript/Svelte project with Paraglide JS setup
- Translation files in JSON format

## Installation Methods

### Using lazy.nvim (Recommended)

Add to your lazy.nvim configuration:

```lua
{
  -- Replace with the actual path to your plugin
  dir = "/path/to/nelementary-watson",
  config = function()
    require("nelementary-watson").setup({
      default_locale = "en",
      update_in_insert = true,
      update_delay = 300,
      hl_group = "Comment",
      debug = false,
    })
  end,
  -- Only load for supported file types
  ft = { "javascript", "typescript", "svelte" },
}
```

### Manual Installation

1. Clone or copy the plugin to your Neovim configuration directory:
   ```bash
   cp -r nelementary-watson ~/.config/nvim/lua/
   ```

2. Add to your `init.lua`:
   ```lua
   require("nelementary-watson").setup({
     default_locale = "en",
     -- other options...
   })
   ```

### Using Packer

```lua
use {
  "path/to/nelementary-watson",
  config = function()
    require("nelementary-watson").setup()
  end,
  ft = { "javascript", "typescript", "svelte" },
}
```

## Quick Test

1. Open the test directory: `cd nelementary-watson/test`
2. Start Neovim: `nvim sample.js`
3. Run the test script: `:luafile test_plugin.lua`
4. Open `sample.js` or `sample.svelte` to see translations displayed

## Project Structure

For the plugin to work correctly, your project should have either:

### Option 1: inlang Project (Recommended)
```
your-project/
├── project.inlang/
│   └── settings.json
├── messages/
│   ├── en.json
│   └── es.json
└── src/
    └── your-code.js
```

### Option 2: Simple Messages Directory
```
your-project/
├── messages/
│   ├── en.json
│   └── es.json
└── src/
    └── your-code.js
```

## Troubleshooting

### Translations not showing
1. Check that your project has the correct structure
2. Verify translation files exist and contain valid JSON
3. Enable debug mode: `require("nelementary-watson").setup({ debug = true })`
4. Check Neovim messages: `:messages`

### Performance issues
1. Increase update delay: `update_delay = 500`
2. Disable insert mode updates: `update_in_insert = false`

### Virtual text not visible
1. Check highlighting group: `hl_group = "DiagnosticHint"`
2. Verify Neovim version supports virtual text (0.5+)

## Commands

- `:ElementaryWatsonChangeLocale` - Change the current locale for translation display

## Configuration Options

See README.md for full configuration options.