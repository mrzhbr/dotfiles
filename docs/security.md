# Public repository security boundaries

This repository contains reusable configuration, not credentials or a live
workstation inventory. Keep the following out of Git, including private Git:

- API keys, passwords, tokens, private keys and authentication stores
- Shell environment files, sessions, histories and generated agent artifacts
- Browser profiles, application databases, model state and personal notebooks

Keep real host mappings, identities, personal Rex targets and machine-specific
operational notes in the private layer or appropriate local stores. A private
repository is not a substitute for Keychain or application authentication.

## Publication checks

Run `scripts/check-safety.sh` and `scripts/validate.sh` before committing.
The safety checker rejects protected filenames before reading their contents
and exports the reviewed source set to Gitleaks with redacted output. Built-in
checks cover account identifiers, tailnet addresses and tracked generated
artifacts. Do not hide source behind arbitrary ignore rules to evade them.

Keep any additional machine-specific identifier denylist **private**, not
hard-coded into a public validator. The checker accepts one identifier per line
(case-insensitive substring matching; blank/comment lines ignored):

```bash
./scripts/check-safety.sh --denylist /path/to/private/public-identifiers.txt
```

A configured denylist must be a nonempty regular, non-symlink file; diagnostics
report offending source paths, not identifier values. Store only non-secret
identifiers there, never credentials. The private overlay's validator checks
the adjacent public checkout with its own denylist.

These checks do not prove every commit in repository history is free of
sensitive material. Review staged paths and diffs, confirm the destination's
visibility, and avoid blanket staging of unrelated changes.

## Disabled functionality

Browser automation is deliberately quarantined. Its normal package entrypoints
refuse use until a supported dependency graph has been reviewed. Do not force
dependency overrides, use legacy fallbacks or delete guards merely to make a
check succeed. Runtime ownership is not a claim that every declared command is
enabled or security-cleared.

## Configuration trust

Review setup scripts, package pins, dependency sidecars and skills before
trusting configuration or applying dotfiles. Keep approval for service starts,
application resets, database work and legacy removal separate from validation.
An agent command guard is not an unconditional sandbox.

## If sensitive material was published

Stop further disclosure and assess what was exposed. Rotate/revoke actual
credentials first where necessary, then coordinate any history cleanup with
collaborators. Removing a file in a later commit does not erase earlier copies,
forks or caches. Routine documentation cleanup does not rewrite history.

Detailed workstation audits, software inventories and remediation status are
maintained privately rather than published alongside this baseline.
