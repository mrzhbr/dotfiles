# Pi Harness boundary

Pi Harness is a separate repository and owns Pi packages, extensions, skills,
settings templates and sandbox integration. Mise owns the host `pi` executable.
Do not embed runtime payloads, agent state or a Harness checkout in this repo.

The checkout helper can clone a missing repository, but never updates, resets,
stashes or cleans an existing checkout. This preserves intentional development
work and makes source updates an explicit decision.

Use Harness ownership opt-outs when the baseline owns Pi/helpers or a private
layer owns model configuration. A full Harness install may replace settings,
models and extension/skill trees; it is not a safe shortcut for deploying a
small asset change. Keep private configuration authoritative for its own files
and leave authentication with the application login store.

Do not bypass browser/sandbox quarantine or accept an unavailable source pin as
remotely reproducible. Review the external repository's current installation
contract and verify the intended source revision before applying it.
