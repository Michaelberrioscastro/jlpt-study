# Sensei online

Sensei supports any OpenAI-compatible chat endpoint. The app sends the active JLPT level, recent chat history, and the current course sessions as grounding context.

Build or run with:

```text
flutter run --dart-define=SENSEI_API_URL=https://your-server.example/v1/chat/completions --dart-define=SENSEI_API_KEY=YOUR_KEY --dart-define=SENSEI_MODEL=gpt-4o-mini
```

For production, point `SENSEI_API_URL` at your own server-side proxy. Do not ship a permanent provider key inside a public mobile build. The proxy can enforce rate limits, redact personal data, select the provider, and keep the API key private.

When `SENSEI_API_URL` is absent or unreachable, the app falls back to the local JLPT tutor and keeps the chat usable offline.
