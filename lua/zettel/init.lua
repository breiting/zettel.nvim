---@class ZettelPlugin
local M = {}

-- Import all modules
local config = require("zettel.config")
local notes = require("zettel.notes")
local links = require("zettel.links")
local search = require("zettel.search")
local keymaps = require("zettel.keymaps")
local cache = require("zettel.cache")
local commands = require("zettel.commands")
local autocmds = require("zettel.autocmds")
local utils = require("zettel.utils")
local view = require("zettel.view")

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

	-- Build the cache initially
	local start_time = vim.loop.hrtime()
	cache.build_cache()
	local elapsed = (vim.loop.hrtime() - start_time) / 1e6 -- ms
	vim.schedule(function()
		vim.notify(string.format("ZettelCache built in %.2f ms", elapsed), vim.log.levels.INFO)
	end)
end

-- Expose main functions for backward compatibility and external access
M.new_note = function()
	return notes.new_note()
end
M.open_journal = function()
	return notes.open_journal()
end
M.extract_to_new_note = function()
	return notes.extract_to_new_note()
end
M.capture_image = function()
	return notes.capture_image()
end
M.follow_link = function()
	return links.follow_link()
end
M.preview_note = function()
	return notes.preview_note()
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
M.toggle_checkbox = function()
	return utils.toggle_checkbox()
end
M.show_views = function()
	return view.show_views_list()
end
M.build_cache = function()
	return cache.build_cache()
end

return M
