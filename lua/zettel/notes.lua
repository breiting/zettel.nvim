local utils = require("zettel.utils")
local config = require("zettel.config")

---@class ZettelNotes
local M = {}

--- Load a template file
local function load_template(note_type)
	local template_file = config.get_templates_dir() .. "/" .. note_type .. ".md"
	if vim.fn.filereadable(template_file) == 1 then
		return vim.fn.readfile(template_file)
	end
	return {} -- Empty template
end

-- Open or create a new journal note
function M.open_journal(date)
	local vault_dir = config.get_vault_dir()

	-- Use given date or today
	local target_date = date or os.date("%Y-%m-%d")

	-- Check if a journal with this date already exists
	local existing_file = nil
	local rg_cmd = string.format('rg --files-with-matches "^title: %s" %s', target_date, vim.fn.shellescape(vault_dir))
	local handle = io.popen(rg_cmd)
	if handle then
		for line in handle:lines() do
			existing_file = line
			break
		end
		handle:close()
	end

	local filepath
	if existing_file then
		-- Reuse existing file
		filepath = existing_file
	else
		-- Create new journal
		local id = utils.generate_id(config.date_format, config.id_random_digits)
		filepath = vault_dir .. "/" .. id .. ".md"

		-- Load journal template, or create a default frontmatter
		local template = load_template("journal")
		if not template or vim.tbl_isempty(template) then
			template = {
				"---",
				"id: " .. id,
				"title: " .. target_date,
				"tags: [journal]",
				"date: " .. target_date,
				"habits: []",
				"---",
				"",
			}
		else
			-- Apply supported placeholder
			local values = {
				id = id,
				title = target_date,
				date = target_date,
			}
			template = utils.apply_placeholders(template, values)
		end

		vim.cmd("edit " .. filepath)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
		vim.cmd("write")
		vim.cmd("normal! G")
		return
	end

	-- Open existing journal
	vim.cmd("edit " .. filepath)
	vim.cmd("normal! G")
end

---Create a new note with user input for title and type
function M.new_note()
	local vault_dir = config.get_vault_dir()

	local id = utils.generate_id(config.date_format, config.id_random_digits)
	local filename = id .. ".md"
	local filepath = vault_dir .. "/" .. filename

	-- Get note title from user
	vim.ui.input({ prompt = "Note Title: " }, function(title_input)
		local title = title_input and utils.trim(title_input) or "Untitled"

		-- Get note type from user
		vim.ui.select(config.get_note_types(), { prompt = "Note Type:" }, function(choice)
			local note_type = choice or "note"

			-- Load template, or create a default frontmatter
			local template = load_template(note_type)
			if not template or vim.tbl_isempty(template) then
				template = utils.create_frontmatter_template(id, title, note_type)
			else
				-- Apply supported placeholder
				local values = {
					id = id,
					title = title,
					today = os.date("%Y-%m-%d"),
				}
				template = utils.apply_placeholders(template, values)
			end

			-- Create and open the file
			if not utils.file_exists(filepath) then
				vim.cmd("edit " .. filepath)
				vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
				vim.cmd("write")
			else
				vim.cmd("edit " .. filepath)
			end

			-- Position cursor at the end
			local lastline = vim.api.nvim_buf_line_count(0)
			vim.api.nvim_win_set_cursor(0, { lastline, 0 })
		end)
	end)
end

