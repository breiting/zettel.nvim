local M = {}

local cache = require("zettel.cache")

---Get all view files from vault
local function get_all_views()
	local results = {}

	-- Search for files with "tags: [view]"
	local notes = cache.notes
	for _, note in ipairs(notes) do
		if note.tags and vim.tbl_contains(note.tags, "view") then
			table.insert(results, {
				file = note.path,
				title = note.title or vim.fn.fnamemodify(note.path, ":t"),
			})
		end
	end

	return results
end

---Parse view definition block
local function parse_view(view_file)
	local lines = vim.fn.readfile(view_file)
	local in_block = false
	local filters = {}

	for _, line in ipairs(lines) do
		if line:match("^```view") then
			in_block = true
		elseif line:match("^```") and in_block then
			break
		elseif in_block then
			-- Simple parser: key: value
			local key, val = line:match("^(%S+)%s*:%s*(.+)$")
			if key and val then
				filters[key] = val
			end
		end
	end

	return filters
end

---Apply query filter on all notes
local function run_query(filters)
	local notes = cache.notes
	local results = {}

	for _, note in ipairs(notes) do
		if filters.tags then
			if not (note.tags and vim.tbl_contains(note.tags, filters.tags)) then
				goto continue
			end
		end

		if filters.status then
			if not (note.status and note.status == filters.status) then
				goto continue
			end
		end

		if filters.date then
			if not note.date or note.date < filters.date then
				goto continue
			end
		end

		table.insert(results, {
			path = note.path,
			title = note.title or vim.fn.fnamemodify(note.path, ":t"),
			tags = note.tags or {},
			date = vim.fn.getftime(note.path),
		})

		::continue::
	end

	return results
end

---Use telescope for output filtered notes
local function show_query_results(filters)
	local results = run_query(filters)

	table.sort(results, function(a, b)
		local da = a.date or ""
		local db = b.date or ""
		return da > db
	end)

	require("telescope.pickers")
		.new({}, {
			prompt_title = "View Results",
			finder = require("telescope.finders").new_table({
				results = results,
				entry_maker = function(note)
					return {
						value = note.path,
						display = note.title,
						ordinal = note.title .. " " .. table.concat(note.tags, " "),
					}
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			previewer = require("telescope.config").values.file_previewer({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					require("telescope.actions").close(bufnr)
					vim.cmd("edit " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

---Show all views in a floating window
local function show_views_list()
	local views = get_all_views()
	if #views == 0 then
		vim.notify("No views found", vim.log.levels.WARN)
		return
	end

	local lines = {}
	for i, view in ipairs(views) do
		table.insert(lines, string.format("%d. %s", i, view.title))
	end

	-- Centered window
	local width = math.floor(vim.o.columns * 0.5)
	local height = #lines + 2
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " VIEWS ",
	})

	vim.keymap.set("n", "<CR>", function()
		local idx = vim.fn.line(".")
		local selected = views[idx]
		vim.api.nvim_win_close(win, true)
		if selected then
			local filters = parse_view(selected.file)
			show_query_results(filters)
		end
	end, { buffer = buf, nowait = true })

	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, nowait = true })
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------
M.show_views_list = show_views_list

return M
