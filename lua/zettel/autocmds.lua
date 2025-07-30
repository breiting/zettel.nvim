local keymaps = require("zettel.keymaps")
local cache = require("zettel.cache")
local config = require("zettel.config")

---@class ZettelAutocmds
local M = {}

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
end

return M
