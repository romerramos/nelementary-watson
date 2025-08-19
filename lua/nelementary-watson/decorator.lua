-- Virtual text decorator module
local config = require("nelementary-watson.config")

local M = {}

-- Namespace for virtual text
local namespace = vim.api.nvim_create_namespace("nelementary_watson")

-- Apply decorations to buffer
function M.apply_decorations(buf, results)
  -- Clear existing decorations
  M.clear_buffer(buf)
  
  -- Apply new decorations
  for _, result in ipairs(results) do
    vim.api.nvim_buf_set_extmark(buf, namespace, result.line, result.col, {
      virt_text = {{" → " .. result.text, config.options.hl_group}},
      virt_text_pos = "inline",
    })
  end
end

-- Clear decorations for buffer
function M.clear_buffer(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
  end
end

-- Clear all decorations
function M.clear_all()
  -- Get all buffers and clear decorations
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    M.clear_buffer(buf)
  end
end

return M