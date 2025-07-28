-- Plugin specification for package managers like lazy.nvim
-- This file will be automatically loaded when the plugin is installed

-- Ensure the plugin is only loaded once
if vim.g.loaded_zettel then
	return
end
vim.g.loaded_zettel = 1

-- Auto-initialize with default settings if not explicitly set up
local zettel = require("zettel")

-- Setup with default configuration if not already done
if not zettel.config.get().vault_dir then
	zettel.setup()
end
