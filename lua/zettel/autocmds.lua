local keymaps = require("zettel.keymaps")

---@class ZettelAutocmds
local M = {}

---Setup autocommands for the zettel plugin
---@param zettel ZettelPlugin The main plugin object
function M.setup(zettel)
	local config = zettel.config.get()

	-- Create augroup for zettel plugin
	local augroup = vim.api.nvim_create_augroup("ZettelPlugin", { clear = true })

	-- Setup buffer-local keymaps and settings for vault files
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		group = augroup,
		pattern = config.vault_dir .. "/*.md",
		callback = function()
			-- Setup buffer-local keymaps
			keymaps.setup_buffer_keymaps(zettel)
		end,
		desc = "Setup zettel environment for vault files",
	})

	-- Auto-save when leaving insert mode in vault files
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		pattern = config.vault_dir .. "/*.md",
		callback = function()
			if vim.bo.modified then
				vim.cmd("silent! write")
			end
		end,
		desc = "Auto-save zettel notes when leaving insert mode",
	})
end

return M
