# zettel.nvim

A minimal yet powerful [neovim](https://neovim.io) plugin for managing a **frictionless personal knowledge management (PKM)** system using Markdown files – inspired by the [Zettelkasten method](https://en.wikipedia.org/wiki/Zettelkasten).

- **Zero friction**: No folders, no manual filenames – just write.
- **Flat file structure**: One directory for all notes, IDs ensure uniqueness.
- **Frontmatter-based metadata**: Tags, titles, and properties instead of folder hierarchies.
- **Seamless navigation**: Jump between notes, search by title or full-text with Telescope.
- **Obsidian compatible**: Use the same vault in both neovim and [Obsidian](https://obsidian.md).

## Why zettel.nvim?

I struggled with my PKM for years, tested all different kinds of system, but never felt "at home", and never was satisfied. Until I found out the reason. I had too much friction. Which directory structure, which file naming scheme, which system. It somehow set me back and I never got into it as I was hoping. As a result I was thinking what may be the minimal setup which allows me to eliminate all friction? Well, zettel.nvim was the result, and perfectly fits my needs, since I am also a heavy neovim user. The main requirements for this plugin are:

- All notes live in **one flat folder** (your "vault").
- Files are named automatically with a simple system **date + random ID**: `YYYY-MM-DD-XYZ.md`.
- Meaningful information (title, tags, status) lives in the **frontmatter**:

  ```yaml
  ---
  id: 2025-07-24-042
  title: Howto write a note
  tags: [note]
  ---
  ```

You focus on writing and linking ideas, not on managing files.

## Features

- Create new notes instantly from within neovim (<leader>nn or :ZettelNew)
- Daily journal (<leader>zj or :ZettelJournal)
- Insert wiki-style links with titles ([[id|Title]])
- Follow links using `gf`
- Search by title with Telescope (<leader>zt)
- Full-text search with Telescope (<leader>zf)
- Extract selection to new note (visual mode, <leader>ze)
- Works seamlessly with Obsidian (supports Front Matter Title plugin)

## Installation

### Using lazy.nvim

```lua
{
    "breiting/zettel.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("zettel").setup({
            vault_dir = "~/zettel",
            note_types = { "note", "journal", "meeting", "meta" },
        })
    end,
}
```

### Using packer.nvim

```lua
use {
    "breiting/zettel.nvim",
    requires = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("zettel").setup()
    end
}
```

## Configuration

```lua
require("zettel").setup({
    -- Directory where your zettel notes are stored
    vault_dir = vim.fn.expand("~/zettel"),

    -- Available note types for selection when creating notes
    note_types = { "note", "capture", "journal", "meeting", "meta" },

    -- Date format for ID generation [default]
    date_format = "%Y-%m-%d",

    -- Number of random digits in note IDs [default]
    id_random_digits = 3,
})
```

## Usage

### Create a new note

```vim
:Zettel New [optional title]
```

or

```vim
<leader>nn
```

### Default Keymaps

Global keymaps (available everywhere):

- `<leader>nn` - Create new note
- `<leader>zf` - Search full text in notes
- `<leader>zt` - Search note titles
- `<leader>zr` - Show recent notes
- `<leader>zg` - Search by tags (interactive)
- `<leader>ze` - Extract selection to new note (visual mode)

Buffer-local keymaps (in vault markdown files):

- `gf` or `<CR>` - Follow link under cursor
- `[[` - Insert link (opens Telescope picker)

### Commands

- `:ZettelNew` - Create a new note
- `:ZettelExtract` - Extract selection to new note
- `:ZettelSearch` - Full-text search
- `:ZettelSearchTitle` - Search note titles
- `:ZettelSearchTags [tag]` - Search by tags
- `:ZettelRecent [limit]` - Show recent notes
- `:ZettelInsertLink` - Insert a link
- `:ZettelFollowLink` - Follow link under cursor
- `:ZettelInfo` - Show plugin information

### Note Format

Notes are created with YAML frontmatter:

```markdown
---
id: 2024-01-15-001
title: My Note Title
tags: [note, idea]
---

# My Note Title

Content goes here...

You can link to other notes using [[2024-01-15-002|Another Note]].
```

### Workflow Examples

1. **Create a new note**: Press `<leader>nn`, enter title and select type
2. **Link to another note**: Type `[[` and select from the picker
3. **Follow a link**: Place cursor on a link and press `gf`
4. **Extract text to note**: Select text and press `<leader>ze`
5. **Find related notes**: Press `<leader>zb` to see backlinks
6. **Search by topic**: Press `<leader>zg` to search by tags

## Architecture

The plugin is structured in modules for maintainability and extensibility:

- `init.lua` - Main plugin entry point
- `config.lua` - Configuration management
- `utils.lua` - Utility functions
- `notes.lua` - Note creation and management
- `links.lua` - Link handling and navigation
- `search.lua` - Search functionality
- `keymaps.lua` - Keymap configuration
- `commands.lua` - User commands
- `autocmds.lua` - Autocommands for vault files

## Requirements

- Neovim >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- `ripgrep` (for searching functionality)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.