---Extract selected text to a new note and replace with wikilink
---Takes the current visual selection, creates a new note with that text as title,
---and replaces the selection with a wikilink to the new note
function M.extract_to_new_note()
	-- Get current visual selection
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	local selection

	if #lines == 1 then
		-- Single line selection
		selection = string.sub(lines[1], start_pos[3], end_pos[3])
	else
		-- Multi-line selection (rare for titles)
		selection = table.concat(lines, "\n")
	end

	local title = utils.trim(selection)
	if title == "" then
		vim.notify("No text selected for extraction", vim.log.levels.WARN)
		return
	end

	-- Generate new note
	local vault_dir = config.get_vault_dir()
	local id = utils.generate_id(config.date_format, config.id_random_digits)
	local filename = id .. ".md"
	local filepath = vault_dir .. "/" .. filename

	-- Create frontmatter and content template
	local template = utils.create_frontmatter_template(id, title, "note")
	table.insert(template, "") -- Add extra empty line

	-- Create the new note file
	if not utils.file_exists(filepath) then
		-- Temporarily switch to new file
		local original_buf = vim.fn.bufnr("%")
		vim.cmd("edit " .. filepath)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
		vim.cmd("write")

		-- Return to original buffer
		vim.cmd("buffer " .. original_buf)
	end

	-- Replace selection with wikilink
	local link_text = utils.create_wikilink(id, title)
	vim.api.nvim_buf_set_text(0, start_pos[2] - 1, start_pos[3] - 1, end_pos[2] - 1, end_pos[3], { link_text })

	vim.notify("Extracted to new note: " .. title, vim.log.levels.INFO)
end

---Collect all notes with their titles from the vault
---@param vault_dir string Directory to search for notes
---@return table[] notes Array of note objects with title and filename
function M.collect_notes_with_titles(vault_dir)
	local notes = {}
	local files = utils.get_markdown_files(vault_dir)

	for _, filepath in ipairs(files) do
		local title = utils.get_note_title(filepath) or utils.get_filename_without_ext(filepath)
		local filename = utils.get_filename_without_ext(filepath)
		table.insert(notes, { title = title, filename = filename })
	end

	return notes
end

---Check if a note exists in the vault
---@param note_id string The note ID to check
---@return boolean exists True if the note exists
function M.note_exists(note_id)
	local filepath = config.get_vault_dir() .. "/" .. note_id .. ".md"
	return utils.file_exists(filepath)
end

---Get the full path to a note file
---@param note_id string The note ID
---@return string filepath The full path to the note file
function M.get_note_path(note_id)
	return config.get_vault_dir() .. "/" .. note_id .. ".md"
end

---Open a note by its ID
---@param note_id string The note ID to open
---@return boolean success True if the note was opened successfully
function M.open_note(note_id)
	local filepath = M.get_note_path(note_id)

	if utils.file_exists(filepath) then
		vim.cmd("edit " .. filepath)
		return true
	else
		vim.notify("Note not found: " .. note_id, vim.log.levels.ERROR)
		return false
	end
end

---Capture an image using the screencapture feature of macos and add the link to the current note
---@return boolean success True if image was added successfully
function M.capture_image()
	local assets_dir = config.get_assets_dir()
	vim.fn.mkdir(assets_dir, "p")

	local filename = os.date("%Y-%m-%d-%H%M%S") .. ".png"
	local filepath = assets_dir .. "/" .. filename

	-- MacOS only!
	vim.fn.system({ "screencapture", "-i", filepath })

	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to get capture image", vim.log.levels.ERROR)
		return true
	end

	local link = "![[" .. filename .. "]]"
	vim.api.nvim_put({ link }, "c", true, true)
	return true
end

---Preview a note (show content in a floating window)
function M.preview_note()
	local link = utils.get_link_under_cursor()
	if not link then
		return
	end
	local filepath = config.get_vault_dir() .. "/" .. link .. ".md"

	if vim.fn.filereadable(filepath) == 0 then
		vim.notify("Note not found: " .. link, vim.log.levels.WARN)
		return
	end

	local lines = vim.fn.readfile(filepath)
	local preview = {}
	local in_frontmatter = false
	local preview_length = 10

	for _, line in ipairs(lines) do
		if line == "---" then
			in_frontmatter = not in_frontmatter
		elseif not in_frontmatter then
			table.insert(preview, line)
			if #preview >= preview_length then
				break
			end -- only the first 10 lines
		end
	end

	-- Floating Window
	local opts = {
		border = "rounded",
	}
	vim.lsp.util.open_floating_preview(preview, "markdown", opts)
end

return M
