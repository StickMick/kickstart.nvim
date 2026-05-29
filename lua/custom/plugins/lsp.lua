---@module 'lazy'
---@type LazySpec
return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim',
        ---@module 'mason.settings'
        ---@type MasonSettings
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      {
        'seblyng/roslyn.nvim',
        ft = 'cs',
        opts = {},
        config = function(_, opts)
          require('roslyn').setup(opts)
        end,
      },
    },
    config = function()
      -- LspAttach keymaps and autocmds
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map(
              '<leader>th',
              function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
              end,
              '[T]oggle Inlay [H]ints'
            )
          end
        end,
      })

      -- Mason setup
      require('mason').setup()
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'ts_ls', 'angularls' },
      })
      require('mason-tool-installer').setup({
        ensure_installed = { 'stylua' },
      })

      -- Lua Language Server
      vim.lsp.config('lua_ls', {
        on_init = function(client)
          client.server_capabilities.documentFormattingProvider = false

          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
              path ~= vim.fn.stdpath('config')
              and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              version = 'LuaJIT',
              path = { 'lua/?.lua', 'lua/?/init.lua' },
            },
            workspace = {
              checkThirdParty = false,
              library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                '${3rd}/luv/library',
                '${3rd}/busted/library',
              }),
            },
          })
        end,
        settings = {
          Lua = {
            format = { enable = false },
          },
        },
      })

      -- TypeScript Language Server
      vim.lsp.config('ts_ls', {
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
      })

      -- Angular Language Server - requires manual setup due to dynamic cmd
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'typescript', 'html', 'typescriptreact' },
        callback = function(args)
          local root_dir = vim.fs.root(args.buf, { 'angular.json', 'project.json' })
          if not root_dir then return end

          vim.lsp.start({
            name = 'angularls',
            cmd = {
              'ngserver',
              '--stdio',
              '--tsProbeLocations', root_dir .. '/node_modules',
              '--ngProbeLocations', root_dir .. '/node_modules',
            },
            root_dir = root_dir,
            filetypes = { 'typescript', 'html', 'typescriptreact', 'typescript.tsx' },
          })
        end,
      })

      -- Enable LSP servers
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('ts_ls')
    end,
  },
}
