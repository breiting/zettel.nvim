# `nvim-zettel.nvim`

This is a simple and minimalistic neovim plugin for organizing and writing frictionless notes. The focus is set on simplicity, no extra batteries included.

## Usage

Create a new note with `<leader>-nn`.

Please use your favorite plugin manager, I am using `lazy.vim` with the following configuration.
All `config` parameters are optional, and are initialized with defaults.

```
{
    "breiting/nvim-zettel.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("zettel").setup({
        vault_dir = "~/zettel",
      })
    end,
}
```
