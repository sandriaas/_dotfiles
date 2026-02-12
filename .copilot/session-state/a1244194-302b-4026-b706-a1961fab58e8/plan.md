# Plan

## Goal
Update installer scripts to add GitHub CLI repo installs (dnf + apt), install Bun, and ensure Copilot CLI install is reliable, then refresh README.

## Workplan
- [ ] Review existing install steps for package manager handling and CLI installs
- [ ] Implement GitHub CLI repo install for dnf and apt (with config-manager on dnf)
- [ ] Add Bun install step
- [ ] Make Copilot CLI install verifiable (npm prerelease) with clear warning if missing
- [ ] Update README installed tools list
- [ ] Sanity-check changes (no destructive commands run)

## Notes
- Avoid running install.sh since it changes the system.
- Keep apt update behavior consistent with existing script.
