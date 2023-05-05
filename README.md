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

## Example

Here is a minimal example showing the critic markup syntax and its rendering: [example.qmd](example.qmd).

This is the output of [example.qmd](example.qmd).