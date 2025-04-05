return {
	"napisani/context-nvim",
	lazy = true,
	cmd = "ContextNvim",
	config = function()
		local M = {}

		M.Generate_Code = [[
I need to implement [specific functionality] in [programming language].
Key requirements:
  1. [Requirement 1]
  2. [Requirement 2]
  3. [Requirement 3]
Please consider:
- Error handling
- Edge cases
- Performance optimization
- Best practices for [language/framework]
Please do not unnecessarily remove any comments or code.
Generate the code with clear comments explaining the logic.
]]

		M.Write_Code = [[
<role>You are a seasoned programmer.</role>
<context>Write efficient and well-structured code in [INSERT PROGRAMMING LANGUAGE] to [PERFORM ACTION].</context>
<steps> 1. Implement the necessary logic and algorithms.
2. Optimize for performance and readability.
3. Document the code for future reference and maintenance.</steps>
]]

		M.Unit_Tests = [[
Generate unit tests for the following function:
[paste function]
  Include tests for:
  1. Normal expected inputs
  2. Edge cases
  3. Invalid inputs
Use [preferred testing framework] syntax.
]]

		M.Explain = [[
Can you explain the following part of the code in detail:
[paste code section]
Specifically:
  1. What is the purpose of this section?
  2. How does it work step-by-step?
  3. Are there any potential issues or limitations with this approach?
]]

		M.Code_Review = [[
Please review the following code:
[paste your code]
Consider:
1. Code quality and adherence to best practices
2. Potential bugs or edge cases
3. Performance optimizations
4. Readability and maintainability
5. Any security concerns
Suggest improvements and explain your reasoning for each suggestion.
]]

		M.Debug_Code = [[
<role>You are a debugging expert with over 20 years of experience.</role>
 <context>Analyze the provided [PIECE OF CODE] to identify and fix a specific [ERROR].</context>
 <steps> 1. Step through the code to diagnose the issue.
 2. Propose a solution to fix the error.
 3. Suggest optimizations for performance and readability.</steps>
]]

		M.Refactor_Code = [[
<role>You are a programming expert specializing in refactoring.</role>
 <context>Refactor the given [PIECE OF CODE] to improve efficiency, readability, and maintainability without altering its functionality.</context>
 <steps> 1. Simplify complex logic.
 2. Remove redundant code.
 3. Document the refactored code for clarity.</steps>
]]

		M.Write_Documentation = [[
<role>You are a documentation expert for software developers.</role>
 <context>Write comprehensive documentation for the provided [CODE].</context>
 <steps> 1. Start with an overview of the code’s purpose.
 2. Break down the functionality of each component.
 3. Include examples and a FAQ section to assist users.</steps>
]]

		M.Write_Tests = [[
<role>You are a software testing specialist.</role>
 <context>Design and write comprehensive tests for a specific [PIECE OF CODE] using [TESTING FRAMEWORK].</context>
 <steps> 1. Outline a testing strategy covering edge cases.
 2. Implement unit, integration, and end-to-end tests as needed.
 3. Ensure all tests are thorough and efficient.</steps>
]]

		M.Architecture = [[
Take the role of Socratic Questioner and ask me about my software idea and use my answers to provide all requested detail for this 'Comprehensive Software Design and Specification Document Template for Code Generation'. If I am unsure about an answer then choose the option that would be most popular for this project. Think through this step by step and DO NOT WRITE ANY CODE UNTIL THIS DOCUMENT HAS BEEN COMPLETED AND THE COMPLETE DOCUMENT HAS BEEN APPROVED BY ME. Ask me these questions one at a time and record my answers.

Comprehensive Software Design and Specification Document Template for Code Generation
Starting Idea: [what is the high level idea for this project]
Project Overview
[Briefly describe the purpose and goals of the software project. ]

Project Goals
[Goal 1]

[Goal 2]

Target Audience
[primary users or groups]

Functional Requirements
Input Handling:

[Describe the types of input the software will accept (e.g., file paths, URLs, data formats).]

[Specify how the software will determine the input type and handle different formats.]

Data Processing:

[Detail the specific actions to be performed on the input data (e.g., extraction, transformation, analysis).]

[Describe any algorithms, libraries, or external services that will be used.]

Output Generation:

[Specify the format(s) of the output data or results.]

[Describe how the output will be presented to the user (e.g., files, displays, API responses).]

Error Handling:

[List the potential errors or exceptions that the software might encounter.]

[Explain how each error will be handled (e.g., logging, retrying, notifying the user).]

5. Additional Features (Optional):

[Describe any optional or advanced features that could be included.]

Non-Functional Requirements
Performance: [Define performance expectations (e.g., response times, processing speed).]

Reliability: [Specify reliability goals (e.g., uptime, data integrity).]

Usability: [Outline the desired user experience and interface design.]

Security: [Address any security concerns or requirements (e.g., data protection, authentication).]

Scalability: [Describe how the software should handle increased loads or data volumes.]

Constraints
Time:

Budget:

Technology:

Pseudocode
function [MethodName]([ParameterType] [ParameterName], ...):

// Detailed steps of the algorithm or logic.

User Stories
As a [user role], I want to [goal] so that [reason].

As a [user role], I want to [goal] so that [reason].

Flowchart
[Include a visual diagram of the program's flow, showing the sequence of operations, decision points, and loops.]

Libraries and Dependencies
[List the external libraries or frameworks that the project will depend on, along with their versions and purposes.]

Technical Specifications
Programming Language:

Operating System:

Hardware Requirements:

Testing and Validation
[Describe the testing strategy]

Output

Example Input 1:

Description: [Describe the example input scenario.]

Input: [Provide a sample input or input format.]

Expected Output: [Describe the expected output for the given input.]
]]

		M.Learning = [[
[SUBJECT]=Topic or skill to learn
[CURRENT_LEVEL]=Starting knowledge level (beginner/intermediate/advanced)
[TIME_AVAILABLE]=Weekly hours available for learning
[LEARNING_STYLE]=Preferred learning method (visual/auditory/hands-on/reading)
[GOAL]=Specific learning objective or target skill level

Step 1: Knowledge Assessment
1. Break down [SUBJECT] into core components
2. Evaluate complexity levels of each component
3. Map prerequisites and dependencies
4. Identify foundational concepts
Output detailed skill tree and learning hierarchy

~ Step 2: Learning Path Design
1. Create progression milestones based on [CURRENT_LEVEL]
2. Structure topics in optimal learning sequence
3. Estimate time requirements per topic
4. Align with [TIME_AVAILABLE] constraints
Output structured learning roadmap with timeframes

~ Step 3: Resource Curation
1. Identify learning materials matching [LEARNING_STYLE]:
   - Video courses
   - Books/articles
   - Interactive exercises
   - Practice projects
2. Rank resources by effectiveness
3. Create resource playlist
Output comprehensive resource list with priority order

~ Step 4: Practice Framework
1. Design exercises for each topic
2. Create real-world application scenarios
3. Develop progress checkpoints
4. Structure review intervals
Output practice plan with spaced repetition schedule

~ Step 5: Progress Tracking System
1. Define measurable progress indicators
2. Create assessment criteria
3. Design feedback loops
4. Establish milestone completion metrics
Output progress tracking template and benchmarks

~ Step 6: Study Schedule Generation
1. Break down learning into daily/weekly tasks
2. Incorporate rest and review periods
3. Add checkpoint assessments
4. Balance theory and practice
Output detailed study schedule aligned with [TIME_AVAILABLE]
]]

		require("context_nvim").setup({
			cmp = {
				enable = true, -- whether to enable the nvim-cmp source for referencing contexts

				register_cmp_avante = true, -- whether to include the cmp source for avante input buffers.
				-- They need to be registered using an autocmd, so this is a separate config option
				manual_context_keyword = "@manual_context", -- keyword to use for manual context
				history_keyword = "@history_context", -- keyword to use for history context
				prompt_keyword = "@prompt", -- keyword to use for prompt context
			},
			telescope = {
				enable = true, -- whether to enable the telescope picker
			},
			blink = {
				manual_context_keyword = "@manual_context", -- keyword to use for manual context
				history_keyword = "@history_context", -- keyword to use for history context
				prompt_keyword = "@prompt", -- keyword to use for prompt context
			},
			prompts = {
				{
					name = "Unit tests", -- the name of the prompt (required)
					prompt = M.Unit_Tests, -- the prompt text (required)
					cmp = "unit_tests", -- an alternate name for the cmp completion source (optional) defaults to 'name'
				},
				{
					name = "Generate Code",
					prompt = M.Generate_Code,
					cmp = "gencode",
				},
				{
					name = "Explain Code",
					prompt = M.Explain,
					cmp = "explain",
				},
				{
					name = "Code Review",
					prompt = M.Code_Review,
					cmp = "review",
				},
				{
					name = "Architecture",
					prompt = M.Architecture,
					cmp = "architecture",
				},
				{
					name = "Write Code",
					prompt = M.Write_Code,
					cmp = "write_code",
				},
				{
					name = "Write Tests",
					prompt = M.Write_Tests,
					cmp = "write_test",
				},
				{
					name = "Debug Code",
					prompt = M.Debug_Code,
					cmp = "debug_code",
				},
				{
					name = "Refactor Code",
					prompt = M.Refactor_Code,
					cmp = "refactor_code",
				},
				{
					name = "Write Documentation",
					prompt = M.Write_Documentation,
					cmp = "write_doc",
				},
			},
		})
	end,
	keys = {
		{ "<localleader>af", "<cmd>ContextNvim add_current_file<cr>", desc = "Add current (f)ile" },
		{ "<localleader>ac", "<cmd>ContextNvim add_current<cr>", desc = "Add (c)urrent" },
		{ "<localleader>ad", "<cmd>ContextNvim add_dir<cr>", desc = "Add (d)ir" },
		{ "<localleader>aq", "<cmd>ContextNvim add_qflist<cr>", desc = "Add (q)uickfix list" },
		{ "<localleader>al", "<cmd>ContextNvim add_line_lsp_daig<cr>", desc = "Add line lsp diagnostic" },
		{ "<localleader>cch", "<cmd>ContextNvim clear_history<cr>", desc = "Clear history" },
		{ "<localleader>ccm", "<cmd>ContextNvim clear_manual<cr>", desc = "Clear manual" },
		{ "<localleader>im", "<cmd>ContextNvim find_context_manual<cr>", desc = "Find context manual" },
		{ "<localleader>ih", "<cmd>ContextNvim find_context_history<cr>", desc = "Find context history" },
		{ "<localleader>ip", "<cmd>ContextNvim insert_prompt<cr>", desc = "Insert prompt" },
	},
}
