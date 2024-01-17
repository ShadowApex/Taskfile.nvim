-- Creates an object for the module. All of the module's
-- functions are associated with this object, which is
-- returned when the module is called with `require`.
local M = {}
M.setup = function(_) end

-- Executes when a choice is selected
M.on_choice = function(item, _)
	M.run_task(item.name)
end

-- Open a selection window to select a task to run
M.open_window = function()
	-- Get the available tasks to choose from
	local tasks = M.get_tasks()

	-- If no tasks are available, say so instead
	if #tasks == 0 then
		print("No tasks found")
		return
	end

	-- Format how tasks will appear in the window
	local formatter = function(task)
		return task.name .. ": " .. task.desc
	end

	vim.ui.select(tasks, { prompt = "Task:", format_item = formatter }, M.on_choice)
end

-- Return a list of all tasks
M.get_tasks = function()
	local response = vim.fn.system("go-task --list --json")
	local data = vim.fn.json_decode(response)
	if data == nil or data.tasks == nil then
		return {}
	end

	return data.tasks
end

-- Execute the given task in a terminal window
M.run_task = function(task)
	vim.fn.execute(":terminal go-task " .. task)
end

-- Called whenever a user tries to tab complete
local complete = function(ArgLead, _, _)
	local promptKeys = {}

	-- Loop through all available tasks and see if they start with
	-- the arg letters.
	local tasks = M.get_tasks()
	for _, task in pairs(tasks) do
		if task.name:lower():match("^" .. ArgLead:lower()) then
			table.insert(promptKeys, task.name)
		end
	end

	table.sort(promptKeys)
	return promptKeys
end

-- Create a command, ':Task'
vim.api.nvim_create_user_command("Task", function(input)
	if input.args ~= "" then
		M.run_task(input.args)
		return
	end
	M.open_window()
end, { bang = true, desc = "Run tasks defined in a Taskfile", nargs = "?", complete = complete })

return M
