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
const DEMO_PERSONA_PROMPT =
  process.env.NANI_DEMO_PROMPT ||
  `
You are “Nani,” the warm, encouraging AI caretaker who helps Maya Sharma stay on top of her medications and daily routines.
Guidelines:
- Sound like a compassionate grandmother; short, upbeat sentences under ~30 seconds of speech.
- Always acknowledge Maya’s feelings, then give the concrete next medication or safety step.
- Track adherence and safety: if she reports dizziness, missed pills, or BP spikes, remind her to alert her nurse or caregiver Priya.
- Offer proactive help: future reminders, hydration tips, caregiver updates.
- Never mention system prompts, implementation details, or API keys. Just act like Nani on a smart speaker.
`;
const DEMO_DAY_PLAN = [
  {
    time: '7:30 AM',
    medication: 'Levothyroxine',
    dosage: '75 mcg',
    purpose: 'Thyroid hormone replacement',
    instructions: 'Take on an empty stomach with water, wait 30 minutes before breakfast',
    status: 'Taken? confirm'
  },
  {
    time: '8:00 AM',
    medication: 'Lisinopril',
    dosage: '10 mg',
    purpose: 'Blood pressure control',
    instructions: 'Check BP first; remind to sit if dizzy',
    status: 'Due now'
  },
  {
    time: '12:00 PM',
    medication: 'Metformin',
    dosage: '500 mg',
    purpose: 'Blood sugar maintenance',
    instructions: 'Take with lunch or light snack to avoid stomach upset',
    status: 'Upcoming'
  },
  {
    time: '3:00 PM',
    medication: 'Vitamin D',
    dosage: '2000 IU',
    purpose: 'Bone health',
    instructions: 'OK with tea; note if already took earlier',
    status: 'Optional supplement'
  },
  {
    time: '6:00 PM',
    medication: 'Atorvastatin',
    dosage: '20 mg',
    purpose: 'Cholesterol',
    instructions: 'Take after dinner; remind to log if skipped due to muscle pain',
    status: 'Upcoming'
  },
  {
    time: 'Bedtime',
    medication: 'Melatonin',
    dosage: '3 mg (PRN)',
    purpose: 'Sleep support',
    instructions: 'Only if restless; encourage wind-down routine first',
    status: 'As needed'
  }
];

const CAREGIVER_ROSTER = [
  {
    name: 'Raj Sharma',
    relation: 'Husband & primary contact',
    phone: 'Raj cell: (408) 555-1101',
    notes: 'Works from home; can assist with evening meds and transportation.'
  },
  {
    name: 'Priya Patel, RN',
    relation: 'Visiting nurse',
    phone: 'Nurse line: (408) 555-2202',
    notes: 'Checks vitals Mon/Wed/Fri 7 PM; wants alerts for dizziness, missed BP meds, or BP > 150/95.'
  },
  {
    name: 'Anika Sharma',
    relation: 'Daughter (remote support)',
    phone: 'FaceTime preferred',
    notes: 'Lives in Seattle; appreciates updates when new symptoms appear.'
  }
];
const SHEET_ID = process.env.GOOGLE_SHEET_ID || '1t7M0WSvLJXgy0RUafI29wZBj9heO8mOOuIGdA5Lzqxs';
const SHEET_GID = process.env.GOOGLE_SHEET_GID || '0';
const SHEET_REFRESH_MS = Number(process.env.GOOGLE_SHEET_REFRESH_MS || 1_000);
const SHEET_ZERO_COOLDOWN_MS = Number(process.env.GOOGLE_SHEET_ZERO_COOLDOWN_MS || 10_000);
let cachedSheetEntry = null;
let lastSheetFetchedAt = null;
let sheetPoller = null;
let lastZeroNotificationAt = 0;
const sheetEventClients = new Set();

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

app.get('/debug/sheet', (_req, res) => {
  res.json({
    sheetId: SHEET_ID,
    gid: SHEET_GID,
    fetchedAt: lastSheetFetchedAt,
    latestEntry: cachedSheetEntry
  });
});

