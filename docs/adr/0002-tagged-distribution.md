# ADR 0002 · Distribute one verified ZIP per release tag

## Decision

GitHub Actions builds one installable artifact and uses it for both GitHub Releases and the CurseForge upload API. Stable version tags identify releases. The matching section in CHANGELOG.md supplies player-facing release notes. The release job compares the downloaded build artifact with the digest recorded by GitHub before sending it to CurseForge.

## Tradeoffs

Using the upload API avoids maintaining a second packaging configuration and keeps the existing CurseForge project, gallery and settings. The account upload token lives in an encrypted repository secret. The manual connection check reads the game-version catalog without submitting a file.

The upload API returns a file ID after accepting a ZIP. A per-tag concurrency group and a pending marker in the GitHub asset label protect retries when a response is lost. This introduces a manual reconciliation step after an ambiguous failure. A successful upload records the ID in the same label. The [publishing guide](../development.md#publishing) describes recovery.
