local group = vim.api.nvim_create_augroup("lumen_user_config", { clear = true })

-- Highlight text after yanking so copy feedback is visible.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 180 })
  end,
})

-- Reload files changed outside Neovim when focus returns.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = group,
  command = "checktime",
})

-- Trim trailing whitespace for common code/text files.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.lua", "*.js", "*.ts", "*.tsx", "*.py", "*.rs", "*.go", "*.swift", "*.md", "*.json", "*.yaml", "*.yml" },
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
