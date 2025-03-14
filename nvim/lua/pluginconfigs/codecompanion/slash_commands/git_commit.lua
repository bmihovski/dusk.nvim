local fmt = string.format

local SlashCommand = {}

-- SlashCommand.new
function SlashCommand.new(args)
  local self = setmetatable({
    Chat = args.Chat,
    config = args.config,
    context = args.context,
  }, { __index = SlashCommand })
  return self
end

-- slash command
function SlashCommand:execute(SlashCommands)
  local message = self:generate_commit_message()
  -- commit message
  self.Chat:add_buf_message({
    role = "user",
    content = message,
  })
end

function SlashCommand:generate_commit_message()
  local git_diff = vim.fn.system("git diff --no-ext-diff --staged")

  return fmt(
    [[
@cmd_runner

MISSION:
- Write commit message for the change with **commitizen convention**
- After generating commit message, commit it with `git commit -m "<message>"`

Make sure:
- the title has maximum 50 characters
- the message is wrapped at 72 characters.

Attention:
- Wrap the whole message in code block with language gitcommit.
- ALL content below this line is DIFF


```diff
%s
```

]],
    git_diff
  )
end

return SlashCommand
