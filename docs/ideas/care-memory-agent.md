# Care Memory Agent

## Concept

A privacy-first health coordination agent that ingests messy multimodal inputs, extracts structured care history, builds a timeline, and answers natural-language questions over that history.

This is not a diagnosis tool. It is a patient-side memory, coordination, and preparation agent.

## Problem

Families managing complex care often carry fragmented, manual, error-prone health administration burdens. Important information is spread across:
- prescriptions
- medicine changes
- voice notes
- lab results
- appointment summaries
- photos of documents
- ad hoc text messages and notes

That fragmentation makes continuity harder. People forget when medicines changed, what the last result was, or what questions they wanted to ask at the next appointment.

## Core idea

The agent accepts messy inputs such as:
- text
- voice notes
- images of scripts or documents
- lab result images or PDFs

It extracts structured data into schemas such as:
- medications
- prescriptions
- lab results
- appointments
- notes / symptoms

Then it can answer questions like:
- When did this medicine change from one dose to another?
- What were the last blood results like?
- Graph the urea result over time.
- What changed since the last appointment?
- Draft questions for the next consultant visit.

## Why this is a strong agent idea

This is naturally agentic because it combines:
- multimodal ingestion
- structured extraction
- timeline building
- question answering over longitudinal history
- messy language understanding
- workflow support for real humans

It avoids the awkwardness of forcing a pure machine-learning prediction problem into a hackathon format.

## Recommended product framing

Best framing for the competition:
- **A personal clinical memory / care coordination agent**
- **A patient-side care continuity agent**
- **An AI agent that converts fragmented health information into structured, searchable care history**

This makes the broader value clearer for:
- families managing complex care
- people with many appointments or prescriptions
- people who need better continuity and preparation

## MVP scope

### Inputs
- text
- image upload
- voice note

### Structured entities
- medications
- prescriptions
- lab results
- appointments
- notes

### Core features
- extract into schema
- maintain a timeline
- answer questions over history
- generate appointment summaries

## Agreed MVP spec (April 1)

This is the agreed hackathon direction as of April 1.

### Product framing

For now, this should be treated as a **digital health tracker** with a very specific first workflow.

The first meaningful feature is **scripts / prescriptions**:
- a user can take a photo of a script
- the app extracts the medicine, dose, and schedule information
- the app proposes what it thinks should happen next
- the user confirms, edits, or cancels that proposal
- once confirmed, the app stores the result locally and can schedule reminders

### Primary MVP workflow

The MVP is a chat-style interface where the user can send:
- a text message
- a photo
- a voice note

The system should then:
1. parse the incoming information
2. extract proposed medication and dosage details
3. generate a structured proposal for what should be saved
4. show that proposal in a structured review UI above the chat
5. let the user confirm, edit, or cancel
6. on confirmation, save the result to a local SQL database
7. schedule medication reminders based on the confirmed dosage/timing

### Core first-use case: scripts

The first use case we should optimise for is:
- user uploads a picture of a prescription / script
- system extracts medicine name, dose, frequency, and timing clues
- system turns that into a medication schedule proposal
- user confirms or corrects it
- app persists the medication plan and reminder schedule locally

Examples:
- “Take once daily” → create one daily reminder
- “Twice daily” → create two daily reminder times
- “Three times a day” → create three reminder times

### Additional input modes

The same workflow should also work from:
- direct text (“Start amoxicillin 500mg three times a day for 7 days”)
- voice notes describing changes (“He is now taking this twice daily instead of once”)

So the real capability is not just OCR on scripts — it is **multimodal medication schedule capture and proposal generation**.

### Proposal-first UX

A key product rule for this MVP:

The agent should **not silently save medication changes**.

It should always create a proposal such as:
- medicine name
- dosage
- frequency
- reminder times
- start date / effective date
- any notes it inferred

The user must then be able to:
- confirm
- edit
- cancel

This confirmation/edit step is where the structured proposal review UI fits best.
The chat collects the raw user input, and the proposal panel renders the
structured proposal and editing controls.

