# Embedded Chinese font

`NotoSansSC-GameSubset.ttf` is a project-specific subset of Google Noto Sans SC.
It includes ASCII, the GB2312 character set, and every glyph currently referenced by
the game content and UI. The subset keeps Web downloads smaller while covering common
Chinese child names in the built-in custom-name path.

- Source: <https://github.com/google/fonts/tree/main/ofl/notosanssc>
- Upstream font: `NotoSansSC[wght].ttf`
- License: SIL Open Font License 1.1; see `NotoSansSC-OFL.txt`
- Subsetting tool: fontTools

The font is embedded as the Godot project default so Web and Android builds do not rely
on operating-system CJK font fallback.
