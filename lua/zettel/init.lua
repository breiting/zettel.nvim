local M = {}

local telescope = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Default Config
M.config = {
	vault_dir = vim.fn.expand("~/zettel"),
	use_date_prefix = true,
}

-- Setup function (user config)
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})
end

-- Read note title from frontmatter
local function get_note_title(filepath)
	local file = io.open(filepath, "r")
	if not file then
		return nil
	end

	local title = nil
	local in_frontmatter = false

	for line in file:lines() do
		if line:match("^---$") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break -- Ende Frontmatter
			end
		elseif in_frontmatter then
			local t = line:match("^title:%s*(.+)")
			if t then
				title = t
				break
			end
		end
	end

	file:close()
	return title
end

-- Collect all titles from all notes in the vault, required for telescope note finding
local function collect_notes_with_titles(vault_dir)
	local notes = {}
	local files = vim.fn.globpath(vault_dir, "*.md", false, true)
	for _, filepath in ipairs(files) do
		local title = get_note_title(filepath) or vim.fn.fnamemodify(filepath, ":t:r")
		local filename = vim.fn.fnamemodify(filepath, ":t:r") -- ID ohne .md
		table.insert(notes, { title = title, filename = filename })
	end
	return notes
end

-- Telescope Picker for adding a new link
function M.insert_link_titles()
	local vault_dir = vim.fn.expand(M.config.vault_dir)
	local notes = collect_notes_with_titles(vault_dir)

	telescope
		.new({
			prompt_title = "Insert Zettel Link",
			finder = finders.new_table({
				results = notes,
				entry_maker = function(entry)
					return {
						value = entry.filename,               -- ID als Link
						display = entry.title .. " (" .. entry.filename .. ")", -- Titel anzeigen
						ordinal = entry.title .. " " .. entry.filename,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					-- Füge [[ID]] ein
					vim.api.nvim_put({ "[[" .. selection.value .. "]]" }, "c", true, true)
				end)
				return true
			end,
		})
		:find()
end

-- Generate a unique ID for the filename
local function generate_id()
	math.randomseed(os.time())
	local date = os.date("%Y-%m-%d")
	local random = string.format("%03d", math.random(0, 999))
	return date .. "-" .. random
end

-- Create a new note
function M.new_note()
	local vault_dir = vim.fn.expand(M.config.vault_dir)
	vim.fn.mkdir(vault_dir, "p")

	local id = generate_id()
	local filename = id .. ".md"
	local filepath = vault_dir .. "/" .. filename

	vim.ui.input({ prompt = "Note Title: " }, function(title_input)
		local title = title_input and vim.trim(title_input) or "Untitled"

		-- Schritt 2: Typ-Auswahl
		local types = { "note", "capture", "journal", "meeting" }
		vim.ui.select(types, { prompt = "Note Type:" }, function(choice)
			local tag = choice or "note"

			-- Template dynamisch
			local template = {
				"---",
				"id: " .. id,
				"title: " .. title,
				"tags: [" .. tag .. "]",
				"---",
				"",
				"# ",
			}

			-- Datei schreiben/öffnen
			if vim.fn.filereadable(filepath) == 0 then
				vim.cmd("edit " .. filepath)
				vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
				vim.cmd("write")
			else
				vim.cmd("edit " .. filepath)
			end

			-- Cursor ans Ende setzen
			local lastline = vim.api.nvim_buf_line_count(0)
			vim.api.nvim_win_set_cursor(0, { lastline, 0 })
			-- vim.cmd("startinsert")
		end)
	end)
end

-- Extracts the link under cursor between [[ and ]]
local function get_link_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".") -- aktuelle Cursorposition (1-basiert)

	-- Suche alle [[...]]-Links im Line
	for start_pos, link_text, end_pos in line:gmatch("()%[%[([^%]]+)%]%]()") do
		if col >= start_pos and col <= end_pos then
			-- Entferne führende/trailende Leerzeichen
			link_text = vim.trim(link_text)

			-- Split bei '|' (Obsidian Alias)
			local filename = link_text:match("^(.-)|") or link_text

			-- Entferne evtl. vorhandene .md Endung
			filename = filename:gsub("%.md$", "")

			return filename
		end
	end

	return nil
end

-- Follow the link under cursor between [[ and ]]
function M.follow_link()
	local link = get_link_under_cursor()
	if not link then
		vim.notify("No link under cursor", vim.log.levels.WARN)
		return
	end

	local vault_dir = vim.fn.expand(M.config.vault_dir)
	local filepath = vault_dir .. "/" .. link .. ".md"

	if vim.fn.filereadable(filepath) == 1 then
		vim.cmd("edit " .. filepath)
	else
		vim.notify("Link not found: " .. filepath, vim.log.levels.ERROR)
	end
end

-- Search for notes using telescope
function M.search_notes()
	local vault_dir = vim.fn.expand(M.config.vault_dir)
	require("telescope.builtin").live_grep({
		prompt_title = "Search Notes (Vault)",
		cwd = vault_dir,
		glob_pattern = "*.md",
		previewer = true,
	})
end

-- Default Keymaps
function M.keymaps()
	vim.keymap.set("n", "<leader>nn", M.new_note, { desc = "New Zettel Note" })
	vim.keymap.set("n", "<leader>sn", M.search_notes, { desc = "Search Notes in Vault" })
end

-- Autocmd: Initialize environment for vault
function M.autocmd()
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = M.config.vault_dir .. "/*.md",
		callback = function()
			vim.keymap.set("n", "gf", M.follow_link, { buffer = true, desc = "Follow Zettel Link" })
			vim.keymap.set("i", "[[", function()
				-- Öffnet Telescope, wenn `[[` getippt wird
				M.insert_link_titles()
			end, { desc = "Insert Zettel Link", noremap = true })
		end,
	})
end

-- Initialization
M.setup()
M.autocmd()
M.keymaps()

return M
