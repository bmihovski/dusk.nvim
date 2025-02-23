local slash_commands_prefix = vim.fn.stdpath("config") .. "/pluginconfigs/codecompanion/slash_commands/"

local just_do_it = require("pluginconfigs.codecompanion.variables.just_do_it")

-- local adapter = "copilot"
-- local adapter = "deepseek"
local adapter = "gemini"

return {
	"olimorris/codecompanion.nvim",
	cmd = {
		"CodeCompanionChat",
		"CodeCompanion",
		"CodeCompanionCmd",
		"CodeCompanionActions",
	},
	event = {
		"BufReadPost",
		"BufNewFile",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"Davidyz/VectorCode",
	},
	config = function()
		require("codecompanion").setup({
			adapters = {
				deepseek = function()
					return require("codecompanion.adapters").extend("deepseek", {
						env = {
							api_key = os.getenv("DEEPSEEK_CHAT_API_KEY"),
						},
						schema = {
							model = {
								default = "deepseek-chat",
								-- default = "deepseek-reasoner",
							},
							temperature = {
								default = 0.5,
							},
						},
					})
				end,
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							temperature = {
								default = 0.5,
							},
							model = {
								default = "claude-3.5-sonnet",
							},
						},
					})
				end,
				gemini = function()
					return require("codecompanion.adapters").extend("gemini", {
						schema = {
							temperature = {
								default = 0.5,
							},
							model = {
								default = "gemini-2.0-flash",
							},
						},
					})
				end,
			},
			strategies = {
				chat = {
					adapter = adapter,
					slash_commands = {
						codebase = require("vectorcode.integrations").codecompanion.chat.make_slash_command(),
						["git_commit"] = {
							description = "Generate git commit message and commit it",
							callback = slash_commands_prefix .. "git_commit.lua",
							opts = {
								contains_code = true,
							},
						},
					},
					variables = {
						["just_do_it"] = {
							callback = just_do_it,
							description = "Automated",
							opts = {
								contains_code = false,
							},
						},
					},
					agents = {
						tools = {
							vectorcode = {
								description = "Run VectorCode to retrieve the project context.",
								-- callback = "vectorcode",
								callback = require("vectorcode.integrations").codecompanion.chat.make_tool({
									default_num = 15,
								}),
							},
						},
					},
				},
				inline = { adapter = adapter },
				agent = { adapter = adapter },
			},
			display = {
				chat = {
					window = {
						position = "right",
					},
				},
			},
		})
	end,
}
