# Mise-first workstation consolidation

## Objective

One intentional owner per tool, one declarative control plane, and a predictable
upgrade process. Being first on PATH is not enough: an unused second installation
is still maintenance debt. Prefer consolidation at the same working version
before combining it with unrelated major upgrades.

Mise is the default for runtimes and standalone developer/AI CLIs. Its npm and
PyPI backends can isolate JavaScript and Python applications without unmanaged
`npm -g`, `pip install` into the main interpreter, pipx, or separate uv-tool
ownership. uv may remain mise's implementation detail rather than another
inventory to maintain manually.

Do not force native libraries or GUI bundles into unsuitable backends merely to
claim everything lives physically in mise. Homebrew remains the native/app
implementation layer where appropriate, declared through mise bootstrap. Git,
tmux and multimedia/TeX dependencies are pragmatic exceptions until an equivalent
mise installation is demonstrated. Mise itself is a Homebrew-owned bootstrap
prerequisite. macOS-provided programs are not removal targets.

## Configuration boundaries

- Public baseline: this repository's `mise.toml`, lockfile and ownership contract.
- Private additions: the existing private mise layer; no identities or credentials
  move into public manifests.
- Project runtimes/libraries: project configuration and isolated environments,
  not additions to the workstation's scientific interpreter.
- Pi payloads/extensions: Harness owns its application dependencies and supported
  host contract. They are not independent global CLI installations to flatten.
- Container tooling: separate Linux environments are necessary; never share host
  Python virtual environments or native npm modules with the sandbox.
- Auth, application profiles, model data and databases: stay in their existing
  appropriate stores, not the installation tree.

## 1. Measure actual ownership

```bash
mise run tools:audit
mise run tools:audit -- --json
mise run tools:audit -- --strict
```

This command queries installation metadata and checks PATH without running tool
binaries, sourcing private shell files, or changing installations/configuration.
`--strict` fails for missing or wrongly resolved mise commands; it does not
pretend every Brew duplicate is removable. It checks the baseline declared in
`tool-ownership.json`, not every possible application or project on disk.

Brew dependency analysis uses **installed runtime receipts**, including retained
versions, rather than assuming today's formula dependencies describe yesterday's
installed binaries. Missing receipt metadata falls back conservatively to the
formula definition. Neither result proves absence of external/project consumers.

The initial audit found a real cutover gap: `bazelisk` belonged to mise but
`bazel` still resolved to Homebrew. The postinstall now creates a guarded relative
`bazel` symlink inside the mise prefix. A no-download local-Bazel fixture verifies
argument forwarding. All **49 mise-owned commands**, including the pinned Python
development CLIs, now resolve to their selected installations. The hook uses mise's documented `MISE_TOOL_INSTALL_PATH` variable;
the older `MISE_INSTALL_PATH` name was not supplied by this mise version.

## 2. Consolidate standalone helper installers

Applied: **`npm:ctx7@0.4.2`** and **`pypi:browser-use@0.13.11`** are now declared
in the public mise baseline. Browser-use has its own mise-managed Python
**3.13.16**, independent of workstation Python 3.14. The main notebook hook skips
private Python dependencies, so they cannot replace the workstation kernel.
The pinned mise documentation describes the per-tool Python selection:

<https://github.com/jdx/mise/blob/v2026.10.15/docs/dev-tools/backends/pypi.md>

The new locked installs were staged before cutover; real SDK and fresh-profile
loopback-CDP browser smokes pass. The live SDK/browser checks also pass. The old
host ctx7 prefix and standalone browser-use uv-tool registration were retired
with program-code backups. Harness auto/mise ownership now refuses to create
standalone duplicates when helpers are declared, including missing/partial/wrong
versions. Context7 prefers the selected PATH helper; browser consent safeguards
and separate sandbox Linux helper environments are preserved.

Python dependency graphs require lock revision 2 or later. The lock was upgraded
to **format 3** after isolated preparation/replay, with generated sidecars for
ctx7, browser-use, existing Pi 1.3 and git-filter-repo 2.47.0. All prior tool
versions and unrelated native lock entries were preserved; the new SDK passes
the actual compatibility smoke. Commit/copy `.mise/locks/` with `mise.lock`.
The shared-lock symlink trap still requires the outside-checkout refresh procedure.

## 3. Retire redundant installations in small batches

Completed the approved first two batches: **awscli, bazelisk, gh,
git-filter-repo, gitleaks, maven, neovim, tectonic, tree-sitter-cli and zig** were
removed from Brew after replacement/alias smokes, installed-receipt consumer
checks, running-executable checks and program-keg backups. All selected commands
remain mise-owned; native linkage and Brew service-state equality pass. Reviewed
managed executable sources contain no hardcoded references to those retired
prefixes. No autoremove, general cleanup, service restart or app-data removal ran.

