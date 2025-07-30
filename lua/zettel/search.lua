local telescope = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("zettel.utils")
local config = require("zettel.config")

---@class ZettelSearch
local M = {}

---Search for content within notes using live grep
---Uses Telescope's live_grep to search through all markdown files in the vault
function M.search_notes()
	local vault_dir = config.get_vault_dir()

	require("telescope.builtin").live_grep({
		prompt_title = "Search Notes (Full Text)",
		cwd = vault_dir,
		glob_pattern = "*.md",
		previewer = true,
		additional_args = function()
			return { "--hidden" }
		end,
	})
end

---Search through note titles using note's cache
---Finds and displays all notes based on their frontmatter titles
function M.search_titles()
	local cache = require("zettel.cache").notes
	local results = {}

	for _, note in ipairs(cache) do
		if note.title and note.title ~= "" then
			table.insert(results, {
				value = note.path,
				display = note.title,
				ordinal = note.title .. " " .. note.path,
				date = vim.fn.getftime(note.path),
			})
		end
	end

	table.sort(results, function(a, b)
		local da = a.date or ""
		local db = b.date or ""
		return da > db
	end)

	telescope
		.new({}, {
			prompt_title = "Search Note Titles",
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return entry
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(bufnr)
					vim.cmd("edit " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

---Search for notes by tags
---@param tag? string Optional specific tag to search for
function M.search_by_tag(tag)
	local cache = require("zettel.cache").notes
	local results = {}

	for _, note in ipairs(cache) do
		if tag then
			if vim.tbl_contains(note.tags, tag) then
				table.insert(results, {
					value = note.path,
					display = string.format("%s (%s)", note.title, vim.fn.fnamemodify(note.path, ":t:r")),
					ordinal = note.title .. " " .. table.concat(note.tags, " "),
				})
			end
		else
			-- If not tag is specified, add all notes with tags
			if #note.tags > 0 then
				table.insert(results, {
					value = note.path,
					display = string.format("%s (%s)", note.title, vim.fn.fnamemodify(note.path, ":t:r")),
					ordinal = note.title .. " " .. table.concat(note.tags, " "),
				})
			end
		end
	end

	local title_suffix = tag and (" - Tag: " .. tag) or ""
	telescope
		.new({}, {
			prompt_title = "Search by Tags" .. title_suffix,
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return entry
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(bufnr)
					vim.cmd("edit " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

---Get all unique tags from cache
---@return string[] tags Array of unique tags found in all notes
function M.get_all_tags()
	local cache = require("zettel.cache").notes
	local tags = {}
	local tag_set = {}

	for _, note in ipairs(cache) do
		for _, tag in ipairs(note.tags or {}) do
			if not tag_set[tag] then
				tag_set[tag] = true
				table.insert(tags, tag)
			end
		end
	end

	table.sort(tags)
	return tags
end

---Interactive tag search with tag selection
function M.search_tags_interactive()
	local all_tags = M.get_all_tags()

	if #all_tags == 0 then
		vim.notify("No tags found in vault", vim.log.levels.INFO)
		return
	end

	vim.ui.select(all_tags, {
		prompt = "Select tag to search:",
		format_item = function(item)
			return "#" .. item
		end,
	}, function(choice)
		if choice then
			M.search_by_tag(choice)
		end
	end)
end

---Show recently modified notes (do not use cache here!)
---@param limit? number Maximum number of notes to show (default: 20)
function M.search_recent(limit)
	limit = limit or 20
	local vault_dir = config.get_vault_dir()
	local files = utils.get_markdown_files(vault_dir)
	local results = {}

	for _, filepath in ipairs(files) do
		local stat = vim.loop.fs_stat(filepath)
		if stat then
			local title = utils.get_note_title(filepath) or utils.get_filename_without_ext(filepath)
			local filename = utils.get_filename_without_ext(filepath)
			local modified_time = stat.mtime.sec

			table.insert(results, {
				value = filepath,
				display = title .. " (" .. filename .. ")",
				ordinal = title .. " " .. filename,
				modified = modified_time,
			})
		end
	end

	-- Sort by modification time (newest first)
	table.sort(results, function(a, b)
		return a.modified > b.modified
	end)

	-- Limit results
	local limited_results = {}
	for i = 1, math.min(limit, #results) do
		table.insert(limited_results, results[i])
	end

	if #limited_results == 0 then
		vim.notify("No notes found", vim.log.levels.INFO)
		return
	end

	telescope
		.new({}, {
			prompt_title = "Recent Notes (Last " .. #limited_results .. ")",
			finder = finders.new_table({
				results = limited_results,
				entry_maker = function(entry)
					return entry
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(bufnr)
					vim.cmd("edit " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

return M
