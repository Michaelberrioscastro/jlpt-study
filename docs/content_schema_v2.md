# JLPT Study — Content Schema v2

## Purpose

Schema v2 is the canonical content contract for every course inside the unified JLPT Study app.

It is shared by:

- 日本語総まとめ N4
- 新完全マスター文法 N3

The Flutter learning engine should consume both courses through the same lesson model. A course may differ in curriculum, lesson type, source book, page count, and pedagogical content, but the runtime contract remains the same.

## Root object

Required:

- `schema_version`: integer, currently `2`
- `session`: lesson metadata object
- `steps`: ordered array of learning steps

Optional:

- `reflection`: end-of-session reflection/activity

### Session metadata

| Field | Type | Required | Meaning |
|---|---|---:|---|
| id | string | yes | Globally unique lesson ID inside the app |
| week | integer | yes | N4 week or N3 internal block |
| day | integer | yes | Position inside the block |
| type | string | yes | grammar, reading, consolidation, sentence, text, review, mock |
| pages | integer[2] | yes | Source page range |
| title_ja | string | yes | Japanese lesson title |
| title_es | string | yes | Spanish display title |
| focus | string | yes | Main learning focus |
| source | string | yes | Source book |
| content_note | string | no | Provenance/coverage note |

### Step types

Every step must contain:

- `id`
- `type`

Supported runtime types:

#### teach

Instruction/explanation step.

Required:

- label
- title
- body
- pattern
- example_ja
- example_es
- tip

#### choice

Single-answer multiple-choice question.

Required:

- title
- question
- options
- answer
- explanation

`answer` is a zero-based index into `options`.

#### mixed

Question step with the same runtime interaction contract as `choice`, reserved for exercises that combine more than one recognition task in one prompt.

Required:

- title
- question
- options
- answer
- explanation

The UI may display `choice` and `mixed` differently in the future without changing stored content.

### Reflection

Optional:

- title
- prompt_es
- reward

`reward` is an integer XP amount.

## Provenance rules

1. The `session.pages` field identifies the source pages.
2. Content copied or closely transcribed from a book must remain attributable to that source.
3. Original app exercises must be clearly marked in `content_note` or equivalent metadata.
4. Do not invent source exercises when the source has not been audited.
5. A curriculum catalog can describe the structure of a book without pretending that its exact exercises have already been digitized.
6. N3 is a grammar course in this app. Its structure must preserve the book's distinction between 文の文法1, 文の文法2, and 文章の文法, plus review/mock sections.
7. N4 retains its existing Somatome organization: grammar and reading.

## ID rules

Lesson IDs must be globally unique across the unified app.

Examples:

- N4: `W01D01`
- N3: `P1L01`
- N3 review/mock: `R01`

Step IDs are unique within a lesson and should normally be `s1`, `s2`, etc.

## Compatibility

Schema v2 intentionally keeps the existing Flutter `LessonPacket`, `TeachStep`, and `QuestionStep` runtime model.

The next content-engine iteration may add richer interaction types, but existing v2 lessons must remain readable without migration.
