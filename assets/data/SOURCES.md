# Content data sources

## JLPT vocabulary

- File: `assets/data/jlpt_vocab.csv`
- Source: user-provided JLPT vocabulary dataset.
- Fields: original expression, furigana, English gloss, JLPT level.
- The app imports this data into the existing `vocabulary` table without overwriting existing SRS state.

## JLPT kanji

- File: `assets/data/anchorI_kanji.json`
- Source: AnchorI, jlpt-kanji-dictionary.
- Repository: https://github.com/AnchorI/jlpt-kanji-dictionary
- License: MIT.
- Imported metadata: JLPT level, stroke count, radical number, frequency, word usage counts and description.
- The source data is normalized before being bundled with the app.

## Design principle

Imported content is treated as source data. User progress remains in the local SRS and knowledge-state tables and is never replaced by a content refresh.
