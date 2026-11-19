# ZOD-FND-010 Research and document the Swiss Ephemeris license decision: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (default, sequential). This is a **non-code research task**: there is no TDD and no test run; verification is source-checking (Task 4). No work here is independent enough for subagents.

**Goal:** Produce a written, sourced decision record that states which Swiss Ephemeris license path Zodiann takes (AGPL with the app's source published, or the paid Astrodienst professional license), why, and what each path obliges, so that ZOD-REL-003 (store distribution) and ZOD-ABT-007 (the About screen's license list) can follow it.

**Architecture:** One new document, `docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md` (a new `docs/decisions/` folder; no decision-record folder exists yet, and PROGRESS's Technical Decisions table stays the index). The research reads the vendor's own published terms first, and a second independent source for every cost or obligation the decision rests on. The choice itself is the **product owner's** (it depends on the open question "store distribution or private installation", spec "Questions to answer before professional development"); the research presents the options and a recommendation, and the record is finalized only after the owner decides.

**Tech Stack:** none (Markdown). Sources are fetched with the web tools; nothing is sent to any outside party.

**Spec:** `assets/zodiann-specification.md` risk R-6, the "License" row of "Decisions and implications", Appendix F, and the open question on distribution; task file `docs/development/foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md`; consumers `docs/development/release-preparation/ZOD-REL-003-*.md` and `docs/development/about/ZOD-ABT-007-*.md`.

## Product-owner decisions needed

- **L1: the distribution channel (decided 2026-11-19: ZOD-REL-003 owns it).** App Store and Google Play, or private installation only. FND-010 does not decide it: it is an input. The record gives the license recommendation as a function of the channel, and ZOD-REL-003 (whose task file owns the channel decision) confirms the final path against the channel it picks.
- **L2: the license path.** The owner's present choice, taken after the research is presented (REL-003 reconfirms it against the channel): (a) AGPL and publish the app's complete source, (b) buy the Astrodienst professional license, or (c) leave Swiss Ephemeris (the spec's backup, astronomy-engine, is the alternative; it carries its own accuracy tolerance, ACC-2, and would change ZOD-EPH-002 and the accuracy tests, so it is outside this task and would be raised as a separate decision).
- **L3 (informational):** the record's location (`docs/decisions/`) is the executor's choice; PROGRESS Technical Decisions links to it.

## Global Constraints

- **Not legal advice:** the record says so at the top (the spec and the task both require it), and nothing in it is presented as a legal conclusion; ambiguities become questions for Astrodienst or a lawyer.
- **No outward action:** the task says "contact Astrodienst (or review their current published terms)". The executor reads published terms only. If they leave a question open, the record contains a drafted question for the product owner to send; the executor sends nothing and uses no project, personal or account detail in any search or request.
- **Facts carry sources:** each cost, term or obligation has the source URL and the date it was read, and quotes at most a short phrase (paraphrase otherwise). A fact found on one page only is marked "single source". Nothing is stated from memory without a source.
- **Do not edit requirements:** the task's acceptance criteria and the spec are unchanged; REL-003 and ABT-007 get Notes pointing to the record, not edited criteria.
- **Git:** task branch `task/ZOD-FND-010-swiss-ephemeris-license-decision`; commit format `docs(ZOD-FND-010): …`; push and PR after verification.

## Review Focus

- **Stale or moved vendor pages:** the license page, price and wording may have changed or be unreachable. Each source is dated; a fetch failure is recorded, and the record says what could not be confirmed instead of filling the gap.
- **App-store compatibility of AGPL:** whether AGPL-licensed code can be distributed through the Apple App Store and Google Play at all is contested; the record states what the sources say, what is contested, and does not assert either way without a source.
- **What the license covers:** the C code and the ephemeris data files (`.se1`) may have the same or different terms, and the Moshier built-in mode (ZOD-EPH-003) is part of the library; the record states which parts each path covers, since the data-file coverage decision (ZOD-FND-011) and the fallback mode depend on it.
- **Open-source consequences of AGPL:** which of the app's own code must be published (the whole app, the FFI package only), the source-offer obligation for network use versus distribution, and the effect on any other license in the app (the app ships IBM Plex and Noto fonts under OFL; the dependencies list in ZOD-ABT-007).
- **Version and edition:** the terms apply to a Swiss Ephemeris version; the record names the version it read (the project pins none yet; ZOD-FND-003 will).
- **Cost and scale:** any per-app, per-seat or per-revenue terms in the professional license, and whether they depend on number of users, so the owner can compare the price with the product's intended audience (spec: personal use or wide audience).

---

## File Structure

| File | Responsibility |
|---|---|
| `docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md` (create) | the decision record: sources, options, obligations, recommendation, the decision |
| `docs/development/release-preparation/ZOD-REL-003-*.md` (modify) | a Note pointing to the record and to L1 |
| `docs/development/about/ZOD-ABT-007-*.md` (modify) | a Note giving the Swiss Ephemeris chip's license text source from the record |
| `docs/development/foundations-architecture/ZOD-FND-010-*.md` (modify) | status, ticked criteria with evidence |
| `docs/development/TASKS.md`, `docs/PROGRESS.md` (modify) | status, Technical Decisions row, a new Blockers entry for R-6, and the Completed Tasks row |

---

### Task 1: gather the sources

**Files:** none yet (notes are kept in the working scratch and go into Task 2's record).

- [ ] **Step 0: Tools.** If no web tool is available or a page cannot be fetched, record "not confirmed" for what depends on it and stop; never fill the gap from memory.
- [ ] **Step 1: Vendor pages.** Read Astrodienst's published pages for the Swiss Ephemeris: the license overview and the professional-license terms, the price list, and the licensing FAQ; record each URL and the date read. Capture: the two license offers and their exact names, the price and what it covers (one app, an edition, a user count), whether the data files are covered, and any statement on app stores or on closed-source apps.
- [ ] **Step 2: The license texts.** Read the AGPL text as the vendor applies it (the AGPL version, the "additional permission" if any) and the vendor's statement of which of its files are under which license.
- [ ] **Step 3: Independent sources.** Find at least one independent source for each of: whether AGPL software can be distributed through the Apple App Store and Google Play (the FSF and Apple/Google terms, or well-sourced commentary), how other apps use Swiss Ephemeris in a closed-source mobile app (the Dart / Flutter / mobile bindings' own license notes, for example `sweph` packages and their README), and the astronomy-engine license (MIT, to state the alternative accurately). Record URL, date and "single source" where applicable. Also check whether the vendor's current wording distinguishes a free and a professional edition (cost, scale and the built-in Moshier mode depend on it).
- [ ] **Step 4: Gaps.** List what the sources do not settle; each becomes either a drafted question for the owner to send to Astrodienst or an item in the record's "Open questions".

### Task 2: draft the record

**Files:** create `docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`.

The record has these sections, in order: **Status and disclaimer** (draft until the owner decides; "not legal advice"); **Question and why now** (R-6, what depends on it: REL-003, ABT-007, FND-003, FND-011, EPH-002, EPH-003); **Sources** (table: URL, date read, what it supports, single-source flag); **Options** (table: A AGPL and publish the source; B professional license; C leave Swiss Ephemeris, with for each: obligations, cost, what it covers, effect on the app's own code and other licenses, store implications, effect on the tasks above, risks); **Findings the sources do not settle** (open questions, with drafted questions for Astrodienst); **Recommendation** (one option, with the reasoning tied to the channel answers L1: stores or private); **Decision** (empty until Task 3).

- [ ] **Step 1:** write every section above from the Task 1 notes, each fact with its source.
- [ ] **Step 2:** write the Recommendation as a function of L1: what to choose if the answer is stores, what if it is private installation only, and say which the sources favour.
- [ ] **Step 3: Commit** `docs(ZOD-FND-010): draft the Swiss Ephemeris license record`.

### Task 3: the owner's decision

- [ ] **Step 1:** present the options and the recommendation briefly and ask the owner L2 (the AskUserQuestion tool), saying plainly that the channel is still open and REL-003 will reconfirm; do not decide for them. If the owner wants Astrodienst contacted first, hand over the drafted question and leave the record in draft with the task `In Progress`. If the owner cannot choose a path before the channel is known, the record can state the conditional recommendation, but criterion 1 ("which license path was chosen") would then be met only conditionally: that is the owner's call to accept or not (do not reinterpret the criterion silently); without that acceptance the task stays `In Progress`.
- [ ] **Step 2:** write the owner's answer into the record's **Decision** section (date, path, why, the channel assumed or left to REL-003, what follows: the obligations they now carry, for example publishing source under AGPL or buying the license before any store submission) and set the status to Decided.

### Task 4: verify, review, document, hand over

If the owner has not decided L2 (Task 3), do **not** run Steps 3 to 5's completion edits: set the task file `Status` to `In Progress`, add a PROGRESS Current Task entry naming the open question (and the drafted Astrodienst question if one exists), and open the PR as a draft or do not open it. The steps below assume a decision.

- [ ] **Step 1: Source check.** Re-read the record against its sources: every cost, term and obligation matches the cited page (re-fetch the two or three that matter most); no unsourced claim; no long quotation; the disclaimer is at the top; the links work (open each once). This replaces the test run for a documentation task; state in PROGRESS that there is no code and no command result.
- [ ] **Step 2: Review.** One fresh reviewer reads the record against its sources and the task's criteria (the whole-branch review for a documentation task); fix the findings in the record.
- [ ] **Step 3: Consumers** (after the review fixes, so the Notes cannot go stale). Add the Notes to ZOD-REL-003 (the record path, the decision, the channel left open to it) and ZOD-ABT-007 (the record path and the license text the Swiss Ephemeris chip must show), tick the two ZOD-FND-010 criteria with their evidence (the record path; the REL-003 Note), set `Status: Done (see Notes)`, and update `TASKS.md`.
- [ ] **Step 4: PROGRESS.** Completed Tasks row (what was verified: sources re-read, dates; no code), Technical Decisions row (L1, L2), the Blockers section (add an R-6 entry, then mark it resolved or list what remains, for example "the Astrodienst answer"), Current Task, Next Recommended Task (re-evaluated), Git State.
- [ ] **Step 5:** push `task/ZOD-FND-010-swiss-ephemeris-license-decision`, open the PR, then add the PR link in a follow-up docs commit.

## Acceptance mapping

| Criterion | Proven by |
|---|---|
| A written decision record exists stating which license path was chosen and why | the record's Decision section, written from the owner's answers (Task 3), with the sources behind the reasons (Tasks 1–2, verified in Task 4 Step 1) |
| The decision is referenced by ZOD-REL-003 before any store submission | the Note added to ZOD-REL-003 (Task 4 Step 3); ZOD-REL-003 depends on this task and cannot start without it |

## Risks and open items

- The decision needs the owner's answer on distribution (L1); until then the task stays in progress.
- The vendor's published terms may not answer every question; those become drafted questions the owner can send, and the record says what is unconfirmed.
- Nothing here is legal advice; the record says so, and the owner may want a lawyer's view before a store submission (ZOD-REL-003's gate).
- If the owner chooses to leave Swiss Ephemeris (option C), that is a separate decision touching ZOD-EPH-002/003, ZOD-FND-003/011 and the accuracy tests; it is raised, not carried out, here.

## Plan review

### Round 1 (comprehensive) — verdict: needs user decision (D1), answered

0 Critical, 2 Important, 3 Minor, 1 needs-user-decision. The review ran with the dedicated `plan-reviewer` agent.

- **D1 (product owner, 2026-11-19):** who decides the distribution channel. Answer: **ZOD-REL-003 owns it**; FND-010 treats it as an input and gives the license recommendation as a function of the channel. Consequence recorded in the plan: criterion 1 may be only conditionally met until REL-003, which is the owner's call to accept (Task 3 Step 1).
- **I1 (applied):** Task 4 now says what happens when L2 is undecided (task `In Progress`, PROGRESS entry, draft or no PR, no completion edits).
- **I2 (applied):** Task 4 reordered: source check, review and fixes, then the consumer Notes, status and PROGRESS.
- **M1 (applied)** the Blockers entry for R-6 is new; **M2 (applied)** Task 1 Step 0 says what to do without web tools; **M3 (applied)** Task 1 Step 3 checks the free vs professional edition wording.
- Open items: none.
