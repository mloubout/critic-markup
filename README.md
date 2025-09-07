# Critic-markup Extension For Quarto

This extension provide a filter for processing [critic markup](https://github.com/CriticMarkup/CriticMarkup-toolkit) syntax when rendering to html. The rendered html provide a flexible interface with

- The markup document with changes highlighted
- The original version
- The updated version with the changes applied


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

### Rendering to PDF

When producing PDF output, you can select which version of the document to render by setting the `critic-mode` metadata. The following values are supported:

* `markup` (default) – show changes with highlights.
* `original` – show the document before edits (additions removed, deletions kept).
* `edited` – show the final document with changes applied.

Example:

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
```

Note:

- For `critic-mode: markup` with PDF output, the LaTeX package `pdfcomment` is required. Install with TeX Live (`tlmgr install pdfcomment`) or your TeX distribution's package manager. The build intentionally fails if `pdfcomment` is not available.

## Example

Here is a minimal example showing the critic markup syntax and its rendering: [example.qmd](example.qmd).
PDF renderings of this example are available:

- [Markup](example-markup.pdf)
- [Original](example-original.pdf)
- [Edited](example-edited.pdf)

This is the output of [example.qmd](https://mloubout.github.io/critic-markup/).
