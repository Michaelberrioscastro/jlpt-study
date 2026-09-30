# JLPT Study: Premium Product Direction

## Product idea

JLPT Study is a daily study ritual, not a dashboard. Every visit answers one question: what is my next small win?

The primary loop is:

1. Open the app and see today's mission.
2. Continue one clearly selected lesson.
3. Receive XP, progress, and a visible unlock.
4. Return tomorrow to protect the streak.

## Visual architecture

- **Home / Today:** hero mission, streak, XP pulse, and daily missions.
- **Path / Course:** vertical map of sessions with completed, active, and locked nodes.
- **Review:** error recovery and spaced-practice priorities.
- **Progress:** mastery, streak, XP, and weekly momentum.
- **Book dashboard:** deep content navigation for users who want to browse.

The sidebar remains the global orientation layer. The main surface stays focused on one action at a time.

## Tokens

### Color

| Token | Value | Role |
| --- | --- | --- |
| background | `#090E1D` | app canvas |
| surface | `#121A2E` | primary panels |
| surface-2 | `#18233B` | secondary panels |
| ink | `#F7F8FC` | primary text |
| muted | `#A9B2C7` | supporting text |
| violet | `#9585FF` | active learning |
| coral | `#FF6B68` | streak and warmth |
| mint | `#56CDB4` | completed state |
| yellow | `#FFC857` | XP and rewards |
| sakura | `#F08CA4` | Japanese identity accent |

### Shape and spacing

- Base spacing: 4px increments.
- Content gutters: 20px compact, 42px wide.
- Primary radius: 24px.
- Action radius: 16px.
- Node size: 34px.
- Card borders: 1px using the border token; elevation comes from soft colored shadows.

### Typography

- Display: heavy, short, and sentence-case.
- Eyebrow: 9px, uppercase, 1.5px tracking.
- Body: 10-12px for dense learning surfaces.
- Japanese examples: 20-24px with generous line height.

## Motion language

- Page entry: 220ms ease-out.
- Path node state: 220ms ease-out with a subtle scale on unlock.
- Lesson completion: 420ms ease-out-back celebration, followed by XP count-up.
- Use motion to communicate state change; avoid permanently animated decoration in tests and low-power contexts.

## Component inventory

- `StudioHomePage`: daily command center.
- `_TodayHero`: one primary CTA and current lesson context.
- `_LearningPath`: vertical unlock map.
- `_MissionCard`: daily retention loop.
- `_ProgressPulse`: XP and level reinforcement.
- `_SideMenu`: global navigation, level, and book switcher.
- `_SessionTile`: reusable lesson node for course and review.
- `_ResultDialog`: completion and retry feedback.

## Wireframe

```text
[ avatar ] Buenos dias, estudiante             [ streak ]
          Somatome N4

[ TODAY HERO                                      ]
[ next lesson ] [ progress ] [ Continuar mision ]

TU RUTA                                  07 / 42
Sigue el hilo
[ o ] Dia 1 ...                         >
[ o ] Dia 2 ...                         >
[ o ] Dia 3 ...                         >
[ o ] Dia 4 ...                         lock

MISIONES DE HOY
[ complete session ] [ review error ] [ protect streak ]

[ XP PULSE ]                              >
[ Explorar libro ]
```

## Product guardrails

- One primary CTA per surface.
- Never hide the next action behind analytics.
- Locked content explains what unlocks it.
- Rewards reinforce learning behavior, not random tapping.
- Ranking is optional and never the default source of pressure.
- Empty states always suggest the next useful action.

## Next implementation slices

1. Add a real daily mission model and persist mission completion.
2. Add achievement definitions and a collection screen.
3. Add a theme mode switch backed by `ThemeMode`.
4. Add sound and haptics behind user preferences.
5. Add lightweight celebration overlays after a passed lesson.
