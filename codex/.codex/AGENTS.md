# Global Guidance For Codex

Canonical source for shared agent guidance in this dotfiles repo.
Task-specific instructions (design system, PR template, project naming) are defined as skills and loaded on demand.

## Communication Language

- Respond to the user in Japanese unless the user explicitly asks for another language or writes their request in another language other than Japanese.
- This rule applies to chat replies, status updates, and inline narration.
- Do not use emojis. Use geometric glyphs such as `>`, `.`, `*` for UI indicators.

## Agent Workspace Operation

- Do not create or rely on agent-specific workspaces such as `~/Workspaces/ws_codex` or `~/Workspaces/ws_claude`.
- Treat `~/Workspaces/src` as the trusted workspace root.
- Do normal project work inside `~/Workspaces/src/github.com/<owner>/<repo>` or a worktree managed from that repository.
- Start new project planning and initial research from the inbox repository at `~/Workspaces/src/github.com/ijiwarunahello/workspace-inbox`, unless `AGENT_INBOX_REPO` points to another inbox repository under the trusted workspace root.
- When planning turns into implementation, move into the target project repository or worktree before editing files or running project commands.
- If work must start outside `~/Workspaces/src`, ask the user before proceeding.
