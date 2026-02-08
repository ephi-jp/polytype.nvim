# polytype.nvim
Seamless polyglot typing for diacritics, Cyrillic, and Greek in Neovim.

PolyType watches the last few ASCII characters you type and replaces a matching
sequence with the desired glyph—much like Compose keys or the macOS Polyglot
layout—so you can stay on your usual keyboard while entering letters with
accents.

## Status

- Work in progress: the repository currently ships only the `latin` mapping
  (`data/polytype/latin.dat`). Additional modes for Cyrillic and Greek are on the
  roadmap.
- The plugin is buffer-local. Enabling a mode in one buffer does not affect the
  others, and disabling PolyType restores the buffer to its original state.

## Requirements

- Neovim 0.9 or newer with LuaJIT (PolyType relies on the built-in FFI module).
- Any terminal/GUI Neovim where insert-mode keymaps are available—there are no
  external dependencies or daemons to run.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "ephi-jp/polytype.nvim",
    config = function()
        local polytype = require("polytype")
        vim.keymap.set("i", "<C-g>ll", polytype.enable_latin, { desc = "PolyType: Enable latin mode" })
        vim.keymap.set("i", "<C-g>la", polytype.disable, { desc = "PolyType: Disable" })
    end,
}
```

Any other plugin manager can load the module in the same way, since the plugin
only exposes a Lua module and ships no native binaries.

### Public API

- `polytype.enable(mode_name, datfile?)`: enable `mode_name`. When `datfile` is
  omitted, PolyType looks for `data/polytype/<mode_name>.dat` in your
  `runtimepath`.
- `polytype.enable_latin()`: shorthand for the built-in Latin mapping.
- `polytype.disable()`: remove the buffer-local mappings installed by PolyType.
- `polytype.mode()`: returns the active mode in the current buffer (or `nil`).

## Modes and `.dat` files

Mappings live in compact `.dat` files generated offline as double-array-based
trie data.

The bundled `data/polytype/latin.dat` mapping covers the following letters from
Latin-1 Supplement, Latin Extended-A, and a few extras. For example, once latin
mode is enabled, typing `A;a` in insert mode immediately becomes `Á`:

| Diacritic | Keys | Supported letters |
|---|---|---|
| ACUTE         | `;a` | Á É Í Ó Ú Ý á é í ó ú ý Ć ć Ĺ ĺ Ń ń Ŕ ŕ Ś ś Ź ź |
| BREVE         | `;b` | Ă ă Ĕ ĕ Ğ ğ Ĭ ĭ Ŏ ŏ Ŭ ŭ |
| CARON         | `;h` | Č č Ď ď Ě ě Ľ ľ Ň ň Ř ř Š š Ť ť Ž ž |
| CEDILLA       | `;c` | Ç ç Ģ ģ Ķ ķ Ļ ļ Ņ ņ Ŗ ŗ Ş ş Ţ ţ |
| CIRCUMFLEX    | `;x` | Â Ê Î Ô Û â ê î ô û Ĉ ĉ Ĝ ĝ Ĥ ĥ Ĵ ĵ Ŝ ŝ Ŵ ŵ Ŷ ŷ |
| DIAERESIS     | `;u` | Ä Ë Ï Ö Ü ä ë ï ö ü ÿ Ÿ |
| DOT ABOVE     | `;d` | Ċ ċ Ė ė Ġ ġ İ Ż ż |
| DOUBLE ACUTE  | `;A` | Ő ő Ű ű |
| GRAVE         | `;g` | À È Ì Ò Ù à è ì ò ù |
| MACRON        | `;m` | Ā ā Ē ē Ī ī Ō ō Ū ū |
| MIDDLE DOT    | `;d` | Ŀ ŀ |
| OGONEK        | `;o` | Ą ą Ę ę Į į Ų ų |
| RING ABOVE    | `;r` | Å å Ů ů |
| STROKE        | `;s` | Ø ø Đ đ Ħ ħ Ł ł Ŧ ŧ |
| TILDE         | `;n` | Ã Ñ Õ ã ñ õ Ĩ ĩ Ũ ũ |
| COMMA BELOW   | `;C` | Ș ș Ț ț |

Additional multi-letter sequences:

| Keys | Supported letters |
|---|---|
| `AE;;` | Æ |
| `DH;;` | Ð |
| `TH;;` | Þ |
| `ss;;` | ß |
| `ae;;` | æ |
| `dh;;` | ð |
| `th;;` | þ |
| `i;d ` | ı |
| `IJ;;` | Ĳ |
| `ij;;` | ĳ |
| `NG;;` | Ŋ |
| `ng;;` | ŋ |
| `OE;;` | Œ |
| `oe;;` | œ |

## License

[MIT](LICENSE)
