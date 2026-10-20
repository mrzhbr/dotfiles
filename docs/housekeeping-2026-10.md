# Runtime housekeeping — 20 October 2026

## Applied baseline

Mise was upgraded through its existing Homebrew owner from **2026.7.14** to
**2026.10.15**. The public minimum version and bootstrap preflight now match.
A subsequent targeted native lane updated **39 Homebrew formulae**, with no
cask upgrades or old-keg cleanup. The private bootstrap was repaired separately.
Existing services were not restarted; the stopped Docker Desktop was started
for sandbox verification. Legacy NVM/Conda installations and PostgreSQL 14
were not removed.

| Tool | Previous | Selected |
| --- | --- | --- |
| Node (24 LTS) | 24.19.0 | 24.21.0 |
| Python (3.14) | 3.14.3 | 3.14.8 |
| uv | 0.10.2 | 0.13.0 |
| Bun | 1.3.10 | 1.4.3 |
| Temurin (25 LTS) | 25.0.3+9.0.LTS | 25.0.4+101.0.LTS |
| Maven (3.9) | 3.9.11 | 3.9.16 |
| AWS CLI | 2.34.11 | 2.37.13 |
| Bazelisk | 1.26.0 | 1.29.0 |
| GitHub CLI | 2.87.3 | 2.102.0 |
| Hadolint | 2.14.0 | 2.15.1 |
| Neovim | 0.12.3 | 0.12.6 |
| tree-sitter CLI | 0.26.9 | 0.27.1 |
| Tectonic | 0.15.0 | 0.17.0 |
| Herdr | 0.7.4 | 0.9.3 |
| Codex | 0.135.0 | 0.162.1 |
| OpenCode (V1) | 1.4.0 | 1.19.0 |
| Pi | 1.0.3 | 1.3.0 |
| Claude Code | 2.1.181 | 2.1.299 |

Git-filter-repo 2.47.0, Gitleaks 8.30.1, and ShellCheck 0.11.0 have no newer
eligible release in the mise check. Older runtime installations are retained
for project pins and rollback; do not run a blanket prune.

## Mise compatibility review

