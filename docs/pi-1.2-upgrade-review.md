# Pi 1.2+ compatibility review — 20 October 2026

Current selected CLI: **1.3.0**, verified with `mise exec -- pi --version`.
The initial audit below was performed on 1.1.0. After approval, the compatibility
patches were applied and mise advanced to 1.3.0 on 20 October, an explicitly
approved exception to the seven-day release-age policy. The general policy
remains unchanged. See the completed migration below.

## Documented breaking changes

[Official changelog](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md):

### 1.2.0

- `before_agent_start` also fires for idle custom-message-triggered runs.
  `messageType: "user"` events contain `prompt`/`images`; `"custom"` events
  contain `message` and **no `prompt`**. Prompt-only handlers need a type guard;
  system-prompt injection intended for all runs needs explicit custom handling.
- Sessions count as busy during startup handlers. `ctx.isIdle()` is false,
  `sendMessage()` queues into the starting run, and `sendUserMessage()` needs
  `deliverAs`. Review continuation/scheduling logic, not just TypeScript types.
- Themes receive strict startup validation. Update the schema URL to
  `https://pi.dev/schemas/theme.schema.json`, put reusable colors in `vars`,
  and remove unsupported metadata.
- `pi mcp list --json` replaces resource counts with `resources: true`; resource
  templates are no longer counted. Scripts consuming the old shape must change.
- Removed experimental source-only server/client/plugin exports were never
  part of the published package; ordinary CLI installations are unaffected.

### 1.3.0

No separate Breaking Changes heading, but `kimi-coding` changes protocol to
OpenAI Chat Completions. Custom base URL overrides must now include `/v1`.
The default NVIDIA model also changes. Private model/auth configuration was not
read, so applicability of provider-specific changes remains unverified.

1.3 pins internal Pi dependencies to exact versions, fixing mixed-version fresh
installs. Both 1.2 and 1.3 retain the 1.2 event changes. Unreleased changes on
`main` are not attributed to these published versions.

## Initial findings in installed extensions (before compatibility patches)

Paths below are relative to the agent's npm `node_modules` directory.

| Installed package | Evidence | Impact |
| --- | --- | --- |
| `pi-continuous-learning` 0.14.4 | `src/index.ts:103` has no custom-event guard; `src/instinct-injector.ts:152` passes `event.prompt` to `inferDomains`, whose `src/instinct-loader.ts:31` calls `.toLowerCase()` | Confirmed absent-prompt failure. Calling the installed compiled `inferDomains(undefined)` throws `TypeError`; custom-triggered runs can lose instinct injection. The observer also assumes a prompt. |
| `pi-codex-goal` 0.1.15 | `src/goal-runtime-input-context-handlers.ts:80` passes `event.prompt` to continuation parsing; `src/prompts.ts:26` calls `.startsWith()` | Another missing custom-event guard. Goal continuation and startup behavior need migration/testing. |
| `pi-subagents` 0.47.1 | `src/watchdog/runtime.ts:101` falls back from a missing prompt to the entire system prompt | No immediate missing-string crash in that helper, but custom-run intent/scope handling needs review. Child system-prompt rewriting uses `systemPrompt`, not `prompt`. |
| `pi-studio` 0.9.43 | Both bundled themes validate against the tagged Pi 1.3 schema | No demonstrated structural theme blocker. Their editor schema references still use the old URL. |
| Local `temporal-awareness.ts` | Its handler only uses `event.systemPrompt` | No missing-prompt assumption found; this is not an end-to-end startup certification. |

Public registry checks: continuous-learning 0.14.4 is still latest, so a simple
package update does not fix that issue. Newer goal 0.6.1, subagents 0.79.2, and
Studio 0.10.5 exist, but their compatibility has not been certified here.
Extensions are Harness-owned, separate from the mise-owned Pi CLI.

## Original migration plan

1. Keep 1.1.0 while resolving the two concrete prompt assumptions.
2. Update/review Harness-owned extensions; continuous-learning needs a compatible
   patch, maintained replacement, or temporary opt-out, not a blind reinstall.
3. Test normal prompts, custom-triggered runs, goal continuation, subagents,
   cancellation during startup, and any MCP JSON consumers.
4. Then prefer 1.3.0 over 1.2.0 for its dependency pinning fix. The existing
   seven-day policy admits 1.3.0 on **22 October**; an earlier install would be
   an explicit policy exception.

## Completed migration

The Harness-owned `scripts/patch-pi-compat.mjs` now reapplies exact-version,
context-checked fixes after package installation. Package versions remain stable;
newer unrelated extension releases were not blindly adopted. The installer and
manifest pins were aligned with the already installed seven-package stack.

- Learning observer ignores custom/no-prompt events, while learning injection
  safely handles absent text. Both TypeScript source and loaded JavaScript were
  patched; existing instincts/facts are untouched.
- Goal tracking skips custom startup before continuation parsing.
- Subagent watchdog no longer treats a custom run's system prompt as user intent.
- Studio's two valid themes now reference the current schema URL.
- Eight changed payload files retain `.pre-pi-1.3` code backups; a second patch
  invocation changes zero files. Version or context mismatch fails preflight.
- Mise config and lock select Pi 1.3.0. Previous 1.1.0 remains installed.

Verification: Harness typecheck, nine unit tests, installer opt-out tests, and a
credential-free test against the actually selected Pi 1.3 SDK passed. The latter
loads all seven package payloads and five local extensions, checks key tool
registration, user/custom events, busy startup, queued followup delivery, and
startup cancellation with a faux provider. No extension load/runtime errors were
reported. This is not certification of active-goal completion, real child-agent
launches, provider login, images, or external MCP services. Some captured
extensions retain worker handles after shutdown; the one-shot probe exits only
after assertions and awaited shutdown handlers succeed.

The full Harness bootstrap was not run. Existing custom extensions, model/auth
settings, and learning state were not replaced. No secret values were read.
Restart Pi with `mise exec -- pi` to use the new host executable; `/reload` alone
does not replace the current process. Package reconciliation outside the Harness
installer can overwrite patches: reapply the patcher and retest after such work.
