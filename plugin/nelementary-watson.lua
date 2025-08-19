-- Nelson Elementary Watson - Neovim Paraglide Plugin
-- Plugin entry point

if vim.g.loaded_nelementary_watson then
  return
end
vim.g.loaded_nelementary_watson = 1

-- Set up autocommands for supported file types
local group = vim.api.nvim_create_augroup("NElementaryWatson", { clear = true })

-- File types to monitor
local supported_filetypes = { "javascript", "typescript", "svelte" }

-- Create autocommands for each supported file type
for _, ft in ipairs(supported_filetypes) do
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = ft,
    callback = function()
      require("nelementary-watson").attach_to_buffer()
    end,
  })
end

-- Also attach to existing buffers with supported file types
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.api.nvim_buf_get_option(buf, "filetype")
    
    if vim.tbl_contains(supported_filetypes, ft) then
      require("nelementary-watson").attach_to_buffer()
    end
  end,
})