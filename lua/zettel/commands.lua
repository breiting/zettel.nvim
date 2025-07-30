---@class ZettelCommands
local M = {}

---Setup user commands for the zettel plugin
---@param zettel ZettelPlugin The main plugin object
function M.setup(zettel)
	-- Note creation commands
	vim.api.nvim_create_user_command("ZettelNew", function()
		zettel.new_note()
	end, {
		desc = "Create a new zettel note",
	})

	-- Journal creation commands
	vim.api.nvim_create_user_command("ZettelJournal", function(opts)
		if opts.args and opts.args ~= "" then
			zettel.notes.open_journal(opts.args)
		else
			zettel.notes.open_journal()
		end
	end, {
		desc = "Opens or create a new journal note",
	})

	vim.api.nvim_create_user_command("ZettelAdd", function()
		zettel.add_current_buffer_as_note()
	end, {
		desc = "Create a new note with the content of the current buffer",
	})

	vim.api.nvim_create_user_command("ZettelExtract", function()
		zettel.extract_to_new_note()
	end, {
		range = true,
		desc = "Extract selection to new zettel note",
	})

	vim.api.nvim_create_user_command("ZettelCaptureImage", function()
		zettel.capture_image()
	end, {
		desc = "Capture an image with a screenshot (macos only!)",
	})

	-- Search commands
	vim.api.nvim_create_user_command("ZettelSearch", function()
		zettel.search_notes()
	end, {
		desc = "Search zettel notes (full text)",
	})

	vim.api.nvim_create_user_command("ZettelSearchTitle", function()
		zettel.search_titles()
	end, {
		desc = "Search zettel note titles",
	})

	vim.api.nvim_create_user_command("ZettelSearchTags", function(opts)
		if opts.args and opts.args ~= "" then
			zettel.search.search_by_tag(opts.args)
		else
			zettel.search.search_tags_interactive()
		end
	end, {
		nargs = "?",
		desc = "Search zettel notes by tags",
		complete = function()
			return zettel.search.get_all_tags()
		end,
	})

	vim.api.nvim_create_user_command("ZettelRecent", function(opts)
		local limit = tonumber(opts.args) or 20
		zettel.search.search_recent(limit)
	end, {
		nargs = "?",
		desc = "Show recent zettel notes",
	})

	-- Link commands
	vim.api.nvim_create_user_command("ZettelInsertLink", function()
		zettel.insert_link_titles()
	end, {
		desc = "Insert a link to another zettel note",
	})

	vim.api.nvim_create_user_command("ZettelFollowLink", function()
		zettel.follow_link()
	end, {
		desc = "Follow the link under cursor",
	})

	-- Refresh zettel cache
	vim.api.nvim_create_user_command("ZettelRefresh", function()
		zettel.build_cache()
		vim.notify("Zettel cache refreshed")
	end, {})

	-- Utility commands
	vim.api.nvim_create_user_command("ZettelInfo", function()
		local config = zettel.config.get()
		local vault_dir = config.vault_dir
		local files = require("zettel.utils").get_markdown_files(vault_dir)
		local note_count = #files

		local info = {
			"Zettel Plugin Information:",
			"========================",
			"Vault Directory: " .. vault_dir,
			"Total Notes: " .. note_count,
			"Date Format: " .. config.date_format,
			"Available Note Types: " .. table.concat(config.note_types, ", "),
		}

		vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
	end, {
		desc = "Show zettel plugin information",
	})
end

return M
