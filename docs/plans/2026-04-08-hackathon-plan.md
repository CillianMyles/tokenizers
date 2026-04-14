# Hackathon Plan — April 8 to April 14

## Goal

Ship something real enough to demo on April 14 without betting the week on infrastructure.

The right target is **not** a mini OpenClaw platform.
The right target is a **local-first agentic app** with one magical loop that works end to end.

For this repo, that likely means:

1. user provides text / image / voice input
2. app parses it into a proposed medication schedule
3. user confirms or edits the proposal
4. app saves the confirmed result locally
5. app creates reminders from the confirmed schedule

If that works cleanly, the project is already defensible.
Anything beyond that is stretch.

---

## Product Positioning

Pitch this as:

> A private, local-first health assistant that helps turn messy real-world medication information into a usable, confirmable schedule.

Not as:

> a general agent framework

The strong story is:
- local-first
- structured output, not chatbot fluff
- confirmation before commit
- optional model choice
- real user value

---

## Build Strategy

## Phase 1 — Must work

By default, optimize for the thing that still demos well even if no remote agent layer ships.

Required:
- Flutter app shell works
- input flow works
- proposal generation works
- confirm/edit/cancel flow works
- local persistence works
- reminders can be created from confirmed schedule
- one model provider works reliably

Strongly preferred:
- support both a local model option and one frontier model option behind a shared adapter
- basic history / previously saved schedules view

Nice but optional:
- image input
- voice input
- better onboarding/settings
- provider switch UI

---

## Phase 2 — Polish

Only after the core loop is working:
- tighten UX copy
- reduce failure states
- improve proposal readability
- improve empty/loading/error states
- make the confirmation moment feel good
- prepare demo script and seeded example data

---

## Phase 3 — Stretch / bonus

Only if the core loop is already solid:
- add a remote agent or messaging layer
- expose the same core actions through that transport
- keep it extremely narrow

This is a bonus, not the bet.

---

## What to Avoid This Week

Do not spend the remaining time building:
- a general-purpose agent platform
- multi-channel messaging
- cloud sync
- auth/accounts
- multi-user infrastructure
- complex memory systems
- plugin systems
- shell tools / broad tool execution
- infrastructure whose value only appears after the demo

That is all seductive and all dangerous right now.

---

## Daily Plan

## Wed Apr 8 (tonight)
- lock the scope
- agree the exact “one magical loop”
- write down success criteria
- identify current repo state vs missing pieces

## Thu Apr 9
- make the end-to-end happy path work locally
- one input path
- one proposal generation path
- one confirmation path
- local save

## Fri Apr 10
- reminder creation
- persistence cleanup
- basic history / saved results visibility
- remove obvious demo-breaking bugs

## Sat Apr 11
- improve UX
- make proposal editing / confirmation clearer
- tighten model/provider behavior
- add seeded demo examples if useful

## Sun Apr 12
- decide whether image/voice input is worth adding
- otherwise spend the day making the main loop sharper
- maybe begin remote layer only if the core already feels real

## Mon Apr 13
- demo prep day
- script the pitch
- rehearse fallback path if LLM/provider fails
- bug fixes only

## Tue Apr 14
- submission-ready cleanup
- zero risky refactors
- package what works

---

## Definition of Done for the Hackathon

A successful submission is one where someone can see:
- messy input comes in
- the app extracts meaningful structure
- the user stays in control
- confirmed data is stored locally
- reminders can be created
- the privacy/local-first angle is credible

That is enough.

If there is also a remote/agent surface by then, great.
If not, the project can still be good.

---

## Decision Rule

For every new idea, ask:

> Does this improve the April 14 demo of the core loop?

If no, defer it.

That rule should save the week.
