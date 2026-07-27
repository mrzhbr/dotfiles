return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter").install({
        "bash",
        "css",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "rust",
        "swift",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }):wait(300000)
    end,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lumen_treesitter", { clear = true }),
        pattern = {
          "bash",
          "css",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "python",
          "rust",
          "swift",
          "typescript",
          "typescriptreact",
          "vim",
          "yaml",
        },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", gs.next_hunk, "Next git hunk")
        map("n", "[c", gs.prev_hunk, "Previous git hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
      end,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lumen_lsp_attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code action")
          map("<leader>lf", function()
            vim.lsp.buf.format({ async = true })
          end, "Format buffer")
        end,
      })

      -- Use Neovim's native 0.11+ LSP configuration API. nvim-lspconfig
      -- supplies the defaults; enabling a server activates it for its filetypes.
      local servers = {
        "clangd",        -- C and C++
        "ts_ls",         -- TypeScript and JavaScript
        "pyright",       -- Python
        "jdtls",         -- Java
        "gopls",         -- Go
        "rust_analyzer", -- Rust
      }

      -- Prefer each project's TypeScript version, with the pinned global
      -- installation as a fallback for standalone files and small projects.
      vim.lsp.config("ts_ls", {
        init_options = {
          tsserver = {
            fallbackPath = vim.fn.expand(
              "~/.local/lib/node_modules/typescript/lib/tsserver.js"
            ),
          },
        },
      })

      -- Reuse the Java language server bundled with the installed VS Code Java
      -- extension. It requires Java 21+, while the system Java is currently 17.
      local jdtls_cmd = vim.fn.exepath("jdtls")
      if jdtls_cmd == "" then
        local matches = vim.fn.glob(
          vim.fn.expand("~/.vscode/extensions/redhat.java-*/server/bin/jdtls"),
          false,
          true
        )
        table.sort(matches)
        jdtls_cmd = matches[#matches] or "jdtls"
      end

      vim.lsp.config("jdtls", {
        cmd = {
          jdtls_cmd,
          "--java-executable",
          "/opt/homebrew/opt/openjdk/bin/java",
        },
      })

      vim.lsp.enable(servers)
    end,
  },
}
