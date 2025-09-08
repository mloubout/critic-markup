# Critic-markup Extension For Quarto

This extension provides a filter for processing [CriticMarkup](https://github.com/CriticMarkup/CriticMarkup-toolkit) syntax when rendering to HTML, PDF (LaTeX), and DOCX. The HTML markup view includes a small in-page switcher to toggle views.

Supported views in all formats:

- Markup: changes highlighted (HTML adds ins/del/mark; PDF uses pdfcomment; DOCX uses Emphasis/Strikeout)
- Original: document before edits (additions removed, deletions kept)
- Edited: final document with changes applied


This extension was inspired by the critic markup processing for [ScholarlyMarkdown](http://scholarlymarkdown.com/) available under MIT license as well [ScholarlyMarkdown.git](https://github.com/slimgroup/ScholarlyMarkdown)
## Installing

```bash
quarto add mloubout/critic-markup
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

To use this extension, simply add it to your header as a filter

```yaml
---
title: Markup example
filters:
  - critic-markup
---
```

### Selecting mode (HTML, PDF, DOCX)

Select which version of the document to render by setting the `critic-mode` metadata. The following values are supported in all formats (HTML, PDF, DOCX):

* `markup` (default) – show changes with highlights.
* `original` – show the document before edits (additions removed, deletions kept).
* `edited` – show the final document with changes applied.

Example (PDF shown here; works the same for HTML and DOCX):

```yaml
---
title: Markup example
filters:
  - critic-markup
critic-mode: edited   # or original, markup
format: pdf
---
```

You can also render a specific version from the command line:

```bash
quarto render example.qmd --to pdf -M critic-mode=markup
quarto render example.qmd --to pdf -M critic-mode=original
quarto render example.qmd --to pdf -M critic-mode=edited

# HTML
quarto render example.qmd --to html -M critic-mode=edited

# DOCX
quarto render example.qmd --to docx -M critic-mode=markup
```

Note:

- For `critic-mode: markup` with PDF output, the LaTeX package `pdfcomment` is required. Install with TeX Live (`tlmgr install pdfcomment`) or your TeX distribution's package manager.
- For DOCX markup, deletions render as strikeout, insertions as emphasis, highlights as strong, and comments as inline bracketed notes (e.g. “[comment: …]”).
- For HTML original/edited, the output is static (no toggle UI). The toggle UI only appears in HTML markup mode.

## Rendered Examples

Here is a minimal example showing the CriticMarkup syntax and its rendering: [example.qmd](example.qmd).

- HTML:
  - [Markup](example-markup.html)
  - [Original](example-original.html)
  - [Edited](example-edited.html)

- PDF:
  - [Markup](example-markup.pdf)
  - [Original](example-original.pdf)
  - [Edited](example-edited.pdf)

- DOCX:
  - [Markup](example-markup.docx)
  - [Original](example-original.docx)
  - [Edited](example-edited.docx)

A published HTML markup example is also available here: https://mloubout.github.io/critic-markup/
