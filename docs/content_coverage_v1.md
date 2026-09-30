# JLPT Study — Content Coverage

Last audited in this iteration: 2026-09-30

## N4

The unified N4 curriculum contains 42 sessions.

All 42 sessions now have dedicated Schema v2 lesson assets:

- W01D01–W01D07 — pp. 18–31
- W02D01–W02D07 — pp. 34–47
- W03D01–W03D07 — pp. 50–63
- W04D01–W04D07 — pp. 66–79
- W05D01–W05D07 — pp. 82–95
- W06D01–W06D07 — pp. 98–111

The assets are source-structured and preserve the audited session/page mapping. Interactive questions are original app exercises rather than literal transcriptions of the book.

Important limitation: dedicated JSON coverage is complete, but not every source exercise/answer has been transcribed into the app. The N4 reading/listening assets currently focus on the skill and session structure rather than reproducing every book item.

## N3

The unified N3 curriculum contains 50 app study units.

All 50 units now have dedicated Schema v2 lesson assets:

- P1L01–P1L12 — Part 1, grammar lessons
- P1A01–P1A10 — consolidation A–J
- P2L01–P2L05 — Part 2, sentence construction
- P3L01–P3L10 — Part 3, text grammar
- R01–R13 — cumulative reviews and two mock-exam units

P1L01 is the first fully source-structured lesson, based on pp. 16–17 of the supplied Shin Kanzen Master N3 PDF.

The remaining N3 assets now provide dedicated lesson content, objectives, patterns and original interactive practice based on the catalogued source structure and page mapping. They are not literal transcriptions of the book exercises.

## Content policy inside the project

A lesson asset can contain:

1. Source-derived structure and learning objectives.
2. Source terminology and page mapping.
3. Short source examples where appropriate.
4. Original interactive questions written for the app.
5. A `content_note` documenting provenance and coverage.

The app must not label generated/original practice as if it were a transcription of the source book.

## Current status

The unified app now has dedicated content assets for every N4 and N3 study unit. The remaining work is quality assurance rather than curriculum wiring:

- validate every JSON against Schema v2;
- check duplicate IDs and malformed options/answers;
- verify N4↔N3 switching, unlocks, XP, accuracy and review;
- audit Japanese/Spanish wording;
- visually test desktop and mobile layouts;
- run Flutter analysis/build when a Flutter SDK is available.

