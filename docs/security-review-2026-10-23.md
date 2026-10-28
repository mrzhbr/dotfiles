# Workstation security follow-up — 23 October 2026

## Status and scope

**Action is needed. The previous functional checks were not security clearance.**
This review compares installed metadata with vendor advisories, fresh npm audits
and OSV package-version queries. It emphasizes 21–23 October disclosures while
also identifying older serious fixes missing from retained installations.
No exploitation was attempted and no compromise is established.

### Initial review boundary (before remediation)

The findings and installed-version tables below retain the initial review
snapshot; they are not a statement that the superseded versions remain selected.
The applied-status section records subsequent approved changes.

Only the explicitly approved **SuperClaude 4.1.9 pipx installer** was removed,
including its two command links, with a Python/Markdown program-source backup.
Claude settings and installed framework configuration were not accessed or
changed. The pipx manager, project interpreters and other managers remain.
**No security upgrades, selector/lock changes, service restarts, database work,
app updates, commits or pushes were performed during that initial advisory pass.**

The general seven-day policy remains. At initial review the prior Pi/Claude
exceptions did not authorize the additional versions; subsequent explicit
security approval is recorded below. Dates in version names are not necessarily
artifact publication dates. Check vendor artifacts/provenance rather than
postponing risk assessment merely because a fix is new.

## Applied status (23 October)

- **Selected core CLI updates installed:** Node **24.22.1**, main Python
  **3.14.9**, private Python **3.13.17**, uv **0.13.5**, Bun **1.4.4**, Temurin
  **25.0.5+8** (mise `temurin-25.0.5+8.0.LTS`), AWS CLI **2.38.4**, Claude Code
  **2.1.309** and Codex **0.164.0**. These are newly approved security exceptions;
  the general **`7d`** policy remains. **Rust 1.99.1** is also installed/selected;
  isolated offline compile/run, Clippy, rustfmt and rust-analyzer checks pass.
  Rustup's normal installation self-updated **1.29.1 → 1.29.2**.
- Main Python **pip 26.2.2 / certifi 2026.10.19** were repaired offline from
  attested wheels. All **113 requirements** are now fully hash-locked, setup
  requires hashes and binary wheels, and the functional Unix-IPC notebook check
  passes. This does not repair every retained/project interpreter or trust store.
- **Chrome 156.0.8078.48 installed** from Google's signed/notarized DMG;
  no personal browser profile was opened. Deep-strict validation reported
  vendor-DMG FinderInfo detritus; deep signature, notarization and Gatekeeper
  checks passed. No xattr/signature-security bypass was applied.
- **Targeted native rollout finished: 23 formula installations/upgrades**,
  including **ca-certificates 2026-10-20**, **certifi 2026.10.19**, **NSPR 4.40**,
  **NSS 3.132**, **Brotli 1.2.1**, **c-ares 1.34.9**, **GnuTLS 3.8.13_2**,
  **GnuPG 2.5.24_1**, **Unbound 1.26.2**, **PostgreSQL 14.24_1 / 18.6_1**
  and **Homebrew Python 3.13.17 / 3.14.9**, with required dependency closures.
  Homebrew/core artifact attestations remained enforced. GnuPG agent-kill and
  server postinstall hooks were skipped; no personal keys, database connections/data,
  initdb, migration, index work or service starts/restarts were involved.
- Active **openssl@3 is 3.5.9 LTS**, following a 3070-Mach-O/83-direct-consumer
  symbol/import gate. Separate **3.6.5** and **4.0.3** branches are installed;
  the branch change was not a blind major upgrade. Retained old OpenSSL kegs
  are inactive rollback code, not patched or supported for direct invocation
  with the active LTS libraries. Whole-cellar linkage and bounded synthetic
  native crypto/decoder/Python/binary checks pass; this is not every project's
  ABI/functional certification.
- Browser-use **0.13.11**, the latest upstream release observed, still exact-pins
  a vulnerable graph. Its new Python does not remove those dependencies. The
  postinstall hook now applies fail-closed namespace quarantine to **browser_use**
  and **browser_harness**: normal CLI and SDK imports are blocked, original
  program source is retained, and profiles/settings are untouched. No forced
  dependency override or `--no-deps` workaround was used. Re-enable only after a
  supported corrected graph is reviewed.
