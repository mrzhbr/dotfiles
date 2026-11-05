# Tool consolidation workflow

## Objective and ownership

Use one intentional owner per executable. Mise owns runtimes and standalone
CLIs; Homebrew supplies native libraries, services and GUI apps through mise
bootstrap declarations. Pi Harness owns its payloads and integration assets.
Project dependencies and private configuration remain separate.

Being first on PATH is not evidence that a second installation is obsolete.
Do not combine ownership migration with unrelated major upgrades or broad
package pruning. Public manifests declare intended ownership, not the current
state of any particular machine.

## Read-only inventory

```bash
mise run tools:audit
mise run tools:audit -- --json
mise run tools:audit -- --strict
```

The audit checks executable resolution and installed package-manager receipts
without executing helpers or reading private shell files. Strict mode checks
mise command ownership; it does not authorize removing duplicates. Native
runtime libraries, project environments and GUI applications may still depend
on a package even when its command is not selected.

For example, Homebrew's `tree-sitter` library and headers are distinct from the
mise-owned tree-sitter CLI. A CLI replacement does not replace a native ABI.
Missing installed-receipt metadata must be treated conservatively.

Keep resulting host inventories, private project paths and migration decisions
in private operational records, not in this public guide.

## Scoped migration

For each explicitly approved package batch:

1. Identify command paths, dependencies, running consumers and project references
   without inspecting credentials, environments or application data.
2. Back up program code and establish a rollback plan outside Git.
3. Install the supported replacement through its declared owner.
4. Verify aliases, actual arguments, runtime behavior and native linkage.
5. Obtain approval for the exact legacy-removal list before removing anything.
6. Re-run ownership and functional checks before proceeding.

Never interpret a missing Homebrew consumer as proof that an interpreter,
database, NVM/Conda environment or application is unused. Rebuild dependent
projects with their own locks/tests before retiring their base runtime. Do not
force dependency bypasses or remove user data to obtain a clean inventory.

## Helper and platform boundaries

Standalone Context7/browser-helper installations must not be recreated when
mise is their declared owner. Broken ownership fails rather than silently
installing another copy. Browser quarantine is intentional and must be retained.

Host macOS and sandbox Linux installations have separate dependency graphs;
never share their native modules or Python virtual environments. Treat immutable
source pins, publisher provenance, graph integrity and runtime compatibility as
distinct verification requirements.

## Ongoing maintenance

Follow [the maintenance procedure](maintenance.md) for reviewed pin/lock updates
and Python hashes. Preview bootstrap without applying it. Make service starts,
application restarts, database migration and removal separate approval steps.
Keep inventories and rollout outcomes private; no general guide certifies a
machine as fully current or secure.
