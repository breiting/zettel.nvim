---@class ZettelConfig
---@field vault_dir string Path to the zettel vault directory
---@field note_types string[] Available note types for selection
---@field date_format string Format string for date generation
---@field id_random_digits number Number of random digits in ID

---@type ZettelConfig
local default_config = {
	vault_dir = vim.fn.expand("~/zettel"),
	note_types = { "note", "capture", "journal", "meeting", "meta" },
	date_format = "%Y-%m-%d",
	id_random_digits = 3,
}

local M = {}
local config = {}

---Resolve symbolic links in a path
---@param path string The path to resolve
---@return string resolved_path The resolved absolute path
local function resolve_symlink(path)
	return vim.fn.resolve(vim.fn.expand(path))
end

---Setup configuration with user options
---@param opts? ZettelConfig User configuration options
function M.setup(opts)
	config = vim.tbl_deep_extend("force", default_config, opts or {})

	-- Resolve symbolic links in vault directory
	config.vault_dir = resolve_symlink(config.vault_dir)

	-- Ensure vault directory exists
	vim.fn.mkdir(config.vault_dir, "p")
end

---Get the current configuration
---@return ZettelConfig config The current configuration
function M.get()
	return config
end

---Get the vault directory path
---@return string vault_dir The vault directory path
function M.get_vault_dir()
	return config.vault_dir
end

---Get available note types
---@return string[] note_types Array of available note types
function M.get_note_types()
	return config.note_types
end

---Get date format string
---@return string date_format The date format string
function M.get_date_format()
	return config.date_format
end

---Get number of random digits for ID generation
---@return number random_digits Number of random digits
function M.get_id_random_digits()
	return config.id_random_digits
end

return M