- **Docker Desktop 4.96.3/build244472 installed by the user**, then started after
  deep-strict signature and notarization checks passed for Docker Team9BNSXJN65R.
  Client and engine both report **29.9.2**, with zero existing running workloads
  at verification. The old app and pre-start raw-disk APFS clone remain retained.
  The prior administrator installation blocker is resolved; no factory reset,
  deletion/pruning or manual database migration was used.
- The **OS download attempt timed out**; no OS installation or reboot occurred.
  **Safari is unchanged.** Stay on Tahoe 26; OS/Safari still need legitimate
  interactive administrator completion, not a macOS27 migration or forced reboot.
- The sandbox source now pins a **Cosign-verified Chainguard index**, with signed
  arm64/amd64 SPDX attestations identifying **Node26.12.1-r2**. Source CA distrust
  is enforced before networking and after APK changes. A **new local image was
  built and tested**: Node26.12.1, Brotli1.2.1, Pi1.3.0, Python3.14.9, kernel
  CPU/memory/PID limits, read-only project mounts and actual UID/capability/
  no-new-privileges checks pass. Podman was not installed and was explicitly skipped.
  Build inputs are allowlisted, npm lifecycle hooks disabled, and no personal
  agent state or credentials were mounted into tests. Pi's117 dependency registry
  signatures passed;33 had verified attestations. Materialized npm metadata queries
  returned zero known findings, but the **84-APK native audit matched10 package
  categories** with vendor pending/detection records requiring applicability/fix
  triage. Consequently **SECURITY_HOLD remains**, as do publication/Harness pin
  gates. Functional success is not image vulnerability clearance. See the
  sandbox's `docs/security-base-2026-10-23.md` receipt.
- **Pi was restarted and its actual Node24.22.1 mapping verified.** Three other
  processes previously used Node24.19.0; they were not killed and have not been
  rechecked. Changing selection does not patch running code or explicit old paths. Project interpreters,
  retained EOL installations and independent trust stores also remain exposure.
  This is not workstation-wide security clearance.

## 1. Urgent: runtimes and certificate trust

The eMudhra/emSign intermediate-CA compromise affects clients using vulnerable
trust bundles, not just connections to websites normally using that CA. An
on-path attacker holding a compromised key can impersonate other TLS endpoints.
Updating one system CA package does **not** repair every embedded/bundled store.

| Verified installed/selected component | Verified fix target | Finding / boundary |
| --- | --- | --- |
| Node **24.21.0** | **24.22.1**, security release 21 October | High-severity Brotli decoder RCE (CVE-2026-111497), DNS validation and TLS hostname bypass fixes; also updated CA trust, OpenSSL, c-ares and Undici. Stay on Node 24 LTS. |
| Main Python **certifi 2026.7.22** | **2026.10.19**, artifact uploaded 20 October | Critical GHSA-6q48-6c7w-9gw2, CVSS 4.0 9.1. The notebook requirements explicitly pin the old version; change the pin as well as the installation. |
| Main Python **pip 26.2.1**; CPython **3.14.8** / private **3.13.16** | pip **26.2.2**; Python **3.14.9 / 3.13.17**, expedited 21 October releases | New Python releases repair bundled pip/certifi. Existing environments need separate remediation. This does not mean CPython's `ssl` universally uses certifi. Main Python's actual OpenSSL is already **3.5.9**. |
| uv **0.13.0** | minimum **0.13.4** (20 October); review **0.13.5** for updated managed-Python builds | High GHSA-hq85-5cpj-mr62: bundled CA trust. Existing Python installations are not retroactively repaired by updating uv. |
| Bun **1.4.3** | **1.4.4**, 22 October | High GHSA-26q8-h657-pf84. Adding system CAs does **not** remove vulnerable bundled trust. Compiled Bun executables need rebuilding separately. |
| AWS CLI **2.37.13** | **2.38.4**, tag commit 21 October | Vendor changelog removes cross-signing `AAA Certificate Services` trust for the CA incident. Its own botocore CA bundle is separate from system certifi. Verify artifact publication and tests before selecting. |
| Temurin runtime **25.0.4.1+1-LTS** (mise identifier `temurin-25.0.4+101.0.LTS`) | Temurin **25.0.5+8**, release 22 October | Actual product release metadata resolves the misleading-looking mise identifier. October Java CPU includes affected 25.0.4.1; application/API exposure varies. |

