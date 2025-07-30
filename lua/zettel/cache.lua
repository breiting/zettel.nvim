local M = {
	notes = {}, -- Cache table with all notes
}

local config = require("zettel.config")
local utils = require("zettel.utils")

---Scan and build cache for vault
function M.build_cache()
	M.notes = {}

	local vault = config.get_vault_dir()
	local ignore_dirs = config.get_ignore_dirs()

	local cmd = { "rg", "--files", vault, "-g", "*.md" }
	for _, dir in ipairs(ignore_dirs) do
		table.insert(cmd, "-g")
		table.insert(cmd, "!" .. dir .. "/**")
	end

	local handle = io.popen(table.concat(cmd, " "))
	if not handle then
		return
	end

	for file in handle:lines() do
		local meta = utils.parse_frontmatter(file) or {}
		local file_mtime = vim.fn.getftime(file)

		table.insert(M.notes, {
			id = meta.id,
			title = meta.title or vim.fn.fnamemodify(file, ":t"),
			tags = meta.tags or {},
			status = meta.status,
			date = meta.date or os.date("%Y-%m-%d", file_mtime),
			mtime = file_mtime,
			path = file,
		})
	end

	handle:close()
	-- print(vim.inspect(M.notes))
end

return M