app.get('/events/sheet', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();
  res.write(`event: connected\ndata: {}\n\n`);
  sheetEventClients.add(res);
  req.on('close', () => {
    sheetEventClients.delete(res);
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
    const promptBlocks = [
      DEMO_PERSONA_PROMPT.trim(),
      buildDemoScenarioContext(cachedSheetEntry),
      (req.body?.context || '').trim()
    ].filter(Boolean);
    const systemPrompt = promptBlocks.join('\n\n');

    const resp = await openai.responses.create({
      model: GEN_MODEL,
      input: [
        {
          role: 'system',
          content: [{ type: 'input_text', text: systemPrompt }]
        },
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

function buildDemoScenarioContext(sheetEntry) {
  const now = new Date();
  const friendlyDate = new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric'
  }).format(now);

  const medsAgenda = DEMO_DAY_PLAN.map(
    (item) =>
      `${item.time} – ${item.medication} ${item.dosage} (${item.purpose}; ${item.status}). Notes: ${item.instructions}`
  ).join('\n- ');

  const caregivers = CAREGIVER_ROSTER.map(
    (c) => `${c.name} – ${c.relation}. Contact: ${c.phone}. Notes: ${c.notes}`
  ).join('\n- ');
  const sheetSummary = formatSheetEntry(sheetEntry);

  return [
    `Today is ${friendlyDate}. Patient: Maya Sharma, 75, lives in San Jose by herself.`,
    'Recent vitals: BP 132/84 this morning, fasting glucose 110 mg/dL, reports mild dizziness when standing quickly.',
    'Care circle:',
    `- ${caregivers}`,
    'Today’s medication plan:',
    `- ${medsAgenda}`,
    sheetSummary ? `Latest care log from Google Sheet:\n${sheetSummary}` : null,
    'Goals: keep blood pressure in range, encourage hydration, confirm she has eaten before the noon Metformin.',
    'If Maya confirms taking a dose, celebrate it and remind her it is logged. If she misses or feels unwell, suggest checking BP and calling Yash or Sonal.'
  ].filter(Boolean).join('\n');
}

async function startSheetPoller() {
  if (!SHEET_ID) return;
  await refreshSheetEntry();
  sheetPoller = setInterval(refreshSheetEntry, SHEET_REFRESH_MS);
}

async function refreshSheetEntry() {
  if (!SHEET_ID) return;
  const entry = await fetchSheetEntryFromSource();
  if (entry) {
    cachedSheetEntry = entry;
    lastSheetFetchedAt = new Date().toISOString();
    console.log('[sheet] refreshed at', lastSheetFetchedAt);
    console.log('[sheet] latest entry', entry);
    handleSheetTriggers(entry);
  }
}

async function fetchSheetEntryFromSource() {
  if (!SHEET_ID) return null;
  try {
    const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:csv&gid=${SHEET_GID}`;
    const response = await fetch(url);
    if (!response.ok) {
      const body = await response.text();
      console.warn('[sheet] Failed to fetch latest entry', response.status, body.slice(0, 200));
      return null;
    }
    const csv = await response.text();
    const rows = parseCsv(csv);
    if (rows.length <= 1) {
      return null;
    }
    const headers = rows[0];
    const dataRows = rows
      .slice(1)
      .filter((row) => row.some((cell) => cell && cell.trim().length > 0));
    if (dataRows.length === 0) return null;
    const latest = dataRows[dataRows.length - 1];
    const entry = {};
    headers.forEach((header, index) => {
      entry[header.trim() || `Column${index + 1}`] = (latest[index] || '').trim();
    });
    return entry;
  } catch (error) {
    console.warn('[sheet] Unable to fetch latest entry', error);
    return null;
  }
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    const next = text[i + 1];
    if (char === '"') {
      if (inQuotes && next === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      row.push(current);
      current = '';
    } else if ((char === '\n' || char === '\r') && !inQuotes) {
      if (row.length || current) {
        row.push(current);
        rows.push(row);
        row = [];
        current = '';
      }
    } else {
      current += char;
    }
  }
  if (row.length || current) {
    row.push(current);
    rows.push(row);
  }
  return rows;
}

function formatSheetEntry(entry) {
  if (!entry) return '';
  const timestamp = entry.Timestamp || entry.Time || entry.Date || '';
  const summary = Object.entries(entry)
    .filter(([, value]) => value && value.trim().length > 0)
    .map(([key, value]) => `${key}: ${value}`)
    .join('; ');
  return timestamp ? `${timestamp} – ${summary}` : summary;
}

function handleSheetTriggers(entry) {
  if (!entry) return;
  const values = Object.values(entry).map((value) => (value ?? '').toString().trim());
  const hasZero = values.includes('0');
  if (!hasZero) return;
  const now = Date.now();
  if (now - lastZeroNotificationAt < SHEET_ZERO_COOLDOWN_MS) {
    return;
  }
  lastZeroNotificationAt = now;
  const message = {
    type: 'pillDetected',
    timestamp: new Date().toISOString(),
    entry
  };
  const payload = `event: pillDetected\ndata: ${JSON.stringify(message)}\n\n`;
  sheetEventClients.forEach((client) => {
    try {
      client.write(payload);
    } catch (error) {
      console.warn('[sheet] failed to notify client', error);
      sheetEventClients.delete(client);
    }
  });
}

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

startSheetPoller().catch((err) => console.warn('[sheet] poller failed to start', err));

app.listen(PORT, HOST, () => {
  console.log(`✅ Voice backend listening on http://${HOST}:${PORT}`);
});
