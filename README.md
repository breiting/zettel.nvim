# zettel.nvim

A minimal yet powerful [neovim](https://neovim.io) plugin for managing a **frictionless personal knowledge management (fPKM)** system using Markdown files – inspired by the [Zettelkasten method](https://en.wikipedia.org/wiki/Zettelkasten).

- Zero friction: No folders, no manual filenames – just write and link ideas.
- Flat file structure: A single directory for all notes, with unique IDs to keep things organized.
- Frontmatter-driven metadata: Titles, tags, and properties replace complex folder hierarchies.
- Seamless navigation: Effortlessly jump between notes or search by title/full-text using Telescope.
- Views can be created to filter and organize virtual notes
- Obsidian-compatible: Use the same vault seamlessly in both Neovim and [Obsidian](https://obsidian.md).

## Why zettel.nvim?

After years of experimenting with various PKM setups, I kept running into the same problem: **friction**.
Which folder structure should I use? How should I name my files? Which system should I commit to?
These questions constantly got in my way and prevented me from truly engaging with my notes.

`zettel.nvim` is the result of stripping all that complexity away. It’s a minimal, opinionated setup that lets me focus entirely on writing and connecting ideas — and it integrates perfectly into my Neovim workflow.

The core principles are simple:

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

> You focus on writing and linking ideas, not on managing files.

## Features

- Create new notes instantly from within neovim (<leader>nn or :ZettelNew)
- Daily journal (<leader>zj or :ZettelJournal)
- Insert wiki-style links with titles ([[id|Title]])
- Follow links using `gf` (also supports preview of images)
- Preview link content using `K`
- Search by title with Telescope (<leader>zt)
- Define views for virtually group notes of similar type (<leader>zv)
- Full-text search with Telescope (<leader>zf)
- Extract selection to new note (visual mode, <leader>ze)
- Capture a screenshot and add the image to the note (MacOS only!)
- Works seamlessly with Obsidian (supports [Front Matter Title plugin](https://github.com/snezhig/obsidian-front-matter-title))

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

    -- Asset directory (for images)
    assets_dir = "_assets",

    -- Templates directory
    templates_dir = "_templates",

    -- Number of random digits in note IDs [default]
    id_random_digits = 3,
})
```

## Usage

### Create a new note

```vim
:ZettelNew [optional title]
```

or

```vim
<leader>nn
```

### Open/create today's journal

```vim
:ZettelJournal
```

or

```vim
<leader>zj
```

### Search note titles

```vim
:ZettelSearchTitle
```

### Full-text search

```vim
:ZettelSearchFull
```

### Capture a screenshot

This feature is currently only supported on MacOS with `screencapture`.

```vim
:ZettelCaptureImage
```

or

```vim
<leader>zi
```

## Default Keymaps

- `<leader>nn` - Create new note
- `<leader>zf` - Search full text in notes
- `<leader>zt` - Search note titles
- `<leader>zr` - Show recent notes
- `<leader>zg` - Search by tags (interactive)
- `<leader>ze` - Extract selection to new note (visual mode)

Buffer-local keymaps (in vault markdown files):

- `gf` or `<CR>` - Follow link under cursor
- `[[` - Insert link (opens Telescope picker)

## Commands

- `:ZettelNew` - Create a new note
- `:ZettelExtract` - Extract selection to new note
- `:ZettelSearch` - Full-text search
- `:ZettelSearchTitle` - Search note titles
- `:ZettelSearchTags [tag]` - Search by tags
- `:ZettelRecent [limit]` - Show recent notes
- `:ZettelInsertLink` - Insert a link
- `:ZettelFollowLink` - Follow link under cursor
- `:ZettelInfo` - Show plugin information

## Note Format

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

### View Notes

View notes are notes which group notes. Currently The current version is a primitive version.

```markdown
---
id: 2025-07-29-265
title: My View
tags: [view]
---

\`\`\`view
tags: content
\`\`\`
```

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

- neovim >= 0.10.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- `ripgrep` (for searching functionality)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.
