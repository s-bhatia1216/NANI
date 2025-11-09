# Nani Voice Backend (Node)

Node/Express microservice that proxies audio + text to OpenAI's speech-to-speech Responses API.

## Prerequisites

- Node.js 18+
- An OpenAI API key with access to the speech-to-speech preview models

## Setup

```bash
cd backend
cp .env.example .env # edit with your key + model overrides
npm install
npm run dev
```

The server listens on `PORT` (default 4000).

## API

### `POST /api/voice-exchange`

`multipart/form-data` fields:

- `audio` (optional) – audio clip (wav/mp3/ogg/etc.) recorded at 16 kHz mono recommended
- `text` (optional) – fallback text prompt if no audio is provided

At least one of `audio` or `text` is required.

**Response**

```json
{
  "text": "Assistant transcript",
  "audioFormat": "wav",
  "audioBase64": "...",
  "rawResponseId": "resp_..."
}
```

Return audio is base64-encoded. Decode it on the client before playback.

### `GET /health`

Simple readiness probe that reports the configured model + voice.

## Notes

- The server uses the official `openai` SDK and the new Responses API with `modalities: ["text", "audio"]`.
- Adjust `OPENAI_SPEECH_MODEL`, `OPENAI_SPEECH_VOICE`, and `OPENAI_AUDIO_FORMAT` in `.env` to try different voices or codecs.
- `MAX_AUDIO_BYTES` (default 15 MB) guards against oversized uploads—tune as needed for your capture length and bitrate.