The next batch retired **Brew JupyterLab**, bringing the total to **11** Brew
CLI removals. Its extension set matched the mise environment, no Brew consumers
or active Jupyter/Brew Python processes were found, and isolated notebook
execution passed before and after removal. Program-code rollback material was
retained; notebooks, user settings and other environments were not removed.

That check exposed a real dependency leak: some frozen notebook/development
requirements were satisfied only by the old Python user-site directory. Setup
now uses Python `-I`, isolated pip with configuration disabled, and an explicit
interpreter prefix. Fifteen already-pinned distributions were installed into
mise's Python without version changes. User-site copies were left intact, not
silently pruned. Isolated imports must pass before kernel registration.

Run `mise run jupyter:check` for the live functional check: it uses a temporary
HOME, a test-owned kernel over Unix IPC, and no user-site packages. It executes
NumPy/Pandas computation and renders a Matplotlib PNG without personal notebooks
or user configuration. Static validation does not substitute for this check.

Further candidates still need review. The audit produces **review candidates**,
not uninstall instructions.

For each batch:

1. Check program paths, dependencies, running consumers and known project/script
   references without reading credentials or environment files.
2. Establish a program-code rollback and test the mise equivalent.
3. Obtain approval for the exact uninstall batch; previous prohibitions on legacy
   NVM/Conda/PostgreSQL removal remain in force.
4. Remove only the redundant package, never application/auth data. No blanket
   autoremove, cleanup, forced dependency bypass, service restart or database
   migration.
5. Re-run ownership, functionality and native linkage checks before continuing.

After these removals, Brew Node and Python 3.13 have no recorded Brew consumers;
that alone is not proof they are unused outside Homebrew. Brew Python 3.14 and
Java still have installed consumers. A bounded metadata-only project scan on
20 October additionally found **14 virtual environments using Brew Python 3.14**
and **11 using a separate Python.org 3.13 installation**. Project names/paths
stay in the private local audit, not this repository. Base interpreters must be
retained until dependent projects are rebuilt and tested against mise runtimes.

Homebrew's `tree-sitter` formula provides the C library and headers, not the
CLI supplied by mise. Only `tree-sitter-cli` was a duplicate command provider;
the audit now reports the native library separately. Do not assume the mise CLI
can replace applications or build configurations linking that library.

NVM, Conda, old Rust/Cargo/pipx locations, PostgreSQL 14, and optional GUI apps
need explicit keep/migrate/retire decisions. Directory presence does not prove
obsolescence. Exclusion from clean-machine bootstrap does not mean an installed
application should be deleted or ignored for security maintenance.

## 4. Make upgrades boring

- Add each new workstation CLI to the appropriate mise layer instead of running
  an ad hoc global installer. Keep project-only dependencies in projects.
- Preview updates, review supported runtime families and upstream compatibility,
  then change pins and lock together. Do not silently add another global config
  beside the established layered source of truth.
- Judge release-age eligibility by the relevant upstream artifact/code change;
  a recent bottle rebuild is not by itself a reason to hold an old release.
- Reinstall/rebuild dependent environments where required; run command ownership,
  bootstrap contracts and relevant functional tests after changes.
- Keep only genuine compatibility, age-policy or explicit-exclusion holds. An
  unfinished review is outstanding work, not an accepted permanent hold.

## Verification boundary and remaining work

The read-only audit itself never uninstalls anything. The approved CLI batches
and helper migrations above were applied separately; full workstation
consolidation is not yet complete. NVM, Conda, databases, GUI apps and personal
configuration remain untouched. Old runtime installations require project and
consumer review, not a blanket prune. Distinguish obsolete CLI providers from
native libraries, project-dependent interpreters and retained mise versions.
The only legacy pipx application found was SuperClaude 4.1.9. On 23 October,
after explicit approval, its installer and both pipx command links were removed
with a program-source backup; Claude settings and installed framework
configuration were not accessed or changed. pipx now reports no installed
applications; the pipx manager and its Python were not removed. NVM still
contains old AI CLI/plugin copies and optional tools that need explicit
keep/migrate/retire decisions before changing protected managers.

The [23 October security follow-up](security-review-2026-10-23.md) supersedes any
inference that successful functional smokes establish current security. It
records newly disclosed and older outstanding issues separately from the
consolidation work; security updates and new release-age exceptions require
their own approval.

Mise 2026.10.15's empty-HOME **tool installer dry-run** incorrectly requires real
PyPI prerequisites. The isolated bootstrap tests therefore preview non-tool
phases using the real dry-run and tool selection using the real metadata API;
they explicitly report the excluded installer phase. They copy graph sidecars
and preserve all trust/no-write checks. This is not certification of a complete
fresh-Mac bootstrap. Actual isolated locked graph installs and SDK/browser
execution were tested separately; no pretend installed dependencies were used.