**Sources:** [Node security advisory](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases),
[Node 24.22.1](https://nodejs.org/en/blog/release/v24.22.1),
[certifi reviewed advisory](https://github.com/advisories/GHSA-6q48-6c7w-9gw2),
[Python release announcement](https://blog.python.org/2026/10/python-3151-3149-31317/),
[uv advisory](https://github.com/astral-sh/uv/security/advisories/GHSA-hq85-5cpj-mr62),
[Bun advisory](https://github.com/oven-sh/bun/security/advisories/GHSA-26q8-h657-pf84),
[AWS changelog](https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst),
[AWS CA change](https://github.com/aws/aws-cli/pull/10786),
[Oracle CPU](https://www.oracle.com/security-alerts/cpuoct2026.html#AppendixJAVA),
[Temurin release](https://github.com/adoptium/temurin25-binaries/releases/tag/jdk-25.0.5%2B8).

### Independent Node installations

The old cached sandbox image and commit37eafe1 contain **Node26.1.0**.
The new uncommitted source base is vendor-signature/SBOM verified for
**Node26.12.1-r2**; a new local image passes Docker runtime tests. Its native
package audit still needs applicability/fix triage, so the live launch hold remains.
Do not publish the old SHA or accept the pending Harness pin as remediated.

Homebrew Node **25.9.0** and NVM Node **23.3.0** are also installed and executable;
both are EOL. Old mise Node versions remain. Do not claim them patched when the
selected Node 24 changes, or silently delete protected installations. Identify
and migrate actual consumers, then retire obsolete providers with approval.
There were no running containers when checked; cached project images were not
fully scanned and are not cleared for untrusted workloads.

## 2. Browser helper: latest top-level version still pins vulnerable dependencies

The installed **browser-use 0.13.11** is also the current PyPI release observed
in this review. Its published requirements **exactly pin** these old versions:

| Installed dependency | Verified fixed boundary | Relevant issue |
| --- | --- | --- |
| AnyIO **4.12.1** | **4.14.2** | Critical TLS hostname/IDNA spoofing, CVE-2026-63374 / GHSA-82r6-8w77-94w6. |
| Pillow **12.3.0** | **13.0.0** | Many image-decoding advisories, including vendor-reported heap corruption/RCE. FPX JPEG issue requires optional `olefile`; no proof of that particular prerequisite or macOS exploitation is claimed. |
| aiohttp **3.14.3** | **3.14.4** | Multiple resource-exhaustion, timeout and protocol issues; server-only findings are conditional on server use. |
| pypdf **6.16.2** | At least **6.21.1** for the matched set; re-audit current **6.21.2** | Multiple crafted-PDF CPU/memory/infinite-loop issues, including 21 October disclosures. |
| MCP SDK **2.1.1** | **2.2.0** | Moderate StreamableHTTP session-exhaustion advisory, CVE-2026-59951; relevant server/transport must be used. |

The helper also contains **certifi 2026.7.22**. Main notebook Python instead has
**Pillow 13.0.0**, **AnyIO 4.15.1**, **JupyterLab 4.6.4** and **Notebook 7.6.3**;
do not conflate the two environments.

**Do not use `--no-deps`, force an inconsistent environment, or claim ordinary
`mise upgrade` fixes the helper.** Its upstream exact requirements need a
supported corrected release or an explicitly reviewed, reproducible alternative.
Until then, avoid using this helper with untrusted web/image/PDF input. A new
Python alone does not remove these dependency constraints. Pillow 13.0.0's
first upload was 16 October at 22:15 UTC: its seven-day eligibility is not reached
until that time on 23 October, despite the version/release labels.

**Sources:** [browser-use published metadata](https://pypi.org/pypi/browser-use/json),
[AnyIO vendor advisory](https://github.com/agronholm/anyio/security/advisories/GHSA-82r6-8w77-94w6),
[Pillow vendor advisory](https://github.com/python-pillow/Pillow/security/advisories/GHSA-5x8w-8jj5-q52h),
[aiohttp vendor advisory](https://github.com/aio-libs/aiohttp/security/advisories/GHSA-2g87-pp6c-29x5),
[MCP vendor advisory](https://github.com/modelcontextprotocol/python-sdk/security/advisories/GHSA-84m7-p3x7-pcfv),
[pypdf advisories](https://github.com/py-pdf/pypdf/security/advisories).

## 3. Desktop and AI tool updates

App-bundle metadata overrides stale Homebrew cask receipts for this comparison.

| Installed | Verified remediation target | Reason and approval boundary |
| --- | --- | --- |
| macOS **26.5.2 (25F84)** | Tahoe **26.7.1**, 28 September | CVE-2026-86950 arbitrary code execution plus earlier cumulative fixes. Apple reports exploitation on older **iOS**, not proof of exploitation on this Mac. Age-eligible; requires planned OS update/restart, not macOS 27 migration. |
| Safari **26.5.2** | Compatible **Safari 27**, 14 September | WebKit code execution and data-protection fixes. Use Apple's supported update path for this OS. |
| Chrome **155.0.8059.85** | Stable **156.0.8078.47/.48**, 20 October | Critical memory-safety security batch. Use the vendor-offered Mac architecture build; new early-update exception and browser relaunch planning required. |
| Docker Desktop **4.43.1**, Engine **28.3.0** | Review **4.96.3**, 22 October | Old package misses container-to-host CVE-2025-9074 (historical fix 4.44.3) and new CA remediation staged in 4.96.1–3. Needs explicit engine/data migration and restart approval; do not run untrusted containers pending remediation. |
| Claude Code **2.1.299** | **2.1.309**, 22 October | Release fixes macOS/Linux startup files outside sandbox, symlinked deny-write paths, MCP-config writes and permission matching. No exact per-defect affected range/CVE is supplied; classify missing security fixes, not tested exploits. New exception needed. |
| Codex **0.162.1** | **0.164.0**, 23 October | macOS case-alias protected-metadata write and other boundary hardening. 0.163.0 is age-eligible but lacks these newest fixes. New exception needed. |

VS Code's actual **1.142.0** notes warn Assisted Permissions does not enforce
`permissions.{allow,ask,deny}` and the Local-harness opt-out bypasses some managed
runtime policy. Whether those modes are enabled here was not inspected; no
fixed version was established. Do not treat agent policy as unconditional
containment. Selected Ghostty **1.3.1**, gh **2.102.0**, OpenCode **1.19.0** and mise
**2026.10.15** exceed the particular older advisory floors checked; that is not
comprehensive clearance. Pi 1.4.0 has no inherited exception or demonstrated
urgent upgrade requirement from its reviewed release notes.

**Sources:** [Apple Tahoe advisory](https://support.apple.com/en-us/149228),
[Safari 27 advisory](https://support.apple.com/en-us/149039),
[Chrome Stable announcement](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_02018666648.html),
[Docker security announcements](https://docs.docker.com/security/security-announcements/),
[Docker release notes](https://docs.docker.com/desktop/release-notes/),
[Claude 2.1.309](https://github.com/anthropics/claude-code/releases/tag/v2.1.309),
[Codex 0.164.0](https://github.com/openai/codex/releases/tag/rust-v0.164.0),
[VS Code 1.142](https://code.visualstudio.com/updates/v1_142).

## 4. Older native/runtime debt is not a demonstrated compatibility exemption

- Installed Homebrew OpenSSL **3.6.2** misses the September security update
  **3.6.5** (including High DTLS stale-buffer CVE-2026-84782). Exploitability
  depends on application API/protocol use. The formula named `openssl@3` now
  describes **3.5.9 LTS**, whereas installed code is 3.6: do not blindly change
  branches or jump to OpenSSL 4 through a blanket Brew upgrade.
- Installed native Brotli **1.2.0** needs **1.2.1** for CVE-2026-111497; updating
  Node's embedded copy does not update the dylib or statically linked programs.
  Native c-ares **1.34.6** needs **1.34.9** for memory-safety fixes, including
  application-callback cancellation paths; this does not affect every caller.
- Installed Unbound **1.23.1** predates Critical DNSSEC heap-overflow/possible-RCE
  CVE-2026-81642 (fixed **1.26.1**, September) and October DoQ fixes in **1.26.2**.
  Installed library presence is not proof of an exposed resolver or enabled DoQ.
- PostgreSQL **14.19 / 18.4** predate **14.24 / 18.6** and multiple August
  security fixes, including authenticated-query RCE CVE-2026-14664 (8.8).
  Plan separate backups, relevant post-update/index work and downtime; no database
  connection, migration, extension change, restart or major upgrade was attempted.
- GnuPG **2.4.8** predates armor-parser memory-corruption fix **2.4.9**
  (CVE-2025-68973). That is a historical minimum on an EOL branch, not a supported
  endpoint. The verified maintained target **2.5.24** is age-eligible; review
  dependency/agent effects without reading keys or restarting agents.
- GnuTLS **3.8.10** predates **3.8.13**, which fixes high-impact DTLS overruns and
  RSA-PSK authentication bypasses. Actual protocol/server use was not established.
- Homebrew CA bundle **2026-05-14**, separate Brew certifi **2026.2.25**, and NSS
  **3.114** predate October distrust updates (curl bundle **2026-10-20**, certifi
  **2026.10.19**, NSS **3.131.1**). NSS also requires a newer NSPR. Cached formula
  candidates may predate the fixes. Check supported package availability and
  actual trust consumers; updating main Python certifi alone is insufficient.
- Selected Rust **1.93.1** includes Cargo fixes absent until **1.96.0** for
  CVE-2026-5223/5222; third-party registry/input prerequisites apply. Prefer a
  reviewed current supported toolchain, not that historical minimum. Compiled
  applications' embedded trust crates require their own updates/rebuilds.
- Project-dependent Brew Python **3.14.3_1 / 3.13.12_1** lag September security
  fixes. Retain until safely updated/migrated; a new global mise interpreter does
  not repair those environments. Possible package backports remain unverified.

**Sources:** [OpenSSL September advisory](https://openssl-library.org/news/secadv/20260929.txt),
[Brotli 1.2.1](https://github.com/google/brotli/releases/tag/v1.2.1),
[c-ares advisory](https://github.com/c-ares/c-ares/security/advisories/GHSA-wpr3-8q3r-4q8c),
[Unbound advisories](https://nlnetlabs.nl/projects/unbound/security-advisories/),
[PostgreSQL CVE-2026-14664](https://www.postgresql.org/support/security/CVE-2026-14664/),
[GnuPG fix](https://dev.gnupg.org/T8001),
[GnuTLS advisories](https://gnutls.org/security-new.html),
[curl CA bundle](https://curl.se/docs/caextract.html),
[NSS release](https://firefox-source-docs.mozilla.org/security/nss/releases/nss_3_131_1.html),
[Cargo advisory](https://blog.rust-lang.org/2026/05/25/cve-2026-5223/).

## Coverage, evidence and safe next action

Fresh npm audits of the Harness root lock, payload lock and live payload report
**zero known findings**. OSV queries of the selected Pi and ctx7 locked graphs
(**118 / 56 packages**) also returned none. These results do **not** cover the
Node executable, CA trust, native components or every extension behavior.

Initial OSV queries covered **113** main-Python and **107** helper distributions,
matching certifi in the former and six packages in the latter. The post-rollout
re-query reports **zero matched main-Python packages**, while the quarantined
helper still has **six matched packages** across its107 distributions. Metadata
was inspected without importing helper code. Advisory aliases/counts are not
independent vulnerability totals; database results do not establish absence of
malware or unknown flaws. No arbitrary dependency overrides were applied.

The LiteLLM **1.107.0** supply-chain incident was checked separately. No LiteLLM
metadata was found in the **32 previously inventoried project environments**;
none were missing on recheck. No `cook.pth`/`cook.py` filename indicator was
found in their site-packages plus the main/helper environments. The cached
LiteLLM container image dates from March and does not match the published bad
October digest; its associated container was stopped months ago. This is no
observed exposure in the checked locations, **not forensic proof of no prior
compromise**, and does not audit remote hosts. Do not execute suspect Python
just to inspect it. [Vendor incident report](https://docs.litellm.ai/blog/security-incident-oct-21-2026).

Detailed version snapshots, database responses and research are retained in the
private local backup checkpoint, not committed here. Project names/paths,
profiles, auth stores, secrets and personal notebooks were not published.

The initial next-action recommendation was to request narrowly scoped early
security-update approval. That approval and the applied subset are now recorded
above; unfinished work is not implicitly complete. Continue to serialize
pin/graph/live changes, verify artifact provenance, rerun ownership and realistic
functional checks, and restart consumers only with permission. Separately
complete OS/Safari maintenance, resolve sandbox native advisory triage and
separately plan any required database work.
A corrected browser-helper dependency plan is still blocked by upstream exact
pins. No blanket upgrade, `audit fix`, forced peer/dependency bypass or pruning.

Coverage gaps remain: all private project dependencies, every cached image,
remote machines, minor-app advisories and every native-library/compiled-tool
trust dependency. Zig's reported HTTP issue lacks verified vendor fix mapping.
The native research lane reached its time limit; its sourced report was then
recovered without further package/source changes. This is still not a completed
all-formula audit. No
claim is made that the workstation is fully current, clean or security-certified.
