local M = {}

---Generate a random digit string
---@param digits number The number of digits which should be generated
function M.random_digits_str(digits)
	local num = math.random(0, 10 ^ digits - 1)
	return ("%0" .. digits .. "d"):format(num)
end

---Generate a unique ID for note filenames
---@param date_format? string Date format string (default: "%Y-%m-%d")
---@param random_digits? number Number of random digits (default: 3)
---@return string id The generated unique ID
function M.generate_id(date_format, random_digits)
	date_format = date_format or "%Y-%m-%d"
	random_digits = random_digits or 3

	local date = os.date(date_format)
	return date .. "-" .. M.random_digits_str(random_digits)
end

---Read note title from frontmatter
---@param filepath string Path to the markdown file
---@return string|nil title The title from frontmatter, or nil if not found
function M.get_note_title(filepath)
	local file = io.open(filepath, "r")
	if not file then
		return nil
	end

	local title = nil
	local in_frontmatter = false

	for line in file:lines() do
		if line:match("^---$") then
			if not in_frontmatter then
				in_frontmatter = true
			else
				break -- End of frontmatter
			end
		elseif in_frontmatter then
			local t = line:match("^title:%s*(.+)")
			if t then
				title = vim.trim(t)
				break
			end
		end
	end

	file:close()
	return title
end

---Extract the link under cursor between [[ and ]]
---@return string|nil link The link filename without .md extension, or nil if not found
function M.get_link_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.fn.col(".") -- Current cursor position (1-based)

	-- Search for all [[...]] links in the line
	for start_pos, link_text, end_pos in line:gmatch("()%[%[([^%]]+)%]%]()") do
		if col >= start_pos and col <= end_pos then
			-- Remove leading/trailing whitespace
			link_text = vim.trim(link_text)

			-- Split at '|' (Obsidian alias syntax)
			local filename = link_text:match("^(.-)|") or link_text

			-- Remove potential .md extension
			filename = filename:gsub("%.md$", "")

			return filename
		end
	end

	return nil
end

---Create frontmatter template for a new note
---@param id string The note ID
---@param title string The note title
---@param note_type? string The note type (default: "note")
---@return string[] template Array of lines for the frontmatter template
function M.create_frontmatter_template(id, title, note_type)
	note_type = note_type or "note"

	return {
		"---",
		"id: " .. id,
		"title: " .. title,
		"tags: [" .. note_type .. "]",
		"---",
		"",
		"# " .. title,
		"",
	}
end

---Get filename without extension from a path
---@param filepath string The file path
---@return string filename The filename without extension
function M.get_filename_without_ext(filepath)
	return vim.fn.fnamemodify(filepath, ":t:r")
end

---Check if a file exists and is readable
---@param filepath string Path to check
---@return boolean exists True if file exists and is readable
function M.file_exists(filepath)
	return vim.fn.filereadable(filepath) == 1
end

---Collect all markdown files in a directory
---@param directory string Directory to search
---@return string[] files Array of file paths
function M.get_markdown_files(directory)
	return vim.fn.globpath(directory, "*.md", false, true)
end

---Create a wikilink with optional alias
---@param id string The note ID
---@param title? string Optional title for alias
---@return string link The formatted wikilink
function M.create_wikilink(id, title)
	if title and title ~= "" then
		return string.format("[[%s|%s]]", id, title)
	else
		return string.format("[[%s]]", id)
	end
end

---Trim whitespace from a string
---@param str string String to trim
---@return string trimmed Trimmed string
function M.trim(str)
	return vim.trim(str)
end

-- Toggle a checkbox line
function M.toggle_checkbox()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if line contains unchecked checkbox
	if line:match("^%s*-%s*%[ %]") then
		-- Replace unchecked with checked
		local new_line = line:gsub("%[ %]", "[x]")
		vim.api.nvim_set_current_line(new_line)

		-- Check if line contains checked checkbox
	elseif line:match("^%s*-%s*%[x%]") then
		-- Replace checked with unchecked
		local new_line = line:gsub("%[x%]", "[ ]")
		vim.api.nvim_set_current_line(new_line)

		-- If no checkbox, do nothing
	else
		print("No checkbox found on this line")
	end
end

--- Search and replace placeholder for templates
function M.apply_placeholders(template_lines, values)
	local replaced = {}
	for _, line in ipairs(template_lines) do
		local new_line = line
		for key, val in pairs(values) do
			new_line = new_line:gsub("%$" .. key .. "%$", val)
		end
		table.insert(replaced, new_line)
	end
	return replaced
end

return M
