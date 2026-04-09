# V1 Testing Plan: 2026-04-09 Workstream

## Goal

Validate the mobile-first medication workflow that now spans:

- `Home` as the primary assistant surface
- manual medication add, edit, and remove from the calendar UI
- confirmation-gated AI draft review from Home chat
- a day-grouped history timeline built from events
- reminder cards derived from today's medication schedule
- direct adherence logging from UI and explicit Home chat messages

This plan is intended to cover the changes landed today and the immediate
follow-on work around reminders and "I took the medication" flows.

## Scope

### In scope

- mobile Home UX and composer-adjacent draft review
- manual CRUD for confirmed medication schedules
- proposal acceptance, cancellation, editing, and superseding behavior
- history timeline rendering from medication, proposal, assistant, and
  adherence events
- reminder card behavior on Home
- `medication_taken` creation from:
  - calendar day actions
  - explicit Home chat messages
- iOS simulator smoke coverage

### Out of scope

- real push notification delivery
- camera-based script capture
- voice ingestion
- server sync or cross-device state

## Test Strategy

Use three layers together:

1. Unit and reducer tests for event emission and projection correctness.
2. Widget and flow tests for mobile interaction paths.
3. Manual smoke testing on iOS simulator for real layout and navigation
   validation.

The release gate for this work should require all three layers to pass.

## Platforms

- Primary: iOS simulator
- Secondary: Flutter test environment
- Optional follow-up: Android emulator once iOS smoke is stable

Recommended device profiles:

- `iPhone 16 Plus`
- one smaller iPhone-sized simulator to pressure-test composer and sheet
  layouts

## Automated Coverage

### Unit and application tests

Add or keep coverage for the following:

- `ChatCoordinator.confirmPendingProposal` uses edited proposal actions rather
  than the original stored proposal payload.
- `ChatCoordinator.submitText` creates a new proposal when the model returns
  proposal actions.
- `ChatCoordinator.submitText` records direct adherence when the user sends an
  explicit taken message such as `I took vitamin D at 9:05`.
- `ChatCoordinator.submitText` does not supersede a pending proposal for
  adherence-only messages.
- `ChatCoordinator.submitText` asks for clarification when the taken message is
  ambiguous across multiple active medications.
- `MedicationCommandService.addSchedule` emits the correct event sequence.
- `MedicationCommandService.updateSchedule` emits
  `medication_schedule_updated` when identity is stable.
- Renaming an existing schedule is modeled as stop-old plus add-new rather than
  an in-place identity mutation.
- `MedicationCommandService.removeSchedule` stops the schedule without erasing
  history.
- `MedicationCommandService.recordMedicationTaken` emits a complete
  `medication_taken` payload including schedule, medication, scheduled time,
  and taken time.

### Projection and history tests

Add or keep coverage for:

- pending proposals do not appear in confirmed medication schedules
- manual schedule updates rebuild active schedules correctly
- removed schedules disappear from active lists but remain visible in history
- `medication_taken` appears in the history timeline with the correct day group
- reminder-shaped events remain mappable in the history model
- Home reminder derivation marks doses as:
  - upcoming
  - due now
  - overdue
  - taken

### Widget tests

Add or expand widget coverage for:

- Home draft affordance appears above the composer when a pending draft exists
- tapping the draft affordance opens the mobile draft sheet
- draft editing updates local form state before acceptance
- removing an action from the draft sheet excludes it from confirmation
- calendar screen supports manual add, edit, and remove flows
- calendar day row `Taken` action records adherence and updates visible state
- Home reminder cards render from today's schedule entries
- history screen renders grouped day sections with newest items first

## Manual Mobile Test Runs

### 1. Home draft review flow

1. Launch the app on iOS simulator.
2. From `Home`, send a medication-change message such as
   `Add vitamin D 1000 IU at 9am`.
