# zettel.nvim

A powerful neovim plugin for managing a simple and minimalistic personal knowledge management (PKM) system with markdown files. It removes any friction, and concentrates on writing and navigating in your notes (similar to a Zettelkasten system). No thinking about where to put your files, no thinking about how to name your files, the system keeps track, and the tools offer a simple interface.

## Features

- **Note Creation**: Create new notes with unique IDs and frontmatter
- **Link Management**: Insert and follow wikilinks with `[[note-id|title]]` syntax
- **Search**: Full-text search, title search, tag search
- **Extract Notes**: Convert selected text into new linked notes
- **Recent Notes**: Quick access to recently modified notes

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
