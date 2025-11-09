// --------------------------------------------------------
// Voice Backend Server
// --------------------------------------------------------
import { File as NodeFile } from 'node:buffer';
if (!globalThis.File) globalThis.File = NodeFile;
import 'dotenv/config';
import express from 'express';
import multer from 'multer';
import OpenAI from 'openai';
import { toFile } from 'openai/uploads';

// --------------------------------------------------------
// Environment Variables
// --------------------------------------------------------

const PORT = process.env.PORT || 4000;
const HOST = process.env.HOST || '127.0.0.1';

const GEN_MODEL = process.env.OPENAI_GEN_MODEL || 'gpt-4o-mini';
const TTS_MODEL = process.env.OPENAI_TTS_MODEL || 'gpt-4o-mini-tts';
const STT_MODEL = process.env.OPENAI_STT_MODEL || 'whisper-1';

const VOICE = process.env.OPENAI_SPEECH_VOICE || 'alloy';
const AUDIO_FORMAT = process.env.OPENAI_AUDIO_FORMAT || 'wav'; // wav|mp3|opus|aac|flac

if (!process.env.OPENAI_API_KEY) {
  throw new Error('OPENAI_API_KEY is required. Add it to your environment or .env file.');
}

// --------------------------------------------------------
// OpenAI Client
// --------------------------------------------------------

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// --------------------------------------------------------
// Express Setup
// --------------------------------------------------------

const app = express();
app.use(express.json({ limit: '1mb' }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: Number(process.env.MAX_AUDIO_BYTES || 15 * 1024 * 1024) } // 15 MB
});

// --------------------------------------------------------
// Health Check
// --------------------------------------------------------

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    sttModel: STT_MODEL,
    genModel: GEN_MODEL,
    ttsModel: TTS_MODEL,
    voice: VOICE,
    format: AUDIO_FORMAT
  });
});

// --------------------------------------------------------
// Main Speech → Text → LLM → Speech Route
// --------------------------------------------------------

app.post('/api/voice-exchange', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file?.buffer?.length && !req.body?.text?.trim()) {
      return res.status(400).json({
        error: 'Provide at least one of: text field or audio file (multipart field name "audio").'
      });
    }

    if (req.file) {
      console.log('[upload]', {
        name: req.file.originalname,
        mimetype: req.file.mimetype,
        bytes: req.file.size
      });
    } else {
      console.log('[upload] no file received');
    }
    

    // --------------------------------------------------------
    // 1. STT if audio uploaded
    // --------------------------------------------------------

    let userText = (req.body?.text || '').trim();

    if (req.file?.buffer?.length) {
      const inferredFormat = inferAudioFormat(req.file);

      const file = await toFile(req.file.buffer, `input.${inferredFormat}`, {
        type: mimeForFormat(inferredFormat)
      });

      const stt = await openai.audio.transcriptions.create({
        file,
        model: STT_MODEL
      });

      userText = `${userText ? userText + '\n\n' : ''}${stt.text}`.trim();
    }

    if (!userText) {
      return res.status(400).json({ error: 'No user text after transcription.' });
    }

    // --------------------------------------------------------
    // 2. LLM Text Generation
    // --------------------------------------------------------

    const resp = await openai.responses.create({
      model: GEN_MODEL,
      input: [
        {
          role: 'user',
          content: [{ type: 'input_text', text: userText }]
        }
      ]
    });

    const replyText = extractText(resp) || 'Okay.';

    // --------------------------------------------------------
    // 3. TTS (text → audio)
    // --------------------------------------------------------

    const speech = await openai.audio.speech.create({
      model: TTS_MODEL,
      voice: VOICE,
      input: replyText,
      format: AUDIO_FORMAT
    });

    const audioBuffer = Buffer.from(await speech.arrayBuffer());

    // --------------------------------------------------------
    // Final Response
    // --------------------------------------------------------

    res.json({
      text: replyText,
      audioFormat: AUDIO_FORMAT,
      audioBase64: audioBuffer.toString('base64')
    });

  } catch (error) {
    console.error('[voice-exchange] request failed', error);
    const status = error.status ?? 500;
    res.status(status).json({
      error: error.message ?? 'Unhandled OpenAI error',
      details: error.response?.data ?? null
    });
  }
});

// --------------------------------------------------------
// Helpers
// --------------------------------------------------------

function inferAudioFormat(file) {
  if (file?.mimetype?.includes('m4a')) return 'm4a';
  if (file?.mimetype?.includes('x-m4a')) return 'm4a';
  if (file?.originalname?.toLowerCase().endsWith('.m4a')) return 'm4a';

  if (file?.mimetype?.includes('wav')) return 'wav';
  if (file?.mimetype?.includes('mp3')) return 'mp3';
  if (file?.mimetype?.includes('mpeg')) return 'mp3';
  if (file?.mimetype?.includes('ogg')) return 'ogg';

  return AUDIO_FORMAT;
}

function extractText(response) {
  for (const out of response.output ?? []) {
    for (const c of out.content ?? []) {
      if (c.type === 'output_text' || c.type === 'text') return c.text;
    }
  }
  return undefined;
}

function mimeForFormat(fmt) {
  switch (fmt) {
    case 'm4a': return 'audio/m4a';
    case 'mp4': return 'audio/mp4';
    case 'wav': return 'audio/wav';
    case 'mp3': return 'audio/mpeg';
    case 'ogg': return 'audio/ogg';
    default: return 'application/octet-stream';
  }
}

// --------------------------------------------------------
// Start Server
// --------------------------------------------------------

app.listen(PORT, HOST, () => {
  console.log(`✅ Voice backend listening on http://${HOST}:${PORT}`);
});
