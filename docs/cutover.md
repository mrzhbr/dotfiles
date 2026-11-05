# Configuration cutover checklist

Nothing here is automatic. Review each phase and verify it before proceeding.

## 1. Review source and destination

- Validate the public layer and any private overlay together.
- Review committed and uncommitted paths; do not mix unrelated work.
- Confirm remote ownership/visibility and that public templates contain no
  credentials, real host mappings or operational inventories.
- Keep detailed acceptance notes and machine state private.

## 2. Back up managed targets

Run `mise run backup:dry-run`. Only after reviewing the target list should
`mise run backup:apply` create its scoped backup outside both repositories.
The backup script excludes authentication stores, environment files, histories,
sessions, SSH keys and cloud credentials. Verify rollback before replacement.

## 3. Install replacements without removing working tools

Use locked selections and verify actual versions/arguments. Keep native ABI
consumers and project environments in mind; don't remove legacy managers or
start services simply because a new tool was installed. See
[tool consolidation](consolidation-plan.md).

## 4. Apply public dotfiles deliberately

Apply forced replacement only after backup and explicit approval. Test a fresh
login shell before closing the working terminal. Preserve Ghostty/Herdr/tmux
fallbacks when trialling Rex; do not change default-terminal or server settings
as an incidental config operation. Personal Rex files remain outside Git.

## 5. Respect separate application owners

Pi Harness is separate and can replace settings, model configuration and
extension/skill trees. Use its ownership opt-outs and do not rerun its full
bootstrap merely to apply a small source change. The private overlay remains
authoritative for private configuration; credentials remain with login stores.
Never bypass browser/sandbox quarantine or interactive push review.

## 6. Verify before any removal

Check shell/project activation, runtime versions, editor/terminal behavior,
owned aliases and relevant native linkage. Database migration, restarts, legacy
removal and application cleanup require their own reviewed plan. Passing tests
is not permission to delete retained state or a claim of universal security.
