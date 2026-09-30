# JLPT Study — Unified Release Audit

Date: 2026-09-30
Branch: jlpt-study-v3-unified

## Curriculum coverage

- N4: 42/42 dedicated Schema v2 lesson assets.
- N3: 50/50 dedicated Schema v2 lesson assets.
- Total dedicated lesson assets: 92.
- N4 and N3 are exposed through the same app shell and level selector.

## Source mapping

N4 assets preserve the audited Somatome session/page mapping:
- Week 1: pp. 18–31
- Week 2: pp. 34–47
- Week 3: pp. 50–63
- Week 4: pp. 66–79
- Week 5: pp. 82–95
- Week 6: pp. 98–111

N3 assets preserve the catalogued Shin Kanzen Master structure:
- Part 1 grammar: P1L01–P1L12
- Consolidation A–J: P1A01–P1A10
- Part 2: P2L01–P2L05
- Part 3: P3L01–P3L10
- Reviews and mock units: R01–R13

## Runtime integration checked

- Level-specific content asset lookup exists for N4 and N3.
- Progress storage is separated by level.
- Unlocking and next-session logic use the active level catalog.
- XP, accuracy, mistakes and corrections are separated by level.
- App title/branding is generic JLPT Study rather than N3-only.
- pubspec includes the content asset directories.

## Content provenance

The lesson JSONs use Schema v2 and preserve source titles, page references and focus areas. Interactive questions added during this pass are explicitly original app exercises. They are not presented as literal transcriptions of the source books.

P1L01 remains the detailed source-structured N3 lesson. The remaining N3 units provide dedicated, source-mapped learning scaffolds and original practice; they should receive a second, exercise-level content audit before being described as full transcriptions.

## Verification limits

No Flutter SDK/compiler was available in the execution environment, so a local `flutter analyze` or release build was not run. GitHub reports no CI status checks for the latest content commit.

The working branch is 139 commits ahead of `main` and 0 commits behind it at the point of comparison; `main` was not modified.

## Release recommendation

The unified architecture and curriculum wiring are complete. Before publishing to an app store, run Flutter analysis/build on a machine with Flutter installed and perform a visual smoke test on desktop and mobile. A final exercise-level Japanese/Spanish audit is also recommended for the N3 content scaffolds.
