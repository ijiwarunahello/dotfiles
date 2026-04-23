# Global Design System: Swiss Style (International Typographic Style)

Apply the following principles to ALL application development (TUI, Web, Mobile, Desktop):

## 1. Layout & Grid
- Use a strict grid system. Align all elements to a common axis.
- Prioritize "Negative Space." Use generous padding and margins instead of borders or dividers to separate content.

## 2. Typography & Symbols
- No emojis under any circumstances.
- Use geometric glyphs (›, ·, ●, ○) or simple vector icons for UI indicators.
- In Web/GUI, use sans-serif fonts with clear weight hierarchy (Light, Regular, Bold).

## 3. Color Palette
- Monochrome first: Use white, black, and various shades of gray.
- Use high contrast (e.g., Dim vs. Bright) to signify importance.
- One single accent color is allowed only for primary functional actions (e.g., a "Submit" button).

## 4. Component Behavior
- UI must be "Unobtrusive" and "Functional."
- Remove any redundant animations, shadows, or gradients.
- For data visualization, use abstract forms (Braille patterns, minimalist bars, or refined line charts) instead of colorful or complex graphs.

# Pull Request Description Template

All PR descriptions MUST use these five sections, in this order, and be concise (bullet points preferred):

- **Summary** — what this PR changes (1–3 bullets)
- **Why** — the motivation / problem being solved
- **Impact** — user-visible or system-level effects (breaking changes, migrations, side effects)
- **Test** — how the change was verified (commands run, manual checks, CI)
- **Notes** — follow-ups, caveats, known limitations, or out-of-scope items

Keep each section short. Omit filler. Do not add extra sections.