### Timeline / calendar direction

Not required for the first end-to-end slice, but this is the next obvious view:
- a calendar or timeline showing medication events and schedule history
- a day view showing when medicines should be taken
- a history of dosage changes over time

This should be treated as **next-step UX**, not the first thing to build.

### Hackathon implementation constraints

For the hackathon version, keep the architecture simple:
- build it as a Flutter app
- use a structured proposal / confirmation UI in the app shell
- use a local SQL database for persistence
- do not build a backend server just to hide an API key
- it is acceptable for the hackathon build to read the AI key from a local file/config
- we are not optimising for production deployment yet
- the app only needs to run locally (simulator, desktop build, or directly on Cillian’s phone)

In other words: **do not over-engineer this**.
The goal is to prove the product loop, not build a production platform.

### Success criteria for MVP

If we can get this one loop working well, the MVP is successful:
1. send text, image, or voice note
2. extract a medication schedule proposal
3. let the user confirm/edit it in the proposal review UI
4. save it locally
5. create reminders from the confirmed plan

That is enough to demonstrate the concept clearly.

## Example demo flow

1. Upload a photo of a prescription.
2. The app extracts the medication and proposes a schedule.
3. The user edits or confirms the proposed reminder times.
4. The app saves the plan locally and creates reminders.
5. Send a voice note saying a dose changed to twice daily.
6. The app proposes an updated schedule.
7. The user confirms the change.

## Public health data angle

Public datasets are not the core of this idea, but they can add supporting context:
- HSE/public service navigation
- official service explanations
- public medicine/service information
- general explanation of tests or care pathways

The strongest version keeps the core on user-provided private records and uses public information as supporting context, not as the main product.

## Key risks and design constraints

### 1. Privacy and security
This project deals with highly sensitive health information.

It should be designed with:
- privacy-first storage
- strong access control
- human review of extracted facts
- source preservation alongside structured data
- clear correction/edit flows

### 2. Medical overreach
The agent should not be framed as:
- diagnosis
- treatment advice
- clinical decision-making
- automated medication management

It should stay in:
- recordkeeping
- continuity
- care coordination
- appointment preparation
- explanation over known records

### 3. Extraction mistakes
Critical facts like doses or lab values can be misread.

Important design principle:
- extract
- show parsed fields
- let the human confirm or correct them
- keep provenance visible

### 4. Scope creep
This idea can expand too fast.

Hackathon version should focus on a few record types and a tight demo loop.

## Competition fit

This idea is strong because it has:
- a real user
- a real problem
- obvious agent behaviour
- clear value over deterministic software
- strong “human intelligence driving transformative innovation” alignment

## IP / ownership caution

If this is also something to build personally beyond the hackathon, there may be ambiguity depending on:
- employment contract
- invention assignment clauses
- side-project/IP policy
- whether employer time/resources were used
- whether it overlaps with employer business

That does not mean it is unsafe to prototype, but it does mean it is worth checking before assuming long-term ownership is simple.

## Architecture: Local-First, Privacy by Design

### Why local-first?

Storing health data in the cloud introduces GDPR complexity, data residency concerns, and trust barriers. For a care memory agent dealing with prescriptions, lab results, and medical history, the privacy story needs to be airtight.

The answer: **everything runs on the user's own machine**. No cloud accounts. No data leaves the device. The user owns their data completely.

This is not a limitation — it is the product's strongest differentiator. It aligns with the direction the industry is heading (Apple on-device ML, Signal's architecture, local-first software movement).

### Docker: One command to run

The entire agent ships as a Docker image. Users do not need to install Python, manage dependencies, configure model downloads, or worry about OS-specific tooling. Docker provides:

- **Cross-platform compatibility** — same Ubuntu-based image runs on macOS, Windows, Linux
- **Dependency isolation** — Python version, transcription libraries, OCR tools, everything is bundled
- **Reproducible environment** — no "works on my machine" problems
- **Simple distribution** — `docker run` or `docker compose up` and you are running

