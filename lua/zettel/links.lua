local telescope = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("zettel.utils")
local notes = require("zettel.notes")
local config = require("zettel.config")

---@class ZettelLinks
local M = {}

---Open Telescope picker to insert a wikilink
---Shows all notes in the vault with their titles and allows selection
---to insert a formatted wikilink at the cursor position
function M.insert_link_titles()
	local vault_dir = config.get_vault_dir()
	local note_list = notes.collect_notes_with_titles(vault_dir)

	if #note_list == 0 then
		vim.notify("No notes found in vault", vim.log.levels.WARN)
		return
	end

	telescope
		.new({
			prompt_title = "Insert Zettel Link",
			finder = finders.new_table({
				results = note_list,
				entry_maker = function(entry)
					return {
						value = entry.filename,
						display = entry.title .. " (" .. entry.filename .. ")",
						ordinal = entry.title .. " " .. entry.filename,
						title = entry.title,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Insert wikilink with alias
					local link_text = utils.create_wikilink(selection.value, selection.title)
					vim.api.nvim_put({ link_text }, "c", true, true)
				end)
				return true
			end,
		})
		:find()
end

---Follow the wikilink under the cursor
---Extracts the link ID from [[id|title]] or [[id]] format and opens the corresponding note
function M.follow_link()
	local link = utils.get_link_under_cursor()
	if not link then
		vim.notify("No link under cursor", vim.log.levels.WARN)
		return
	end

	local success = notes.open_note(link)
	if not success then
		-- Offer to create the note if it doesn't exist
		vim.ui.select(
			{ "Create new note", "Cancel" },
			{ prompt = "Note '" .. link .. "' does not exist. What would you like to do?" },
			function(choice)
				if choice == "Create new note" then
					M.create_note_from_link(link)
				end
			end
		)
	end
end

---Create a new note from a broken link
---@param note_id string The ID for the new note
function M.create_note_from_link(note_id)
	local vault_dir = config.get_vault_dir()
	local filename = note_id .. ".md"
	local filepath = vault_dir .. "/" .. filename

	-- Use the note_id as the default title (can be changed by user)
	local title = note_id:gsub("-", " "):gsub("_", " ")

	-- Capitalize first letter of each word
	title = title:gsub("(%w)(%w*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)

	vim.ui.input({ prompt = "Note Title: ", default = title }, function(title_input)
		local final_title = title_input and utils.trim(title_input) or title

		vim.ui.select(config.get_note_types(), { prompt = "Note Type:" }, function(choice)
			local note_type = choice or "note"

			-- Create template
			local template = utils.create_frontmatter_template(note_id, final_title, note_type)

			-- Create and open the file
			vim.cmd("edit " .. filepath)
			vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
			vim.cmd("write")

			-- Position cursor at the end
			local lastline = vim.api.nvim_buf_line_count(0)
			vim.api.nvim_win_set_cursor(0, { lastline, 0 })

			vim.notify("Created new note: " .. final_title, vim.log.levels.INFO)
		end)
	end)
end

---Find all wikilinks in the current buffer
---@return table[] links Array of link objects with position and content
function M.find_links_in_buffer()
	local links = {}
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for line_nr, line in ipairs(lines) do
		for start_col, link_text, end_col in line:gmatch("()%[%[([^%]]+)%]%]()") do
			local filename = link_text:match("^(.-)|") or link_text
			filename = filename:gsub("%.md$", "")

			table.insert(links, {
				line = line_nr,
				start_col = start_col,
				end_col = end_col - 1,
				filename = filename,
				display_text = link_text,
				exists = notes.note_exists(filename),
			})
		end
	end

	return links
end

---Validate all links in the current buffer
---Shows a list of broken links and offers to create missing notes
function M.validate_links()
	local links = M.find_links_in_buffer()
	local broken_links = {}

	for _, link in ipairs(links) do
		if not link.exists then
			table.insert(broken_links, link)
		end
	end

	if #broken_links == 0 then
		vim.notify("All links are valid!", vim.log.levels.INFO)
		return
	end

	local broken_list = {}
	for _, link in ipairs(broken_links) do
		table.insert(broken_list, string.format("Line %d: [[%s]]", link.line, link.display_text))
	end

	vim.ui.select(
		broken_list,
		{ prompt = "Found " .. #broken_links .. " broken link(s). Select one to create:" },
		function(choice, idx)
			if choice and idx then
				local selected_link = broken_links[idx]
				M.create_note_from_link(selected_link.filename)
			end
		end
	)
end

---Get all backlinks to the current note
---@return table[] backlinks Array of files that link to the current note
function M.get_backlinks()
	local current_file = vim.fn.expand("%:t:r") -- Current filename without extension
	local vault_dir = config.get_vault_dir()
	local backlinks = {}

	local files = utils.get_markdown_files(vault_dir)

	for _, filepath in ipairs(files) do
		local filename = utils.get_filename_without_ext(filepath)

		-- Skip the current file
		if filename ~= current_file then
			local file = io.open(filepath, "r")
			if file then
				local content = file:read("*all")
				file:close()

				-- Search for links to current file
				local pattern = "%[%[" .. current_file .. "[|%]]"
				if content:match(pattern) then
					local title = utils.get_note_title(filepath) or filename
					table.insert(backlinks, {
						filename = filename,
						title = title,
						filepath = filepath,
					})
				end
			end
		end
	end

	return backlinks
end

---Show backlinks to the current note using Telescope
function M.show_backlinks()
	local backlinks = M.get_backlinks()

	if #backlinks == 0 then
		vim.notify("No backlinks found for this note", vim.log.levels.INFO)
		return
	end

	telescope
		.new({}, {
			prompt_title = "Backlinks to " .. vim.fn.expand("%:t:r"),
			finder = finders.new_table({
				results = backlinks,
				entry_maker = function(entry)
					return {
						value = entry.filepath,
						display = entry.title .. " (" .. entry.filename .. ")",
						ordinal = entry.title .. " " .. entry.filename,
					}
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
