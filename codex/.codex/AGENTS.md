# Global Guidance For Codex

Canonical source for shared agent guidance in this dotfiles repo. Claude should reference this file instead of duplicating the content.

## Design System: Swiss Style (International Typographic Style)

Apply the following principles to all application development, including TUI, web, mobile, and desktop work:

### 1. Layout and Grid

- Use a strict grid system. Align all elements to a common axis.
- Prioritize negative space. Use generous padding and margins instead of borders or dividers to separate content.

### 2. Typography and Symbols

- Do not use emojis.
- Use geometric glyphs such as `>`, `.`, `*`, or simple vector icons for UI indicators.
- In web and GUI work, use sans-serif fonts with clear weight hierarchy such as Light, Regular, and Bold.

### 3. Color Palette

- Start monochrome-first: white, black, and gray.
- Use high contrast to show importance.
- Allow a single accent color only for primary functional actions.

### 4. Component Behavior

- UI must stay unobtrusive and functional.
- Remove redundant animations, shadows, and gradients.
- For data visualization, prefer abstract forms such as minimalist bars or refined line charts over colorful or complex graphs.

## Pull Request Description Template

All PR descriptions must use these five sections, in this order, and stay concise:

- **Summary**: what this PR changes in 1-3 bullets
- **Why**: the motivation or problem being solved
- **Impact**: user-visible or system-level effects, including breaking changes, migrations, or side effects
- **Test**: how the change was verified, including commands, manual checks, or CI
- **Notes**: follow-ups, caveats, known limitations, or out-of-scope items

Keep each section short. Omit filler. Do not add extra sections.
Write PR descriptions in Japanese unless the user explicitly asks for another language.