```bash
# One command to start the agent
docker compose up
```

### Docker Compose: Two-service architecture

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama-models:/root/.ollama
    ports:
      - "11434:11434"

  care-agent:
    build: .
    volumes:
      - ~/care-memory-data:/data  # All patient data stays on host
    ports:
      - "8080:8080"
    depends_on:
      - ollama
    environment:
      - OLLAMA_HOST=http://ollama:11434
      - TIER=full  # or "lite"

volumes:
  ollama-models:
```

Key design decisions:
- **Ollama** runs as a separate service and manages model downloads/caching
- **Patient data** is volume-mounted from the host — never baked into the container
- **Models** are pulled on first run and cached in a named volume — not bundled in the image (a 7B model is 4-5 GB; baking it in makes the image impractical)
- The agent code image stays small and fast to download

### Model tiers

Two tiers, selected at startup based on available hardware:

| Tier | Target Hardware | Model | RAM Needed | Capability |
|------|----------------|-------|------------|------------|
| **Lite** | Laptop, 8 GB RAM, no GPU | Gemma 2 2B or Phi-3 Mini (3.8B) | ~4 GB | Basic extraction, slower Q&A, still functional |
| **Full** | 16 GB+ RAM or discrete GPU | Gemma 2 9B or Llama 3.1 8B | ~8-10 GB | Better extraction quality, faster responses |

The agent detects available memory at startup and recommends a tier, or the user can override with an environment variable.

Two tiers is enough to demonstrate that the architecture scales. A third tier with 70B+ models is theoretically possible but impractical to test and support in the hackathon timeframe.

### What runs locally

| Component | Tool | Purpose |
|-----------|------|---------|
| LLM inference | Ollama (Gemma 2, Llama 3.1, Phi-3) | Extraction, Q&A, summarisation |
| OCR | Tesseract (bundled in Docker) | Text extraction from prescription/lab images |
| Speech-to-text | whisper.cpp or faster-whisper | Voice note transcription |
| Vector search | ChromaDB or SQLite with embeddings | Semantic search over care history |
| Structured storage | SQLite | Medications, labs, appointments, timeline |
| Web UI | Streamlit or Gradio | Simple interface for demo |

Everything in the table above runs inside Docker on the user's machine. No external API calls required.

### Optional cloud escape hatch

If local models are not sufficient for certain extraction tasks (e.g., complex handwritten prescriptions), the agent can optionally send **anonymised text snippets** to a cloud model (Vertex AI Gemini via the GCP credits). Key constraints:

- Cloud is opt-in, not default
- Only transient text is sent, never raw images or full records
- No persistent cloud storage
- PII is stripped or anonymised before sending
- The user is informed when cloud processing is used

This gives a quality boost where needed while preserving the local-first privacy story.

### Data backup

All data lives in the mounted volume on the user's machine. For backup:

- Encrypted export using `age` or `gpg` to a USB drive, NAS, or second disk
- Simple, auditable, no cloud dependency
- The agent can provide a one-click encrypted backup/restore flow

### Hackathon demo plan

For the live demo, run on the Mac Mini (M-series, 16 GB+ RAM) in Full tier:

1. `docker compose up` — agent starts, model is already cached
2. Upload a photo of a prescription → extracted medication data shown
3. Send a voice note about a dose change → transcribed and structured
4. Upload a lab result → parsed into timeline
5. Ask natural-language questions over the history
6. Show that everything is in `~/care-memory-data/` on the local machine — nothing in the cloud

The pitch: *"We built a care memory agent that keeps all your health data on your own device. No cloud. No GDPR headaches. You own your data. And it works because modern open-source models are good enough to run locally."*

## Recommendation

This is one of the strongest ideas discussed. It is more naturally agent-shaped than many of the generic public-data concepts, as long as it is kept firmly in patient memory, continuity, and coordination rather than diagnosis.
