---@class ZettelKeymaps
local M = {}

---Setup default keymaps for the zettel plugin
---@param zettel ZettelPlugin The main plugin object
function M.setup(zettel)
	-- Global keymaps (available everywhere)
	vim.keymap.set("n", "<leader>nn", zettel.new_note, {
		desc = "Zettel: Create new note",
	})

	vim.keymap.set("n", "<leader>zf", zettel.search_notes, {
		desc = "Zettel: Search full text",
	})

	vim.keymap.set("n", "<leader>zt", zettel.search_titles, {
		desc = "Zettel: Search note titles",
	})

	vim.keymap.set("n", "<leader>zj", zettel.open_journal, {
		desc = "Zettel: Open today's journal",
	})

	vim.keymap.set("n", "<leader>zi", zettel.capture_image, {
		desc = "Zettel: Capture an image with a screenshot (macos only!)",
	})

	vim.keymap.set("n", "<leader>zr", function()
		zettel.search.search_recent()
	end, {
		desc = "Zettel: Search recent notes",
	})

	vim.keymap.set("n", "<leader>zg", function()
		zettel.search.search_tags_interactive()
	end, {
		desc = "Zettel: Search by tags",
	})

	-- Visual mode keymap for extracting selections
	vim.keymap.set("v", "<leader>ze", zettel.extract_to_new_note, {
		desc = "Zettel: Extract selection to new note",
	})
end

---Setup buffer-local keymaps for markdown files in the vault
---@param zettel ZettelPlugin The main plugin object
function M.setup_buffer_keymaps(zettel)
	-- Follow link under cursor
	vim.keymap.set("n", "gf", zettel.follow_link, {
		buffer = true,
		desc = "Zettel: Follow link under cursor",
	})

	-- Alternative follow link mapping
	vim.keymap.set("n", "<CR>", zettel.follow_link, {
		buffer = true,
		desc = "Zettel: Follow link under cursor",
	})

	-- Insert link when typing [[
	vim.keymap.set("i", "[[", function()
		zettel.insert_link_titles()
	end, {
		buffer = true,
		desc = "Zettel: Insert link",
		noremap = true,
	})
end

return M