3. Verify a pending draft affordance appears above the composer.
4. Open the draft sheet.
5. Edit one or more fields in the prefilled form.
6. Accept the draft.
7. Verify the schedule appears in the calendar and active schedule list.
8. Verify history contains:
   - the user message
   - the assistant/model turn
   - `proposal_created`
   - `proposal_confirmed`
   - medication registration/schedule events

### 2. Pending draft isolation

1. Create a pending medication draft from Home.
2. Do not accept it.
3. Navigate to `Calendar`.
4. Verify the pending medication does not appear as a confirmed schedule.
5. Return to `Home` and cancel the draft.
6. Verify confirmed schedules remain unchanged.

### 3. Manual add schedule

1. Open `Calendar`.
2. Use `Add medication`.
3. Save a medication with at least one daily time.
4. Verify:
   - the schedule appears in the active schedule list
   - the dose appears in the day view for the correct day/time
   - history includes medication creation events

### 4. Manual edit schedule

1. Edit an active schedule.
2. Change time, dose, and notes.
3. Save.
4. Verify:
   - active schedule values update immediately
   - day view reflects the new time
   - history shows an update event

### 5. Manual remove schedule

1. Remove an active schedule.
2. Confirm the destructive dialog.
3. Verify:
   - the schedule leaves the active list
   - future day entries are removed
   - history still shows prior creation and removal activity

### 6. Calendar adherence action

1. Open today's day view in `Calendar`.
2. Tap `Taken` for one scheduled dose.
3. Verify:
   - history shows a `medication_taken` item today
   - reminder cards and related UI move that dose to a taken state

### 7. Home reminder behavior

1. Seed or create schedules for earlier, current, and later times today.
2. Open `Home`.
3. Verify reminder cards classify doses correctly as overdue, due now, and
   upcoming.
4. Mark one dose taken.
5. Verify that card now shows taken state.

### 8. Direct "I took it" Home chat logging

1. Ensure at least one active medication exists.
2. In `Home`, send `I took vitamin D at 9:05`.
3. Verify:
   - no proposal sheet is created
   - no existing pending proposal is removed
   - history shows a `medication_taken` item
   - the assistant confirms the medication was recorded

### 9. Ambiguous adherence clarification

1. Ensure at least two active medications exist.
2. In `Home`, send `I already took it`.
3. Verify:
   - no adherence event is recorded
   - the assistant asks which medication was taken
   - no pending proposal is superseded

### 10. Navigation and product-language sanity

1. Verify bottom navigation labels are `Home`, `Calendar`, and `History`.
2. Verify the app no longer exposes thread selection or thread-centric copy in
   primary user flows.

## Edge Cases

Explicitly test these cases before considering the work stable:

- only one medication exists and the user says `I took it`
- multiple medications share similar names
- a medication has multiple daily times and the user reports a taken time close
  to one of them
- a taken message omits time completely
- the user sends a new medication-change request while a draft is already
  pending
- the user edits a proposal action to remove required fields and attempts to
  accept it
- a schedule is edited to change medication name
- very small screens with the keyboard open on Home
- long medication names and long notes in reminder cards and history rows

## Suggested Test Data

Use a seed set like:

- `Vitamin D` at `09:00`
- `Magnesium` at `21:00`
- `Metformin` at `09:00` and `21:00`

This dataset covers:

- single-medication adherence shorthand
- ambiguous adherence messages
- multi-time schedule resolution
- morning and evening reminder states

## Release Gate

Do not treat this work as complete until:

- targeted unit tests are green
- widget coverage exists for the main mobile interaction paths
- iOS simulator smoke run passes end to end
- no runtime errors appear after hot reload or hot restart
- history, Home reminders, and calendar views all stay consistent after the
  same medication action

## Immediate Follow-On Tests

When real reminder scheduling is added, extend this plan with:

- scheduling event creation
- delivery event creation
- notification tap acknowledgement
- skipped reminder handling
- app restart persistence for scheduled reminders