[Upstream changelog](https://github.com/jdx/mise/blob/main/CHANGELOG.md):

- Java's unspecified vendor now defaults to Temurin; our explicit Temurin pin
  already preserves the intended vendor.
- The experimental pkgx backend and legacy RTX environment aliases were removed;
  the public configuration does not use them.
- Unknown backend options are now rejected. Current tool declarations parse and
  resolve successfully. General identity-based layout remains opt-in; graph-locked
  npm/PyPI tools use graph-specific install identities after consolidation.
- Git-filter-repo's registry backend is now `pypi`, replacing `pipx`.
- [Lockfile format 3](https://mise.jdx.dev/dev-tools/mise-lock-reference.html#format-versions)
  adds request bindings and native dependency sidecars. The initial runtime pass
  retained format 0. Subsequent helper consolidation upgraded to format 3 after
  isolated locked replay of generated graphs for ctx7, browser-use, Pi 1.3 and
  git-filter-repo 2.47.0. Prior versions and unrelated native lock entries were
  preserved; the new SDK and browser graphs pass live functional smokes.
- The seven-day tool release-age policy remains enabled. Exact pins bypass that
  filter, so reviewed targets must be selected before pinning.

### Safe lockfile refresh

The global lockfile is a symlink to the repository lockfile. A lock run from
this checkout with `--global` was observed to write the project lock and then
prune it through its global symlink. Even though newer help describes separate
scopes, avoid relying on that distinction with this composition.

Preview from outside the checkout through the safe task (no writes):

```bash
mise run tools:lock:dry-run
```

Only after all other lanes finish, back up `mise.lock` outside the repository,
review the intended pin changes, and regenerate from outside the checkout:

```bash
MISE_LOCKED=0 mise --cd /tmp lock --global --platform macos-arm64
./scripts/validate.sh
mise install --dry-run-code --locked
```

Validation requires one matching entry per public pin, plus the explicitly
configured private Python dependency. There are **25 tools** and browser-use's
private Python **3.13.16** alongside main Python **3.14.8**. Commit/copy
`.mise/locks/` with the format-3 lock. A nonzero install preview means tools are
missing, not permission to apply unreviewed updates. After review, `mise install
--locked` and `mise reshim` apply the selections. Do not regenerate shared locks
concurrently or run another unreviewed format migration.

The installed Git-filter-repo short-name metadata was also migrated from
`pipx` to `pypi` using mise's supported backend switch at the same 2.47.0 pin.
Because the public lock had already switched, the migration used a temporary,
public-only config/old lock entry and backed up the old installation first.
No shared lock regeneration or manual metadata relabeling was needed. The
active command works and the backend mismatch warning is gone.

## Jupyter ownership and Python updates

The existing versioned mise Python kernel was valid, but the environment was
not reproducible and `jupyter-lab` still resolved to Homebrew. Notebook 7.6.3
and JupyterLab 4.6.4 now live in mise Python 3.14.8. All 52 pre-existing Python
packages other than pip were preserved at their original versions.

`config/python/requirements.in` records direct requirements; `requirements.txt`
pins the complete dependency set. The Python postinstall hook installs it and
registers **`mise-python`**, displaying **Python 3.14.8 (mise)**. Its absolute
interpreter path is refreshed whenever the hook runs. To repair/reapply:

```bash
mise run jupyter:setup
mise exec -- jupyter notebook
mise exec -- jupyter lab
```

Select that kernel in VS Code or Jupyter. Existing `mise-python-3.14.3` notebooks
remain usable because neither the old kernelspec nor interpreter is deleted.
The setup task also runs during bootstrap, including on an already installed
Python. The public shell removes the obsolete Homebrew `jupyter` alias on reload,
so both frontends follow mise activation. A disposable-HOME shell regression
covers that ownership rule. Project-specific libraries should still use project
environments.

To refresh the package lock intentionally, review the resulting version diff:

```bash
mise exec -- uv pip compile config/python/requirements.in --python-version 3.14 \
  --exclude-newer 7d --no-header --no-annotate \
  --output-file config/python/requirements.txt
mise run jupyter:setup
```

## Breaking changes and holds

- **Node 26 / Python 3.15: not selected.** Stay on Node 24 LTS and Python 3.14
  rather than combining runtime-major and notebook-dependency migrations.
- **uv 0.13:** unpinned downloads now default to Python 3.15. Use
  `uv venv --python 3.14` or a project `.python-version`. Intervening releases
  change certificate handling (`--system-certs` replaces `--native-tls`) and make
  `uv init` package new projects by default (`--no-package` restores the old
  layout). Constraints reject editables and enforce included hash directives;
  repeat `-c` for multiple paths. Caches may rebuild.
  [0.11](https://github.com/astral-sh/uv/releases/tag/0.11.0),
  [0.12](https://github.com/astral-sh/uv/releases/tag/0.12.0),
  [0.13](https://github.com/astral-sh/uv/releases/tag/0.13.0).
- **Bun 1.4:** new workspaces default to isolated linking; existing locks retain
  their linker. Node-compatible invocation no longer auto-loads `.env`; FFI
  cstring results are strings/null and TOML parsing is stricter. Existing project
  locks/configurations were not rewritten.
  [Migration notes](https://bun.com/blog/bun-v1.4).
- **Rust remains 1.93.1:** 1.99.0 has regressions fixed in 1.99.1, including
  macOS rust-lld/libLLVM loading. The announcement is dated 15 October, but the
  release object is dated 16 October. Revisit **23 October or later**, after
  verifying the selected artifact's full seven-day age, with project tests and
  the configured Clippy/rustfmt/analyzer components.
  [Compatibility and patch notes](https://doc.rust-lang.org/stable/releases.html).
- **Zig remains 0.16.0:** 0.17 has source/build API changes and documented ZLS
  incompatibility at release. Migrate representative projects/editor support
  before changing the global default.
  [Release notes](https://ziglang.org/download/0.17.0/release-notes.html).
- **Maven stays on 3.9:** 3.10 switches dependency traversal, tightens POM and
  toolchain validation, and changes Super POM/plugin defaults. Test builds and
  pin plugins explicitly before migrating.
  [Migration notes](https://maven.apache.org/docs/3.10.0/release-notes.html).
- **Pi advances to 1.3.0:** after the 1.2+ audit and explicit approval, the
  Harness now reapplies version-checked learning, goal, watchdog and theme
  compatibility patches. The selected 1.3 SDK passes credential-free user/custom
  startup, queued-followup and cancellation tests. This is an approved exception
  to the seven-day policy, not a global policy change. See
  [the compatibility review](pi-1.2-upgrade-review.md) for evidence and limits.
  [Changelog](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md).
- **Claude Code advances to 2.1.299:** explicitly approved on 20 October as an
  early security exception; the official tag was published **14 October 2026
  at 02:49:42 UTC**, before the seven-day window completes. The general `7d`
  policy remains unchanged, and 2.1.181 is retained for rollback. Official release
  notes fix the 2.1.296 approved-tool-call duplication on cloud/headless resume,
  denied-path symlink sandbox bypasses, plan-mode writes allowed by hooks, and
  third-party gateway credentials being sent to Anthropic endpoints. Local
  temporary-HOME startup/help and loopback permission checks passed: Read was
  denied for a synthetic denied path and its symlink, and Write was unavailable
  in plan mode. These are not sandbox-shell, hook-bypass, or exactly-once
  cloud/resume regression proofs; those fixes are upstream release claims.
  The existing private permission policy is unchanged; no private
  permission/auth/model settings were read by this change.
  [Official tagged release and publication date](https://github.com/anthropics/claude-code/releases/tag/v2.1.299),
  [Changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md).
- **Herdr 0.9.3:** plugins became user-global; old `agent send`/top-level wait
  commands and `--no-session` were replaced, and the proprietary pane graphics
  API was removed in favor of Kitty graphics. The existing keymap/config passes
  `herdr config check`. Save work before restarting old servers; this pass does
  not stop servers or update remote machines. Pi 1.3 includes the Herdr image
  fix from 1.2, but image rendering was not manually certified in this pass.
  [Changelog](https://github.com/herdrdev/herdr/blob/v0.9.3/CHANGELOG.md).
- **tree-sitter 0.27:** library APIs and HTML-highlight flags changed; these do
  not rewrite Neovim's embedded library or installed parsers. HTML consumers
  should review `--layout`/`--style`; parser generation still needs project tests.
  [Release notes](https://github.com/tree-sitter/tree-sitter/releases/tag/v0.27.0).
- **Neovim 0.12.6:** includes the 0.12.5 change where `:restart` and `ZR` restore sessions. No custom restart
  mappings need migration; normal headless startup was checked.
  [Release notes](https://github.com/neovim/neovim/commit/5885a30e1e1225349079e7a1c4a3848aa8e43e42).
- **Codex:** `codex mcp-server` was removed; integrations must migrate separately
  to the app-server interface (experimental). `tui.prompt_suggestions` was
  removed and unknown TUI keys now fail strict validation. Private Codex
  configuration/integrations were not inspected.
  [Changelog](https://developers.openai.com/codex/changelog).
- **OpenCode:** select supported V1; 1.19 requires explicit `--major` for V2.
  V2's permission/configuration migration is deferred, not silently applied.
  [Release notes](https://github.com/anomalyco/opencode/releases/tag/v1.19.0).
- **Tectonic:** bundles changed in 0.16 with stated legacy compatibility;
  `tectonic-biber` takes precedence when present. Compare document output before
  changing project bundles.
  [Changelog](https://github.com/tectonic-typesetting/tectonic/blob/tectonic@0.17.0/CHANGELOG.md).

GitHub CLI 2.102.0 includes important security fixes for download symlink handling
and attestation verification; this is not merely a feature update.
[Security notes](https://github.com/cli/cli/releases/tag/v2.102.0).

## Final integration and remaining limits

- Public/private validation passes. Isolated-HOME tests use the real non-tool
  bootstrap dry-run and separate tool metadata preview: mise 2026.10.15 wrongly
  requires installed PyPI prerequisites even in installer dry-run. That excluded
  phase is explicit; actual empty-data locked graph replay was tested separately.
  This is not a complete installation onto a newly erased Mac.
- Harness checks pass **25 tests** plus typechecking and host-mutation controls.
  A fresh locked payload install uses eight explicit SDK overrides/aliases,
  without blanket peer bypass, and reports zero npm audit findings. Actual Pi
  1.3 faux-provider checks pass with seven payloads and five live local
  extensions. Source-only installer imports are inert even with a matching
  `$0`; direct execution still reaches the installer.
- The tested payload, quoted-path `.env` guard, Context7 wrapper/locked helper
  **0.4.2**, and two corresponding skills were selectively applied with code
  backups. Auth, settings, models and learning state were not replaced. The
  `.env` command guard remains heuristic, not a shell security boundary.
- Browser-use **0.13.11** is now mise-owned with private Python **3.13.16**;
  its standalone uv-tool registration was retired. Context7's **0.4.2** helper is
  also mise-owned; Harness owns only its wrapper/skills. Browser Harness reports
  **0.1.13**. A fresh-profile, loopback-CDP
  smoke passes navigation/input/click/doctor checks without using personal
  Chrome or cloud services. CLI 3 is incompatible with the old command syntax;
  the updated skill requires explicit browser approval and endpoint selection.
- Sandbox lint/contracts and the rebuilt Pi 1.3 image were verified. Its preserved
  Chainguard base contains Node **26.1.0**, independent of the host's Node 24
  policy. Non-root runtime, dropped capabilities and no-new-privileges checks
  pass. Existing stopped Docker Desktop **4.43.1** was started and remains
  running; the **4.96.0** major engine/data migration is held for separate review.
- The original native audit left **80 formula updates and seven cask updates**
  before consolidation. Ten redundant Brew CLI copies have since been retired;
  see [the consolidation ledger](consolidation-plan.md). Remaining update reviews
  are not all proven compatibility blocks. llhttp **9.3.1** is kept linked for
  legacy Homebrew Node compatibility; installed **9.4.3** remains
  unlinked after a real SONAME failure and targeted rollback. Final native
  linkage passes. Existing Brew service state, including spotifyd's pre-existing
  error, is unchanged. The Finder list-view preference was converged without
  restarting Finder or Dock.

Runtime smoke tests do not certify every project, AI login, remote server,
notebook extension, or native dependency. This machine is not universally
up-to-date or security-certified. Restart Pi to load the replaced extension
code, and open a fresh shell for the selected tool paths. An inherited shell
can still find Claude 2.1.181; `mise exec -- claude --version` selects the verified
**2.1.299** immediately. No changes were staged, committed or pushed.
