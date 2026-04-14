# App-First Architecture Plan

## Core idea

Build this in a way where the **Flutter app is the first client of the system**, not a temporary prototype that gets thrown away later.

The remote agent / messaging interface, if it happens, should be added at the end as another thin entry point over the same core logic.

That gives the project two chances to succeed:
- minimum success: local app works
- stretch success: remote agent layer also works

---

## Architecture principle

Do not build “an agent platform.”
Build a small product with clean seams.

Recommended layers:

## 1. Domain layer
Pure app logic, no UI assumptions.

Responsibilities:
- take raw input
- call model/provider
- parse into proposed medication schedule
- validate/normalize the proposal
- expose confirm/edit/cancel actions
- save confirmed results
- generate reminder intents

This is the layer that matters most.

## 2. Data layer
Local persistence only.

Responsibilities:
- SQLite schema and writes
- schedule storage
- reminder metadata
- conversation/proposal history if needed
- provider/settings storage

Keep this simple and local-first.

## 3. LLM adapter layer
One interface, multiple providers.

Target shape:
- `generateProposal(input, settings)`
- local provider implementation
- frontier provider implementation

Initial provider strategy:
- default to whatever is most reliable for the demo
- if local open-source model works well enough, great
- if not, remote is acceptable for the hackathon as long as the architecture keeps provider choice open

The important bit is the seam, not ideological purity.

## 4. UI / transport layer
First client:
- Flutter app

Optional later client:
- remote agent / messaging interface

This layer should be thin.
It should orchestrate user interaction, not own business logic.

---

## Why this shape is good

### If time runs out
You still have a real app.

### If the local model underperforms
You can switch to the frontier provider for demo purposes.

### If you get time late in the week
You can add a remote surface without rewriting the product.

### If the hackathon goes well
You have a clean base to keep building from.

---

## Practical implementation guidance

### Keep the first happy path brutally narrow
Example:
- one input screen
- one proposal screen
- one confirmation action
- one saved-plan view
- one reminder creation path

Not:
- multiple tabs
- generalized tool abstractions
- complex chat orchestration
- speculative multi-agent behavior

### Design for seams, not for scale
It is enough if the code is shaped so a future remote client could call the same functions.
You do not need to build the future remote client now.

### Avoid backend creep
Unless something truly forces it, do not introduce a backend just to feel “serious.”
The local-first story is part of the product value.

---

## Recommended stretch path

If the core app is working by late weekend, then the remote agent layer can be a tiny wrapper that can:
- submit raw input
- request a proposal
- return the proposal
- confirm and save

That is enough.

No broad tool execution.
No shell.
No giant permission system.
No multi-channel support.

Just one extra doorway into the same system.

---

## Product framing

The most persuasive framing is probably:

> We focused first on making the private local workflow real.
> The agent surface is additive, not the foundation.

That sounds disciplined instead of hand-wavy.

---

## Build-order rule

1. make the local workflow real
2. make it feel trustworthy
3. make it demo cleanly
4. only then add remote access

That order is how this avoids turning into a beautiful corpse.
