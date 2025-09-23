# Changelog

## [1.0.0] - Initial Release

### Added

- Core translation call detection for `m.methodName()` pattern
- Inline virtual text display of translation values
- Support for JavaScript, TypeScript, and Svelte files
- inlang project configuration support (`project.inlang/settings.json`)
- Fallback to simple `messages/{locale}.json` structure
- Real-time updates with configurable debouncing
- Locale switching with `:ElementaryWatsonChangeLocale` command
- Configurable virtual text styling
- Debug mode for troubleshooting

### Features

- **Pattern Matching**: Detects `m.methodName()` and `m.methodName(params)` calls
- **Translation Loading**: Loads JSON translation files with error handling
- **Virtual Text**: Shows translations as `→ "translation value"` next to code
- **Locale Management**: Auto-detects from inlang settings or uses fallback
- **Performance**: Debounced updates to avoid excessive processing
- **Configuration**: Flexible options for behavior and styling

### Supported File Types

- JavaScript (`.js`)
- TypeScript (`.ts`)
- Svelte (`.svelte`)

### Project Structure Support

1. **inlang projects** with `project.inlang/settings.json`
2. **Simple structure** with `messages/{locale}.json`

### Technical Details

- Pure Lua implementation
- Uses Neovim's virtual text API (requires 0.5+)
- Modular architecture with separate concerns
- Autocommands for file type detection and buffer changes
- Namespace-based virtual text management for clean cleanup

