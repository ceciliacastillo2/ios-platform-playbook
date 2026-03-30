# Continuous Integration

---

## Why This Project

Release automation is the right first investment for a four-person team that wants to grow — not because it is the most technically complex problem, but because it is the one that pays off immediately, visibly, and without requiring the rest of the codebase to change first.

### The Problem Today

Releasing the app is a manual, high-stakes event. It requires a specific engineer to be available, to follow a sequence of steps from memory, and to catch any mistakes before they reach users or the App Store. Every release carries the same risk and requires the same effort regardless of how small the change is.

For a team of four, this means:
- Releases are tied to individuals — if that person is unavailable, the release waits
- The process is not written down in a way that anyone can follow without guidance
- There is no automated check that the build is healthy before it goes out
- Adding a new test device or rotating a certificate requires manual coordination

### The Goal

Make releasing the app a non-event. Any team member should be able to trigger a build and ship to TestFlight with a single command — with confidence that the output is correct, consistent, and does not depend on their local environment.

### Impact

| Before | After |
|---|---|
| Releases depend on one person | Any team member can ship |
| Manual steps from memory | Scripted, version-controlled lanes |
| No visibility into what was built or when | Full build history and logs |
| Adding a test device requires manual profile work | Handled automatically |
| New engineer needs weeks to understand the release | Documented, runnable from day one |

### What It Unlocks

Release automation is not just about saving time on releases. It is the foundation everything else depends on:

- **Unit tests become useful** — a test suite only protects you if it runs automatically on every change. Without CI, tests are optional. With CI, a failing test blocks a broken build from shipping.
- **Snapshot tests become enforceable** — visual regressions are caught in the pipeline, not spotted by a user after the release.
- **Code review gets faster** — reviewers stop worrying about "does this build?" and focus on what the code actually does.
- **Growth becomes safer** — when the team doubles, the release process does not double in complexity. It stays a button.
- **Confidence compounds** — every engineer knows that if their change passes the pipeline, it is safe to ship. That confidence is what lets a small team move fast without breaking things.

### Why Now

This is the lowest-risk, highest-visibility improvement available. It does not require changing the architecture, adopting new patterns, or touching feature code. It builds on what the team already does — it just removes the manual steps and makes it repeatable.

With four engineers, the cost of building this is low. With eight engineers across two time zones, the cost of not having it becomes a daily tax on every release.

---

## Current Status

**Manual.** The team currently owns the full build, test, and release process hands-on. This gives us direct control and deep familiarity with every step — and it's the right starting point from which to build a thoughtful, well-understood automation strategy.

## Goal

Progressively automate the build and release process from local developer workflows through fully managed cloud CI so that shipping a build is repeatable, auditable, and fast, and the team can focus more energy on building great features.

---

## Phases

### Phase 1  Fastlane Local Automation (Beta Simulator Build)

**What:** Automate the beta simulator build locally using Fastlane. This phase targets the non-production, simulator build only not the App Store release.

**Goal:**
Define and script the build pipeline as Fastlane lanes so any developer can trigger a consistent, reproducible beta simulator build from their machine with a single command.

**Business Value:**
- Gives every developer a shared, version-controlled definition of what a build is
- Makes onboarding smoother — a new team member can get a build running without tribal knowledge
- Lays the foundation all later phases build on, making each subsequent phase a natural extension

**Success Criteria:**
- A Fastlane lane exists for the beta simulator build and is documented
- Any team member can run the lane from a clean checkout and produce a successful build
- The lane is checked into version control and passes a smoke run in a peer review

---

### Phase 2  AI-Assisted Release Creation (Beta + Production Build)

**What:** Use Claude to orchestrate the release process — triggering Fastlane lanes, generating the production build, and handling the steps that today require manual coordination.

**Goal:**
Complement the team's release expertise with a Claude workflow that can create a beta distribution and kick off the production build, making the release process more approachable and consistent for everyone.

Claude is usable in two ways:
- **Via command** — a defined Claude Code command that runs the release lanes with a single invocation, producing a consistent outcome regardless of who triggers it
- **Via conversation** — an engineer describes what they want in natural language ("create a beta build from the release branch") and Claude interprets the intent, confirms before acting, and runs the appropriate lanes

Both paths produce the same outcome. The command is for routine releases; the conversational path is for edge cases or engineers less familiar with the release process.

**Business Value:**
- Makes release creation faster and more accessible across the team
- Channels engineers' focus toward higher-value decisions rather than procedural steps
- Demonstrates a practical, low-infrastructure path to automation before investing in external CI tooling

**Success Criteria:**
- A Claude Code command exists that triggers the release lanes end-to-end
- The same outcome is achievable via a conversational Claude session without memorising lane names or flags
- Both the beta distribution build and the production build can be triggered through either path
- The process is documented well enough that a new team member can execute it without help

---

### Phase 3 — Cloud CI

**What:** Move the automated pipeline off developer machines and into a cloud CI platform, triggered automatically and producing an auditable log for every run.

**Goal:**
Run builds and releases on dedicated cloud infrastructure so the process is no longer tied to any individual's machine. The specific platform has not been selected — options including Bitrise, GitHub Actions, and other tools need to be evaluated against the team's build volume, cost, and code signing requirements before a decision is made.

**Code Signing**
Code signing is an open problem and is in scope for this phase. Today, adding a new test device is a manual process — someone has to update the provisioning profile, download it, and redistribute it to the team. This is error-prone as the team grows. A cloud CI solution must address how signing is managed, how test devices are added without manual intervention, and how certificates are stored and rotated securely. This evaluation is part of the platform selection decision.

**Business Value:**
- Decouples the release process from any individual's laptop — builds run even when the team is heads-down or out of office
- Solving code signing in the cloud removes a recurring manual bottleneck for adding test devices
- Creates a consistent build environment that every team member can trust equally
- Enables parallel testing and faster feedback loops across the team

**Success Criteria:**
- A cloud CI platform has been selected based on a documented evaluation of options
- The Fastlane lanes from Phase 1 run on the cloud platform without modification
- Builds trigger automatically on the agreed branching event
- Adding a new test device does not require manual provisioning profile management
- Build history, logs, and artifacts are accessible to the full team
- The release owner can monitor and re-trigger builds without a local environment

---

### Phase 4 Explore Next Steps

**What:** With a solid pipeline in place, step back and identify where the team wants to grow the automation investment next.

**Goal:**
Take stock of the full delivery lifecycle including test coverage gates, App Store submission automation, rollout strategies, and observability of the pipeline itself and decide where to invest next.

**Business Value:**
- Keeps the CI investment growing in value over time as the team and product scale
- Creates a shared picture of where the team stands and what great looks like for mobile CI/CD
- Brings the whole team into shaping the roadmap, surfacing ideas like automated regression runs, staged rollouts, or release notes generation

**Success Criteria:**
- A written assessment exists of what is and isn't automated after Phase 3
- The team has aligned on a ranked list of next opportunities (e.g., automated App Store submission, test gates, rollback tooling)
- At least one next initiative has been scoped and added to the backlog
