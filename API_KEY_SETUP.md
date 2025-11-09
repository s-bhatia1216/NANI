# Voice Backend Setup

The iOS client now talks to our Node proxy (`backend/`) which streams recorded audio to OpenAI's speech-to-speech model and returns synthesized audio plus text.

## Configure the Backend

1. `cd backend`
2. `cp .env.example .env` and fill in:
   - `OPENAI_API_KEY` – your OpenAI key with access to the speech-to-speech preview models.
   - Optional overrides for `OPENAI_SPEECH_MODEL`, `OPENAI_SPEECH_VOICE`, etc.
3. `npm install`
4. `npm run dev` (or `npm start` for production)

The server listens on `PORT` (default `4000`). The iOS app points at `http://127.0.0.1:4000/api/voice-exchange` by default via `VoiceAssistantService`.

## iOS Client Configuration

If you need to hit a different host/port (e.g., physical device or deployed backend), update:

```swift
VoiceAssistantService.shared.backendBaseURL = URL(string: "https://your-host.com")
```

You can place that in `AppDelegate` or a feature flag when the app launches.

## Security Notes

- Keep the OpenAI API key in the backend only—never ship it with the iOS app.
- Lock down the backend with auth if you expose it publicly (API keys, mTLS, or your existing auth stack).
- Log response IDs (`rawResponseId`) on the backend to help trace conversations during support incidents.
