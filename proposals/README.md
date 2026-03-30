# Proposals

Technical proposals and RFCs for changes to the ClaraCard iOS platform.

Use this folder for ideas that need discussion before implementation  architecture changes, new tooling, process improvements. A proposal doesn't mean the work is approved or scheduled, just that it's been written up for the team to review.

## How to add a proposal

Create a new file named `YYYY-MM-DD-short-title.md` and describe the problem, the proposed solution, alternatives considered, and open questions.

Each proposal must include a `status` field. Valid statuses:

| Status | Meaning |
|---|---|
| `draft` | Being defined, not ready for generation. Claude CLI will refuse to generate and warn the author. |
| `review` | Ready for a teammate to look at. Still not generatable. |
| `approved` | Sign-off given. Claude CLI is allowed to generate from this proposal. |
| `implemented` | Code has been generated and merged. The JSON config is now the source of truth for that module or screen. |
| `deprecated` | The module or screen is being phased out. |
