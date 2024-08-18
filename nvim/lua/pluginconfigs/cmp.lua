local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
local cmp_autopairs = require('nvim-autopairs.completion.cmp')

cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done()
)

-- import luasnip plugin safely
local luasnip_status, luasnip = pcall(require, "luasnip")
if not luasnip_status then
  return
end

-- load VSCode-like snippets from plugins (e.g., friendly-snippets)
require("luasnip/loaders/from_vscode").lazy_load()

cmp.setup({
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  completion = {
    completeopt = 'menu,menuone,noselect,noinsert'
  },
  sources = {
    { name = "copilot" },
    { name = "cmp-dbee" },
    { name = "nvim_lsp" },
    { name = "luasnip" },
    {
      name = "buffer-lines",
      option = { words = true, leading_whitespace = false, comments = true }
    },
    { name = "path" },
  },
  sorting = {
      comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.recently_used,
          require("clangd_extensions.cmp_scores"),
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
      },
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Enter confirms the autocompletion candidate
    ['<Tab>'] = cmp_action.luasnip_supertab({ behavior = cmp.SelectBehavior.Select }),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab({ behavior = cmp.SelectBehavior.Select }),
  }),
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
})

-- `/` cmdline setup.
cmp.setup.cmdline('/', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- `:` cmdline setup.
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    {
      name = 'cmdline',
      option = {
        ignore_cmds = { 'Man', '!' }
      }
    }
  })
})
