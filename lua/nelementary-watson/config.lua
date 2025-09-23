-- Configuration module
local M = {}

-- Default configuration
M.defaults = {
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
}

-- Current options (will be set by setup)
M.options = {}

-- Setup function
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M

