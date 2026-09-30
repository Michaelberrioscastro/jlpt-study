# Guided Curriculum Expansion v1

## Objective

The app keeps the existing books, sessions, educational order and source mapping, but each session is now expanded at runtime into a guided mini-lesson.

For every level/book combination, the lesson flow adds:

1. Additional explanation or reading strategy.
2. Four active vocabulary items.
3. Two verb-production items with dictionary, ます, ない and て forms.
4. Three kanji-in-context items.
5. A vocabulary question.
6. A verb-form question.
7. A kanji-in-context question.
8. A transfer/application question.

The original book-derived session content remains the base. The added material is original app content and is not a transcription of copyrighted exercises.

## Coverage

The enrichment engine is applied after loading the JSON packet and therefore covers:

- 日本語総まとめ N4
- 新完全マスター 読解 N4
- 新完全マスター 文法 N3
- JSON-backed sessions and catalog fallback sessions

The engine selects vocabulary, verbs and kanji according to the active level and rotates the selection by session ID so consecutive sessions do not all show the same study bank.

## Answer randomization

All choice questions are randomized when a lesson is opened.

The question ID stays unchanged for progress tracking, but the option order is shuffled and the correct-answer index is recalculated. This applies to:

- original JSON questions
- catalog fallback questions
- newly generated enrichment questions

The learner can no longer infer the answer from a fixed position.

## Pedagogical basis

The expansion follows the idea that JLPT preparation should combine language knowledge with the ability to use that knowledge in reading/listening tasks. The official JLPT guide describes N4 as requiring basic Japanese comprehension and N3 as understanding everyday Japanese to a certain degree.

The 3A Network description of 新完全マスター 文法 N3 emphasizes learning grammar through both meaning/function and form, contrasting easily confused expressions, and practicing grammar in sentence/text contexts. The expansion follows that same principle without copying the book.

External reference resources used to shape the expansion:

- JLPT official guide: https://www.jlpt.jp/reference/pdf/guide_2026.pdf
- 3A Network — 新完全マスター文法 N3: https://www.3anet.co.jp/np/books/3604/
- JLPT Sensei — N4 grammar reference: https://jlptsensei.com/jlpt-n4-grammar-list/
- JLPT Sensei — N3 grammar reference: https://jlptsensei.com/jlpt-n3-grammar-list/
- JLPT Sensei — N4 study guide: https://jlptsensei.com/how-to-pass-jlpt-n4-study-guide/
- JLPT Sensei — N3 study guide: https://jlptsensei.com/how-to-pass-jlpt-n3-study-guide/

These sources are used as reference material for level scope, grammar functions, vocabulary/kanji coverage and study methodology. The app does not copy their example sentences or proprietary exercise sets.

## Important limitation

The JLPT itself does not publish an official current list of required vocabulary, kanji and grammar. Therefore the level banks are treated as curated study targets rather than an official exhaustive specification.
