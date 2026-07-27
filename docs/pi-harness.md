# Pi Harness integration

The canonical Pi Harness remains a separate repository and owns Pi packages,
extensions, skills, settings templates, and sandbox integration. mise owns the
host `pi` executable. A custom idempotent task clones a missing checkout but
never updates, resets, stashes, or cleans an existing checkout; this avoids
mise's repository convergence refusing intentionally dirty development trees.

Integration is currently status-only. The harness now supports opting out of
host Pi installation, global helper tools, shell mutation, model replacement,
and sandbox setup. Its public model template no longer contains a
machine-private endpoint. The eventual mise-owned invocation will use all of
these controls and leave the private overlay authoritative for `models.json`.

Never embed or snapshot Pi Harness inside this repository.
