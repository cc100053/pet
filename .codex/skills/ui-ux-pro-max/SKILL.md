---
name: ui-ux-pro-max
description: Use when choosing visual design patterns or reviewing UI accessibility beyond PicPet's existing design system.
---

# UI/UX guidance

Reuse PicPet's existing components and Juice UI rules in `AGENTS.md`. Search
this database when those patterns do not answer the design question; routine
UI fixes do not require a new design system.

From the repository root, query Flutter implementation guidance:

```sh
python3 .codex/skills/ui-ux-pro-max/scripts/search.py "<question>" --stack flutter
```

For a specific design question, use `--domain ux`, `color`, `typography`, or
another domain listed by `--help`. Use the target's actual stack for work
outside the Flutter app.

Generate a design system with `--design-system` only for a requested new visual
direction. `--persist` optionally saves it; generated recommendations remain
subordinate to PicPet's established product decisions.

Preserve accessible contrast, touch targets, semantic labels, keyboard focus,
and reduced-motion support using the target platform's APIs. Generic web
examples and suggested palettes do not replace PicPet's typography, interaction,
localization, or component conventions.
