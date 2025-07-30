local keymaps = require("zettel.keymaps")
local cache = require("zettel.cache")
local config = require("zettel.config")

---@class ZettelAutocmds
local M = {}

-- Set hightlights for bold and italic
local function set_markdown_highlights()
	vim.api.nvim_set_hl(0, "@markup.strong", { bg = "#2f4a2f", bold = true })
	vim.api.nvim_set_hl(0, "@markup.italic", { bg = "#4a2f2f", italic = true })
end

-- 1. Autocmd für Theme-Wechsel
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_markdown_highlights,
})

---Setup autocommands for the zettel plugin
function M.setup(zettel)
	-- Create augroup for zettel plugin
	local augroup = vim.api.nvim_create_augroup("ZettelPlugin", { clear = true })

	-- Setup buffer-local keymaps and settings for vault files
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		group = augroup,
		pattern = config.get_vault_dir() .. "/*.md",
		callback = function()
			-- Setup buffer-local keymaps
			keymaps.setup_buffer_keymaps(zettel)
		end,
		desc = "Setup zettel environment for vault files",
	})

	-- Auto-save when leaving insert mode in vault files
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		pattern = config.get_vault_dir() .. "/*.md",
		callback = function()
			if vim.bo.modified then
				vim.cmd("silent! write")
			end
		end,
		desc = "Auto-save zettel notes when leaving insert mode",
	})

	-- Refresh cache, if a file gets stored
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		callback = function(args)
			local vault = config.get_vault_dir()
			local file = vim.fn.expand(vim.fn.shellescape(args.file))

			-- Check if file is in fault
			if string.sub(file, 1, #vault) == vault then
				cache.build_cache()
			end
		end,
	})

	-- Setup optimized color highlights
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = set_markdown_highlights,
	})

	set_markdown_highlights()
end

return M
