---@class ZettelPlugin
local M = {}

-- Import all modules
local config = require("zettel.config")
local notes = require("zettel.notes")
local links = require("zettel.links")
local search = require("zettel.search")
local keymaps = require("zettel.keymaps")
local commands = require("zettel.commands")
local autocmds = require("zettel.autocmds")

-- Module references for external access
M.config = config
M.notes = notes
M.links = links
M.search = search

---Initialize the zettel plugin with user configuration
function M.setup(opts)
	-- Initialize random generator
	math.randomseed(vim.loop.hrtime())

	-- Initialize configuration first
	config.setup(opts)

	-- Setup keymaps, commands, and autocmds
	keymaps.setup(M)
	commands.setup(M)
	autocmds.setup(M)
end

-- Expose main functions for backward compatibility and external access
M.new_note = function()
	return notes.new_note()
end
M.extract_to_new_note = function()
	return notes.extract_to_new_note()
end
M.follow_link = function()
	return links.follow_link()
end
M.insert_link_titles = function()
	return links.insert_link_titles()
end
M.search_notes = function()
	return search.search_notes()
end
M.search_titles = function()
	return search.search_titles()
end

return M
