return {
	-- Autosave feature
	{
		"okuuva/auto-save.nvim",
		-- cmd = "ASToggle", -- Use this cmd if you want to enable or Space + t + s
		event = { "InsertLeave", "TextChanged" },
		opts = {
			execution_message = {
				enabled = false,
			},
			debounce_delay = 5000,
		},
	},

	-- Lsp server status updates
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	-- Electric indentation
	{
		"nmac427/guess-indent.nvim",
		lazy = true,
		event = { "BufReadPost", "BufAdd", "BufNewFile" },
		opts = {},
	},

	-- Highlight word under cursor
	{
		"RRethy/vim-illuminate",
		event = "VeryLazy",
		config = function()
			local illuminate = require("illuminate")
			vim.g.Illuminate_ftblacklist = { "NvimTree" }

			illuminate.configure({
				providers = {
					"lsp",
					"treesitter",
					"regex",
				},
				delay = 200,
				filetypes_denylist = {
					"dirvish",
					"fugitive",
					"alpha",
					"NvimTree",
					"packer",
					"neogitstatus",
					"Trouble",
					"lir",
					"Outline",
					"spectre_panel",
					"toggleterm",
					"DressingSelect",
					"TelescopePrompt",
					"sagafinder",
					"sagacallhierarchy",
					"sagaincomingcalls",
					"sagapeekdefinition",
				},
				filetypes_allowlist = {},
				modes_denylist = {},
				modes_allowlist = {},
				providers_regex_syntax_denylist = {},
				providers_regex_syntax_allowlist = {},
				under_cursor = true,
			})
		end,
	},

	-- Delete whitespaces automatically on save
	{
		"saccarosium/nvim-whitespaces",
		event = "BufWritePre",
		opts = {
			handlers = {},
		},
	},

	{
		"NStefan002/visual-surround.nvim",
		event = "VeryLazy",
		config = function()
			require("visual-surround").setup({
				-- your config
			})
		end,
	},

	-- Session management
	-- auto save and restore the last session
	{
		"folke/persistence.nvim",
		event = "BufReadPre", -- this will only start session saving when an actual file was opened
		opts = {
			-- add any custom options here
		},
	},
	{
		"tpope/vim-obsession",
		lazy = true,
	},

	{
		"https://gitlab.com/yorickpeterse/nvim-pqf.git",
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
		config = function()
			require("pqf").setup()
		end,
	},
	{
		"shortcuts/no-neck-pain.nvim",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},

	{
		"tris203/precognition.nvim",
		event = "VeryLazy",
		config = function()
			require("precognition").setup({
				startVisible = true,
				showBlankVirtLine = false,
				-- highlightColor = { link = "Comment"),
				-- hints = {
				--      Caret = { text = "^", prio = 2 },
				--      Dollar = { text = "$", prio = 1 },
				--      MatchingPair = { text = "%", prio = 5 },
				--      Zero = { text = "0", prio = 1 },
				--      w = { text = "w", prio = 10 },
				--      b = { text = "b", prio = 9 },
				--      e = { text = "e", prio = 8 },
				--      W = { text = "W", prio = 7 },
				--      B = { text = "B", prio = 6 },
				--      E = { text = "E", prio = 5 },
				-- },
				-- gutterHints = {
				--     -- prio is not currently used for gutter hints
				--     G = { text = "G", prio = 1 },
				--     gg = { text = "gg", prio = 1 },
				--     PrevParagraph = { text = "{", prio = 1 },
				--     NextParagraph = { text = "}", prio = 1 },
				-- },
			})
		end,
	},

	{
		"pteroctopus/faster.nvim",
		cmd = { "FasterDisableAllFeatures", "FasterEnableSonarlint", "FasterDisableSonarlint" },
		opts = {
			behaviours = {
				bigfile = {
					on = true,
					features_disabled = {
						"sonarlint",
						"matchparen",
						"lsp",
						"treesitter",
						"syntax",
						"filetype",
					},
					filesize = 5,
					pattern = "*",
					extra_patterns = {
						{ filesize = 0.5, pattern = "*.json" },
					},
				},
				fastmacro = {
					on = true,
					features_disabled = { "lualine" },
				},
			},
			-- Feature table contains configuration for features faster.nvim will disable
			-- and enable according to rules defined in behaviours.
			-- Defined feature will be used by faster.nvim only if it is on (`on=true`).
			-- Defer will be used if some features need to be disabled after others.
			-- defer=false features will be disabled first and defer=true features last.
      -- stylua: ignore
			features = {
				filetype = { on = true, defer = true },
				illuminate = { on = true, defer = false },
				indent_blankline = { on = true, defer = false },
				lsp = { on = true, defer = false },
				lualine = { on = true, defer = false },
				matchparen = { on = true, defer = false },
				syntax = { on = true, defer = true },
				treesitter = { on = true, defer = false },
				vimopts = { on = true, defer = false },
			},
		},
	},

	-- Tmux Integration
	{
		"alexghergh/nvim-tmux-navigation",
		lazy = false,
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true, -- defaults to false
			})
		end,
	},

	-- GitHub copilot

	{
		"AndreM222/copilot-lualine",
		event = "VeryLazy",
	},

	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
			{ "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = function()
			local user = vim.env.USER or "User"
			user = user:sub(1, 1):upper() .. user:sub(2)

			-- Base commit prompt template
			local commit_prompt =
				"Take a deep breath and analyze the changes made in the git diff. Then, write a commit message for the %s with commitizen convention, only use lower-case letters. Output the full multi-line command starting with `git commit -m` ready to be pasted into the terminal. If there are references to filenames or the backtics in the commit message, escape them with backslashes. i.e. \\` text with backticks \\`"

			return {
				separator = "---",
				debug = false, -- Enable debugging
				model = "gemini-2.0-flash-001",
				mappings = {
					reset = {
						normal = "<C-r>",
						insert = "<C-r>",
					},
				},
				history_path = vim.fn.stdpath("data") .. "/copilotchat_history",
				auto_follow_cursor = false,

				auto_insert_mode = false,
				question_header = "  " .. user .. " ",
				answer_header = "  Copilot ",
				error_header = "## Error ",
				window = {
					width = 0.4,
				},
				-- Register custom contexts
				contexts = {
					pr_diff = {
						description = "Get the diff between the current branch and target branch",
						resolve = function()
							-- Check if we're in a git repository
							local is_git = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
							if vim.v.shell_error ~= 0 then
								return { { content = "Not in a git repository", filename = "error", filetype = "text" } }
							end

							-- Get target branch (main/master/develop)
							local target_branch = vim.fn
								.system(
									"git for-each-ref --format='%(refname:short)' refs/heads/ | grep -E '^(main|master|develop)' | head -n 1"
								)
								:gsub("\n", "")
							if vim.v.shell_error ~= 0 or target_branch == "" then
								return {
									{
										content = "Failed to determine target branch",
										filename = "error",
										filetype = "text",
									},
								}
							end

							-- Fetch the latest changes from the remote repository
							local fetch_result = vim.fn.system("git fetch origin " .. target_branch .. " 2>&1")
							if vim.v.shell_error ~= 0 then
								return {
									{
										content = "Failed to fetch from remote: " .. fetch_result,
										filename = "error",
										filetype = "text",
									},
								}
							end

							-- Get current branch
							local current_branch =
								vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
							if vim.v.shell_error ~= 0 or current_branch == "" then
								return {
									{ content = "Failed to get current branch", filename = "error", filetype = "text" },
								}
							end

							-- Get the diff
							local cmd = string.format(
								"git diff --no-color --no-ext-diff origin/%s...%s 2>&1",
								target_branch,
								current_branch
							)
							local handle = io.popen(cmd)
							if not handle then
								return {
									{ content = "Failed to execute git diff", filename = "error", filetype = "text" },
								}
							end

							local result = handle:read("*a")
							handle:close()

							-- If there's no diff, return a meaningful message
							if not result or result == "" then
								return {
									{
										content = "No changes found between current branch and " .. target_branch,
										filename = "info",
										filetype = "text",
									},
								}
							end

							return {
								{
									content = result,
									filename = "pr_diff",
									filetype = "diff",
								},
							}
						end,
					},
				},
				-- Custom prompts incorporating git staged/unstaged functionality
				prompts = {
					-- Code related prompts
					Explain = {
						prompt = "Please explain how the following code works.",
						system_prompt = "You are an expert software developer and teacher. Explain the code in a clear, concise way.",
					},
					Review = {
						prompt = "Please review the following code and provide suggestions for improvement.",
						system_prompt = "You are an expert code reviewer. Focus on best practices, performance, and potential issues.",
					},
					GitHubReview = {
						prompt = "> #pr_diff\n\nPerform a comprehensive code review of the following git diff. Provide specific, actionable feedback in the form of individual comments targeted at specific lines and files. This review should cover code in Java (with a strong focus on Spring Boot), C++, Python, build systems (with a strong focus on Bazel), and infrastructure-as-code (IaC) configurations (e.g., GitHub Actions, YAML, JSON, Terraform, CloudFormation, Dockerfiles, Kubernetes manifests). Do NOT provide a general summary; focus on line-by-line analysis.",
						system_prompt = [[You are a senior software engineer/DevOps engineer performing a thorough code and infrastructure review. Your goal is to provide actionable feedback that improves quality, maintainability, performance, security, and reliability. You are reviewing changes for a colleague, so maintain a constructive and professional tone. You are an expert in a wide range of programming languages, scripting languages, build systems, and infrastructure-as-code technologies, with *deep expertise* in Java/Spring Boot, C++, Python, and Bazel.

    Input: You will receive a git diff representing changes in a pull request. The changes may include:

    *   Code in Java (especially Spring Boot), C++, Python, and other languages.
    *   Build system configurations (especially Bazel BUILD files).
    *   Infrastructure-as-Code configurations (e.g., GitHub Actions, YAML, JSON, Terraform, CloudFormation, Dockerfiles, Kubernetes manifests).
    *   Configuration files.
    *   Documentation.

    Output: Your output MUST be a series of individual comments, each formatted as follows:

    ```
    File: [File Path and Name]
    Line: [Line Number]
    Comment: [Your detailed review comment. Be specific and explain the reasoning behind your suggestion. Consider not only syntax and best practices, but also potential functional bugs, architectural improvements, maintainability, security, and operational concerns.]
    ```

    Examples (Illustrative - Adapt to the specific diff and technology):

    **Java (Spring Boot) - Dependency Injection:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 25
    Comment: Instead of directly instantiating `MyDependency`, use constructor injection with `@Autowired` (or better, use constructor injection without `@Autowired` in modern Spring Boot). This improves testability and follows dependency injection best practices.
    ```

    **Java (Spring Boot) - REST Controller:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyController.java
    Line: 42
    Comment: Consider using `@Validated` on the request body and adding validation annotations (e.g., `@NotBlank`, `@Size`, `@Email`) to the `User` class (or a dedicated DTO) to ensure input is valid.  Add a `@RestControllerAdvice` to handle `MethodArgumentNotValidException` globally for consistent error responses.
    ```

    **Java (Spring Boot) - Exception Handling:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 68
    Comment:  Catching `Exception` is generally too broad.  Catch more specific exceptions (e.g., `IOException`, `SQLException`) or create custom exceptions to handle different error scenarios appropriately.  Consider whether this method should throw a checked exception or wrap it in an unchecked exception (like `RuntimeException`).
    ```

    **Java - Variable Naming:**
]]
							.. "    ```\n"
							.. [[    File: src/main/java/com/example/MyService.java
    Line: 45
    Comment: The variable name `temp` could be more descriptive. Consider renaming it to something like `processedData` to improve readability.
    ```

    **Java - Missing Assertion:**
]]
							.. "    ```\n"
							.. [[    File: src/test/java/com/example/MyServiceTest.java
    Line: 120
    Comment: This test seems to be missing an assertion. Make sure to verify the expected outcome of the `processData` method. Consider adding an `assertEquals` or similar assertion.
    ```

   **Java/YAML - Hardcoded Secrets**
]]
							.. "    ```\n"
							.. [[    File: config/application.yml
    Line: 12
    Comment: The database password is hardcoded here. It is recomended to store secrets safely, consider using a secrets manager or environment variables.
    ```

    **C++ - Smart Pointers:**
]]
							.. "    ```\n"
							.. [[    File: src/engine/Renderer.cpp
    Line: 125
    Comment: Raw pointers are used here without explicit ownership semantics.  Use `std::unique_ptr` if ownership is exclusive, `std::shared_ptr` if ownership is shared, or `std::weak_ptr` to observe without owning. This prevents memory leaks and dangling pointers.
    ```

     **C++ - const correctness:**
]]
							.. "    ```\n"
							.. [[    File: include/utils/Math.h
    Line: 30
    Comment: The `calculateDistance` function does not modify the input vectors. Mark the parameters as `const` references (`const std::vector<double>&`) to improve code clarity and allow the function to accept `const` vectors.
    ```

    **C++ - Rule of Five/Zero:**
]]
							.. "    ```\n"
							.. [[    File: src/data/MyResource.cpp
    Line: 15
    Comment:  This class manages a resource (e.g., a dynamically allocated array).  You should implement the Rule of Five (or Rule of Zero if possible by using smart pointers).  Define (or delete) the copy constructor, copy assignment operator, move constructor, move assignment operator, and destructor to ensure proper resource management.
    ```

    **Python - List Comprehension:**
]]
							.. "     ```\n"
							.. [[    File: src/app.py
    Line: 22
    Comment:  Use a list comprehension for conciseness and often better performance: `squares = [x**2 for x in numbers if x > 0]`.
    ```

    **Python - Type Hints:**
]]
							.. "    ```\n"
							.. [[    File: src/utils/helper.py
    Line: 10
    Comment: Add type hints to the function signature to improve code readability and allow for static analysis: `def process_data(data: List[int], threshold: float) -> List[float]:`
    ```

    **Bazel - Dependency Management:**
]]
							.. "    ```\n"
							.. [[    File: BUILD
    Line: 20
    Comment: The `java_library` rule doesn't explicitly declare all its dependencies in the `deps` attribute.  List *all* direct dependencies (e.g., `@maven//:com_google_guava_guava`, `//src/main/java/com/example/lib:my_lib`).  Avoid relying on transitive dependencies for better build reproducibility and to prevent unexpected breakages.
    ```

     **Bazel - Visibility:**
]]
							.. "    ```\n"
							.. [[    File: BUILD
    Line: 35
    Comment: Consider making this target more restrictive. If it's only used within this package, use `visibility = ["//visibility:private"]`. If it's used by other packages within your project, use `visibility = ["//my_project/..."]`.  Avoid `//visibility:public` unless absolutely necessary.
    ```

    **Bazel - glob:**
]]
							.. "     ```\n"
							.. [[    File: BUILD
    Line: 12
    Comment: Using `glob` can lead to unexpected behavior if files are added or removed.  Consider explicitly listing source files or using `filegroup` for better control over the build graph. If you must use `glob`, be very specific with the patterns used.
    ```

    **GitHub Actions Example:**
]]
							.. "    ```\n"
							.. [[    File: .github/workflows/ci.yml
    Line: 35
    Comment: The `checkout` action uses the default depth. Consider using `fetch-depth: 0` to fetch the entire history, which may be necessary for some tools (e.g., linters that analyze commit history) or for accurate versioning (e.g., if you're using Git tags for releases).
    ```

    **Terraform Example:**
]]
							.. "    ```\n"
							.. [[    File: main.tf
    Line: 15
    Comment: The `aws_instance` resource does not have termination protection enabled. Consider setting `disable_api_termination = true` to prevent accidental deletion. Also, consider adding tags for better resource management and cost tracking.
    ```
     **JavaScript Example:**
]]
							.. "     ```\n"
							.. [[    File: src/components/MyComponent.jsx
    Line: 52
    Comment:  The state update here (`setCount(count + 1)`) might lead to unexpected behavior if multiple updates happen in quick succession.  Consider using the functional form of `setState`: `setCount(prevCount => prevCount + 1)` to ensure you're always working with the latest state.
    ```

    **Dockerfile Example:**
]]
							.. "     ```\n"
							.. [[    File: Dockerfile
    Line: 12
    Comment: Consider using a multi-stage build to reduce the final image size. A separate build stage can be used for compilation, and then only the necessary artifacts copied to the final runtime image.
    ```
 **Spring Boot Test Example:**
]]
							.. "     ```\n"
							.. [[    File: src/test/java/com/example/MyServiceTest.java
    Line: 30
    Comment:  `@SpringBootTest` loads the entire application context, which can make tests slow and introduce dependencies between tests.  Consider using more focused testing annotations like `@DataJpaTest` (for testing JPA repositories), `@WebMvcTest` (for testing Spring MVC controllers), or `@MockBean` to mock specific dependencies.  Only use `@SpringBootTest` when absolutely necessary for integration testing.
    ```
 **Spring Boot Test Example:**
]]
							.. "     ```\n"
							.. [[    File: src/test/java/com/example/RepositoryTest.java
    Line: 18
    Comment: Using TestBase Classes is not recomended, consider creating individual test classes to keep tests isolated.
    ```

    Key Considerations:

    *   Line-Specific Feedback: Each comment *must* be associated with a specific file and line number.
    *   Actionable Suggestions: Don't just point out problems; suggest concrete solutions.
    *   Beyond Syntax: Go beyond basic syntax checks. Consider:
        *   Functional Bugs: Look for logic errors, edge cases, and potential unexpected behavior.
        *   Architectural Improvements: Suggest better design patterns, improved modularity.
        *   Performance: Identify potential bottlenecks, inefficient algorithms or data structures.
        *   Maintainability: Assess code clarity, readability, documentation, and adherence to coding conventions.
        *   Security: Look for vulnerabilities (e.g., injection, cross-site scripting, insecure configurations, dependency vulnerabilities).
        *   Testing:  **Strong emphasis on test quality:**
            *   Check for adequate test coverage, missing test cases, well-written assertions, and appropriate mocking/stubbing.
            *   **Avoid `@SpringBootTest` overuse:**  Warn against using `@SpringBootTest` unless strictly necessary for integration testing.  Promote the use of more focused testing annotations like `@DataJpaTest`, `@WebMvcTest`, etc.
            *  **Discourage TestBaseclasses**: Warn about using TestBase classes.
            *   **Promote Mocking:** Encourage the use of mocking frameworks (like Mockito) to isolate units under test.
            *   **Verify Test Isolation:** Ensure that tests are truly isolated and do not depend on shared state or external resources.
        *   Operational Concerns (for IaC): Consider reliability, scalability, cost, and deployment/management.
        *   Build System Best Practices (especially Bazel):  Focus on dependency management (explicit `deps`), visibility control, efficient build rules, avoiding `glob` overuse, and hermeticity.
        *   Language-Specific Best Practices:
            *   **Java/Spring Boot:** Dependency injection, proper exception handling, validation, REST API best practices, use of Spring Boot features (e.g., `@ConfigurationProperties`, `@Enable*` annotations), efficient data access (e.g., using Spring Data JPA), security best practices (e.g., Spring Security).  **Emphasize appropriate use of Spring testing annotations.**
            *   **C++:**  Memory management (smart pointers), const correctness, Rule of Five/Zero, modern C++ features (C++11/14/17/20/23), avoiding undefined behavior, exception safety.
            *  **Python**: List comprehension, type hints.
        *   Professional Tone: Be constructive and respectful.
        *   Context Awareness: Understand the overall purpose of the changes.
       * **Microservices Considerations**: If you detect inter-service communication (like gRPC calls), make sure to check the contract.
       * **Gradle Build**: When adding dependecies, remind to use version catalog.
       * **Synchronous Remote Calls**: When detecting synchronous remote calls (e.g., gRPC), remind the developer about the implications and to be mindful of the performance and potential for cascading failures.

    Optimization for Gemini 2.0 Flash:

    *   Clear, Concise Instructions: The prompt is structured clearly.
    *   Specific Output Format: The required format is explicitly defined.
    *   Emphasis on Actionable Feedback: Stress the need for concrete suggestions.
    * Avoid Summaries: Explicitly avoid providing general summaries.
    * Multiple, Detailed Examples: Provide numerous examples for each key area, showing the desired level of detail and specificity.
    ]],
					},
					Tests = {
						prompt = "Please explain how the selected code works, then generate unit tests for it.",
						system_prompt = "You are an expert in software testing. Generate thorough test cases covering edge cases.",
					},
					Refactor = {
						prompt = "Please refactor the following code to improve its clarity and readability.",
						system_prompt = "You are an expert in code refactoring. Focus on making the code more maintainable and easier to understand.",
					},
					FixCode = {
						prompt = "Please fix the following code to make it work as intended.",
						system_prompt = "You are an expert programmer. Help fix code issues while maintaining code style and best practices.",
					},
					FixError = {
						prompt = "Please explain the error in the following text and provide a solution.",
						system_prompt = "You are an expert in debugging. Help identify and fix the error while explaining the solution.",
					},
					BetterNamings = {
						prompt = "Please provide better names for the following variables and functions.",
						system_prompt = "You are an expert in code readability. Suggest clear, descriptive names following naming conventions.",
					},
					Documentation = {
						prompt = "Please provide documentation for the following code.",
						system_prompt = "You are an expert technical writer. Create clear, comprehensive documentation.",
					},
					SwaggerApiDocs = {
						prompt = "Please provide documentation for the following API using Swagger.",
						system_prompt = "You are an expert in API documentation. Create comprehensive Swagger/OpenAPI documentation.",
					},
					SwaggerJsDocs = {
						prompt = "Please write JSDoc for the following API using Swagger.",
						system_prompt = "You are an expert in JavaScript documentation. Create comprehensive JSDoc with Swagger annotations.",
					},
					SwaggerApiSpringDocs = {
						prompt = "Please generate Spring Boot REST controller method annotations (for OpenAPI 3 specification) for the following Java method. Include annotations for request parameters, response types, and descriptions. Consider the method's purpose and parameters to create appropriate annotations.",
						system_prompt = [[You are an expert in Java and Spring Boot REST API documentation using OpenAPI 3.  You will be provided with a Java method signature and potentially some surrounding context. Your task is to generate the appropriate Spring Boot annotations to fully document that method for OpenAPI generation using a library like springdoc-openapi-ui.

                        Focus on these key annotations:

                        *   `@Operation`:  Provide a `summary` (short description) and a more detailed `description`.
                        *   `@Parameter`: For each method parameter, use `@Parameter` to describe it.  Include `description`, `required` (if applicable), and `in` (e.g., `ParameterIn.PATH`, `ParameterIn.QUERY`, `ParameterIn.HEADER`, `ParameterIn.COOKIE`).
                        *   `@ApiResponses`: Define possible API responses. Use `@ApiResponse` for each status code (e.g., 200, 400, 404, 500). Include a `description` and, importantly, a `content` attribute specifying the `@Content` (media type and schema).
                        *   `@RequestBody`: If the method accepts a request body, use `@RequestBody` to describe it.  Include a `description` and `content` (with media type and schema).
                        * `@Schema`: Use to fully define return types.
                        *   `@PathVariable`: Use as needed with `@Parameter` for path variables.
                        *   `@RequestParam`: Use as needed with `@Parameter` for query parameters.
                        *   `@RequestHeader`:  Use as needed with `@Parameter` for header parameters.
                        *  Consider adding the annotation @Tag to improve documentation.

                        Example:

                        Input Java Method:
                        ```java
                        public ResponseEntity<User> getUserById(long id) {
                            // ... implementation ...
                        }
                        ```

                        Desired Output Annotations:
                        ```java
                        @Operation(summary = "Get a user by ID", description = "Retrieves a user based on their unique identifier.")
                        @ApiResponses(value = {
                            @ApiResponse(responseCode = "200", description = "Successful operation",
                                    content = @Content(mediaType = "application/json",
                                            schema = @Schema(implementation = User.class))),
                            @ApiResponse(responseCode = "404", description = "User not found",
                                    content = @Content)
                        })
                        public ResponseEntity<User> getUserById(
                            @Parameter(description = "The ID of the user to retrieve.", required = true, in = ParameterIn.PATH)
                            @PathVariable long id
                        ) {
                            // ... implementation ...
                        }
                        ```
                    ]],
					},
					-- Git related prompts
					Commit = {
						prompt = "> #git:staged\n\n" .. string.format(commit_prompt, "change"),
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					CommitStaged = {
						prompt = "> #git:staged\n\n" .. string.format(commit_prompt, "staged changes"),
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					CommitUnstaged = {
						prompt = "> #git:unstaged\n\n" .. string.format(commit_prompt, "unstaged changes"),
						system_prompt = "You are an expert in writing clear, concise git commit messages following best practices.",
					},
					PullRequest = {
						prompt = "> #pr_diff\n\nWrite a pull request description for these changes. Include a clear title, summary of changes, and any important notes.",
						system_prompt = [[You are an experienced software engineer about to open a PR. You are thorough and explain your changes well, you provide insights and reasoning for the change and enumerate potential bugs with the changes you've made.

          Your task is to create a pull request for the given code changes. Follow these steps:

          1. Analyze the git diff changes provided.
          2. Draft a comprehensive description of the pull request based on the input.
          3. Create the gh CLI command to create a GitHub pull request.

          Output Instructions:
          - The command should start with `gh pr create`.
          - Do not use the new line character in the command since it does not work
          - Output needs to be a multi-line command
          - Include the `--base $(git parent)` flag
          - Use the `--title` flag with a concise, descriptive title matching the commitzen convention.
          - Use the `--body` flag for the PR description.
          - Include the following sections in the body:
            - '## Summary' with a brief overview of changes
            - '## Changes' listing specific modifications
            - '## Additional Notes' for any extra information
          - Escape any backticks in the message body to avoid shell interpretation issues
          - Wrap the entire command in a code block for easy copy-pasting.

          Desired Output:
          ```sh
          gh pr create \
            --base $(git parent) \
            --title "feat: your title here" \
            --body "## Summary
          Your summary here

          ## Changes
          - Change 1
          - Change 2
          - Change 3 \`with backticks\`

          ## Additional Notes
          Your notes here"
          ```]],
					},
					CustomPullRequest = {
						prompt = "> #pr_diff\n\nWrite a pull request description for these changes. Include a clear title, summary of changes, and any important notes.",
						system_prompt = [[You are an experienced software engineer about to open a PR. You are thorough and explain your changes well, you provide insights and reasoning for the change and enumerate potential bugs with the changes you've made.

    Your task is to create a pull request for the given code changes. Follow these steps:

    1. Analyze the git diff changes provided.
    2. Draft a comprehensive description of the pull request based on the input.  **Crucially, structure the description according to the template below.**
    3. Create the gh CLI command to create a GitHub pull request.

    Output Instructions:
    - The command should start with `gh pr create`.
    - Do not use the new line character in the command since it does not work
    - Output needs to be a multi-line command
    - Include the `--base $(git parent)` flag
    - Use the `--title` flag with a concise, descriptive title matching the commitzen convention.
    - Use the `--body` flag for the PR description.
    - Include the following sections in the body:
      - '#### Why?' explaining the *reason* for the proposed change.  Why is this change necessary or beneficial?
      - '#### What?' providing a *high-level overview* of what the PR changes.  Don't just repeat the diff, but describe the changes conceptually.
    - Escape any backticks in the message body to avoid shell interpretation issues
    - Wrap the entire command in a code block for easy copy-pasting.

    Desired Output:
    ```sh
    gh pr create \
      --base $(git parent) \
      --title "feat: your title here" \
      --body "#### Why?

    _Your reasoning for the changes goes here._

    #### What?

    _A high-level description of the changes goes here.  Example:  This PR refactors the user authentication module to improve security and maintainability. It replaces the old hashing algorithm with a more robust one and adds input validation to prevent common injection attacks._
    "
    ```]],
					},
					-- Text related prompts
					Summarize = {
						prompt = "Please summarize the following text.",
						system_prompt = "You are an expert in technical writing. Create clear, concise summaries.",
					},
					Spelling = {
						prompt = "Please correct any grammar and spelling errors in the following text.",
						system_prompt = "You are an expert editor. Fix grammar and spelling while maintaining the original meaning.",
					},
					Wording = {
						prompt = "Please improve the grammar and wording of the following text.",
						system_prompt = "You are an expert writer. Improve clarity and readability while maintaining the original meaning.",
					},
					Concise = {
						prompt = "Please rewrite the following text to make it more concise.",
						system_prompt = "You are an expert in technical writing. Make the text more concise while preserving key information.",
					},
				},
			}
		end,
		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")

			-- Disable line numbers in chat window
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "copilot-chat",
				callback = function()
					vim.opt_local.relativenumber = false
					vim.opt_local.number = false
				end,
			})

			-- Setup CMP integration
			chat_autocomplete = true

			-- Create commands for visual mode
			vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
				chat.ask(args.args, { selection = select.visual })
			end, { nargs = "*", range = true })

			-- Inline chat with Copilot
			vim.api.nvim_create_user_command("CopilotChatInline", function(args)
				chat.ask(args.args, {
					selection = select.visual,
					window = {
						layout = "float",
						relative = "cursor",
						width = 1,
						height = 0.4,
						row = 1,
					},
				})
			end, { nargs = "*", range = true })

			chat.setup(opts)
		end,
	},

	-- codecompanion
	{ import = "pluginconfigs.codecompanion.init" },

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false, auto_trigger = false, debounce = 75 },
				panel = {
					enabled = false,

					layout = {
						position = "bottom", -- | top | left | right
						ratio = 0.4,
						event = { "BufEnter" },
					},
				},
				copilot_node_command = "node",
				server_opts_overrides = {},
			})
		end,
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = true,
		-- dev = true,
		version = false,
		build = "make",
		opts = {
			provider = "copilot",
			auto_suggestions_provider = "openai",
			openai = {
				endpoint = "https://api.deepseek.com/v1",
				model = "deepseek-chat",
				timeout = 30000,
				temperature = 0,
				max_tokens = 4096,
			},
			copilot = {
				model = "claude-3.5-sonnet",
				temperature = 0.5,
				timeout = 30000, -- Timeout in milliseconds
				max_tokens = 8192,
			},
			gemini = {
				model = "gemini-2.0-flash",
				temperature = 0.2,
				max_tokens = 16384,
			},
			web_search_engine = {
				provider = "google",
			},
			dual_boost = {
				enabled = true,
				first_provider = "copilot",
				second_provider = "gemini",
				prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Provide brief explanation with highlighting the important points. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
				timeout = 60000, -- Timeout in milliseconds
			},
			windows = {
				sidebar_header = {
					enabled = false,
				},
			},
			behaviour = {
				auto_suggestions = false, -- Experimental stage
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = true,
				minimize_diff = true,
			},
			mappings = {
				sidebar = {
					switch_windows = "<C-Tab>",
					reverse_switch_windows = "<C-S-Tab>",
				},
			},
			file_selector = {
				--- @alias FileSelectorProvider "native" | "fzf" | "telescope" | string
				provider = "fzf",
				-- Options override for custom providers
				provider_opts = {},
			},
			suggestion = {
				dismiss = "<C-e>",
			},
			on_error = function(err)
				vim.notify("Avante error: " .. err, vim.log.levels.ERROR)
			end,
		},
		dependencies = {
			{ "stevearc/dressing.nvim", lazy = true },
			{ "nvim-lua/plenary.nvim", lazy = true },
			{ "MunifTanjim/nui.nvim", lazy = true },
			{ "nvim-tree/nvim-web-devicons", lazy = true },
			{ "hrsh7th/nvim-cmp", lazy = true },
			{ "zbirenbaum/copilot.lua", lazy = true },
			--- The below dependencies are optional,
			{ "echasnovski/mini.pick", lazy = true }, -- for file_selector provider mini.pick
			{ "nvim-telescope/telescope.nvim", lazy = true }, -- for file_selector provider telescope
			{ "hrsh7th/nvim-cmp", lazy = true }, -- autocompletion for avante commands and mentions
			{ "ibhagwan/fzf-lua", lazy = true }, -- for file_selector provider fzf
			{ "nvim-tree/nvim-web-devicons", lazy = true }, -- or echasnovski/mini.icons
			{ "zbirenbaum/copilot.lua", lazy = true }, -- for providers='copilot'
			{ "MeanderingProgrammer/render-markdown.nvim", lazy = true },
			{
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						use_absolute_path = true,
					},
				},
			},
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			file_types = {
				"Avante",
				"codecompanion",
				"markdown",
				"copilot-chat",
			},
		},
		ft = {
			"Avante",
			"codecompanion",
			"markdown",
			"copilot-chat",
		},
		config = function(_, opts)
			require("render-markdown").setup(opts)
		end,
	},

	-- Python helpers
	{
		"AckslD/swenv.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		lazy = false,
		config = function()
			require("swenv").setup({
				venvs_path = vim.fn.expand("~/.cache/pypoetry/virtualenvs"),
				post_set_venv = function()
					vim.cmd("LspRestart")
				end,
			})
		end,
	},

	-- C++ build
	{
		"Civitasv/cmake-tools.nvim",
		ft = { "hpp", "h", "cpp" },
		event = "VeryLazy",
		opts = {
			handlers = {},
		},
	},

	{
		"pogyomo/cppguard.nvim",
		dependencies = {
			"L3MON4D3/LuaSnip", -- If you're using luasnip.
		},
		config = function()
			local luasnip = require("luasnip")
			luasnip.add_snippets("cpp", {
				require("cppguard").snippet_luasnip("guard"),
			})
		end,
	},

	{
		"Badhi/nvim-treesitter-cpp-tools",
		ft = { "hpp", "h", "cpp" },
		event = "VeryLazy",
		dependencies = { "nvim-treesitter" },
		config = function()
			require("nt-cpp-tools").setup({
				header_extension = "h",
				source_extension = "cpp",
			})
		end,
		cmd = { "TSCppDefineClassFunc", "TSCppMakeConcreteClass", "TSCppRuleOf3", "TSCppRuleOf5" },
	},

	{
		"bfrg/vim-c-cpp-modern",
		ft = { "hpp", "h", "cpp" },
	},

	-- bazel
	{
		"mrheinen/bazelbub.nvim",
		version = "v0.2",
	},
	{ "bazelbuild/vim-bazel", dependencies = { "google/vim-maktaba" } },

	{
		"gen740/SmoothCursor.nvim",
		event = { "BufRead", "BufNewFile" },
		config = function()
			local default = {
				autostart = true,
				cursor = "", -- cursor shape (need nerd font)
				intervals = 35, -- tick interval
				linehl = nil, -- highlight sub-cursor line like 'cursorline', "CursorLine" recommended
				type = "exp", -- define cursor movement calculate function, "default" or "exp" (exponential).
				fancy = {
					enable = true, -- enable fancy mode
					head = { cursor = "▷", texthl = "SmoothCursor", linehl = nil },
					body = {
						{ cursor = "", texthl = "SmoothCursorRed" },
						{ cursor = "", texthl = "SmoothCursorOrange" },
						{ cursor = "●", texthl = "SmoothCursorYellow" },
						{ cursor = "●", texthl = "SmoothCursorGreen" },
						{ cursor = "•", texthl = "SmoothCursorAqua" },
						{ cursor = ".", texthl = "SmoothCursorBlue" },
						{ cursor = ".", texthl = "SmoothCursorPurple" },
					},
					tail = { cursor = nil, texthl = "SmoothCursor" },
				},
				priority = 10, -- set marker priority
				speed = 25, -- max is 100 to stick to your current position
				texthl = "SmoothCursor", -- highlight group, default is { bg = nil, fg = "#FFD400" }
				threshold = 3,
				timeout = 3000,
				disable_float_win = true, -- disable on float window
			}
			require("smoothcursor").setup(default)
		end,
	},

	{
		"aznhe21/actions-preview.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-telescope/telescope.nvim" },
		opts = {
			handlers = {},
		},
		config = function()
			vim.keymap.set({ "v", "n" }, "gf", require("actions-preview").code_actions)
		end,
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup({
				prompt_func_return_type = {
					java = true,
					cpp = true,
					c = true,
					h = true,
					hpp = true,
					cxx = true,
				},
				prompt_func_param_type = {
					java = true,
					cpp = true,
					c = true,
					h = true,
					hpp = true,
					cxx = true,
				},
				show_success_message = true, -- shows a message with information about the refactor on success
				-- i.e. [Refactor] Inlined 3 variable occurrences
				-- load refactoring Telescope extension
				require("telescope").load_extension("refactoring"),
			})
		end,
	},
	-- misc
	{
		"norcalli/nvim-colorizer.lua",
		config = true,
		cmd = "ColorizerToggle",
	},
	{
		"EthanJWright/vs-tasks.nvim",
		dependencies = {
			"nvim-lua/popup.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("vstask").setup({
				json_parser = require("json5").parse,
			})
		end,
	},
	{
		"Joakker/lua-json5",
		build = "./install.sh && mv lua/json5.dylib lua/json5.so",
		lazy = false,
		priority = 1000,
	},
	-- rest client
	-- {
	--   "vhyrro/luarocks.nvim",
	--   priority = 1000,
	--   config = true,
	--   opts = {
	--     rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" }
	--   }
	-- },
	-- {
	--   "rest-nvim/rest.nvim",
	--   ft = "http",
	--   dependencies = { "luarocks.nvim", "nvim-telescope/telescope.nvim" },
	--   config = function()
	--     require("rest-nvim").setup()
	--     require("telescope").load_extension("rest")
	--   end,
	-- }
}
