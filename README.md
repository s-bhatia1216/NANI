# NANI: A Compassionate Medicine Companion 

<img src="nani_logo.png" alt="NANI Logo" width="250" align="right" style="margin-right: 20px; margin-bottom: 10px;"> 

> *"Nani" means grandmother in Hindi—a symbol of warmth, care, and gentle guidance. NANI is an AI-powered medication adherence system, a voice that speaks her language (English, Hindi, Spanish, or any other), designed to help elderly patients like Maya Sharma stay healthy, independent, and connected to their care circle of family members and doctors.*
🎥 [Watch the Demo Video](https://youtu.be/y7C8Kh3Aam4)

## 🌟 The Story Behind NANI 
Imagine Maya Sharma, a 75-year-old living alone in San Jose, managing multiple medications for thyroid, blood pressure, diabetes, and cholesterol. Her days are filled with pills at different times—some on an empty stomach, some with meals, some only when needed. Her family worries: *Did she remember? Did she take the right dose? Is she feeling okay?*

Missed doses cause **nearly 1 in 3 hospital readmissions**, and we wanted to fix that with empathy and smart tech. NANI was born from a simple truth: **medication adherence isn't just about technology—it's about dignity, independence, and peace of mind.**

For Maya, NANI is more than a reminder system. It's a voice that speaks her language (English and Hindi), understands her concerns, and connects her to her care circle of doctors, nurses, and family members she designates. When Maya takes her medication, an invisible IR beam detects it. When she has questions, she asks NANI through her phone. 

**NANI bridges the gap between independence and safety, between technology and humanity.**

---

## 💡 The Vision

NANI transforms medication management from a burden into a seamless, supportive experience:

- **Passive Detection**: IR beam sensors detect when medication is actually taken—no manual logging required
- **Voice-First Interaction**: Natural conversations in multiple languages with a compassionate AI assistant
- **Care Circle Integration**: Real-time updates to family members and healthcare providers
- **Cultural Sensitivity**: Bilingual support (English/Hindi) that respects cultural context, with more languages in beta.
- **Proactive Health Monitoring**: Tracks adherence patterns and alerts caregivers to potential issues

---

## 🏗️ System Architecture

NANI is a full-stack IoT system integrating hardware sensors, cloud services, mobile applications, and voice interfaces.

```
                      ┌──────────────────────────────┐
                      │         NANI System          │
                      └──────────────────────────────┘

       ┌───────────────────────┐           ┌──────────────────-────┐
       │     Raspberry Pi      │◄─────────►│       iOS App         │
       │  + IR Beam Sensor     │           │       (Swift)         │
       │                       │           │  • Medication Tracking│
       │                       │           │  • Voice AI Assistant │
       │                       │           │  • Care Circle Portal │
       └──────────┬────────────┘           └──────────┬──────-─────┘
                  │                                   │
                  │                                   │
                  │                         ┌─────────▼───-───────┐
                  │                         │   Node.js Backend   │
                  │                         │ (Express + OpenAI)  │
                  └───────────────────────► │ • Voice Processing  │
                                            │ • Med Logging       │
                                            │ • Care Notifications│
                                            └─────────┬───────────┘
                                                      │
                                            ┌─────────▼───-───────┐
                                            │   Google Sheets     │
                                            │     (Data Log)      │
                                            └─────────────────────┘
```

---

## 🔧 Technical Components

### 1. Hardware Layer (Raspberry Pi)

**Components:**
- Raspberry Pi 3 Model B (or newer)
- IR Break-Beam sensor pair (emitter + receiver)
- GPIO pin 27 for sensor input
- 330Ω resistor for current limiting

**Functionality:**
- Continuously monitors IR beam state (BLOCKED = medication taken, CLEAR = no interruption)
- Debounced GPIO reading to prevent false triggers
- FastAPI service exposes REST endpoints for status and control
- Systemd service ensures automatic startup on boot
- Heartbeat mechanism for live monitoring

**Key Files:**
- `hardware/beam.py` - Core GPIO monitoring class (`BeamWatcher`)
- `hardware/beam_api.py` - FastAPI microservice with `/health`, `/start`, `/stop` endpoints
- `hardware/beam_raw.py` - Standalone debugging script with CSV logging

**Integration:**
- Posts beam events to configurable webhook (Google Apps Script or backend API)
- Supports dynamic URL configuration via API calls
- Handles network failures gracefully with timeout protection

### 2. Backend Services (Node.js)

**Technology Stack:**
- Node.js 20+ with Express
- OpenAI API (Whisper STT, GPT-4o-mini, TTS)
- Multer for audio file handling
- WebSocket support for real-time communication

**API Endpoints:**

**`POST /api/voice-exchange`**
- Accepts audio file (multipart/form-data) or text input
- Performs speech-to-text transcription via Whisper
- Generates contextual responses using GPT-4o-mini with NANI persona
- Synthesizes speech using OpenAI TTS
- Returns both text transcript and base64-encoded audio

**Persona Configuration:**
NANI is configured as a warm, encouraging AI caretaker:
- Acknowledges feelings before providing concrete next steps
- Tracks adherence and safety (dizziness, missed pills, BP spikes)
- Offers proactive help (reminders, hydration tips, caregiver updates)
- Maintains cultural sensitivity and respect

**Key Files:**
- `backend/src/server.js` - Main Express server with voice processing pipeline
- `backend/package.json` - Dependencies and scripts

### 3. iOS Application (Swift)

**Architecture:**
- Native Swift iOS app with UIKit
- Tab-based navigation (Home, AI Assistant, Medications)
- MVVM-inspired architecture with shared managers
- Bilingual localization (English/Hindi) via `LocalizationManager`

**Core Features:**

**Home Screen:**
- Personalized greeting with profile image
- Next medication reminder with time and dosage
- Quick action buttons (Remind Later, Mark as Taken)
- Care Circle section with family member profiles
- Activity log showing recent medication events

**Voice Assistant:**
- Real-time audio recording and playback
- Integration with backend voice API
- Visual feedback during recording/processing
- Transcript display for accessibility

**Medication Management:**
- Medication list with schedules
- Detailed medication information (dosage, purpose, instructions)
- Medication logging with timestamps
- Adherence tracking and history

**Care Circle:**
- Family member profiles
- In-app messaging and notifications
- Activity sharing with caregivers (doctors / nurses)
- Emergency contact integration

**Key Files:**
- `nani/HomeViewController.swift` - Main dashboard
- `nani/VoiceInteractionViewController.swift` - Voice AI interface
- `nani/MedicationsViewController.swift` - Medication list and details
- `nani/VoiceAssistantService.swift` - Backend API client
- `nani/MedicationLogManager.swift` - Medication logging and persistence
- `nani/LocalizationManager.swift` - Bilingual text management

### 4. Data Layer (Google Sheets)

**Purpose:**
- Centralized logging of all medication events
- Historical data for adherence analysis
- Care circle visibility into medication patterns
- Backup data store independent of app state

**Implementation:**
- Google Apps Script webhook receives POST requests from Raspberry Pi
- Logs timestamp, event type, sensor value, device ID
- Accessible to caregivers via shared Google Sheet

---

## 🚀 Getting Started

### Prerequisites

**Hardware:**
- Raspberry Pi 3 Model B+ (or newer)
- IR Break-Beam sensor pair
- Breadboard and jumper wires
- 330Ω resistor
- USB power supply

**Software:**
- Raspberry Pi OS (latest)
- Node.js 18+ (for backend)
- Xcode 15+ (for iOS development)
- OpenAI API key with access to:
  - Whisper (speech-to-text)
  - GPT-4o-mini (text generation)
  - TTS models (text-to-speech)

### Installation

#### 1. Raspberry Pi Setup

```bash
# Install base packages
sudo apt update
sudo apt install -y python3-pip python3-venv python3-rpi.gpio python3-fastapi python3-uvicorn python3-requests

# Clone or copy project files to /home/pi/nani/
cd /home/pi/nani

# Install Python dependencies
pip3 install fastapi uvicorn requests pydantic

# Configure systemd service
sudo cp hardware/nani-beam-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable nani-beam-api
sudo systemctl start nani-beam-api
```

**Hardware Wiring:**
- Connect IR emitter: 5V → 330Ω resistor → Emitter VCC, GND → GND
- Connect IR receiver: 5V → VCC, GND → GND, Signal → GPIO 27

See `hardware/hardware_setup.md` for detailed wiring diagrams.

#### 2. Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env with your OPENAI_API_KEY
npm install
npm run dev  # Development mode
# or
npm start    # Production mode
```

The server will listen on `http://127.0.0.1:4000` by default.

#### 3. iOS App Setup

1. Open `nani.xcodeproj` in Xcode
2. Configure signing with your Apple Developer account
3. Update `VoiceAssistantService.swift` if backend is not on localhost:
   ```swift
   VoiceAssistantService.shared.backendBaseURL = URL(string: "https://your-backend.com")
   ```
4. Build and run on simulator or device

#### 4. Google Sheets Integration

1. Create a new Google Sheet named "NANI Events"
2. Open Extensions → Apps Script
3. Paste the webhook handler (see `hardware/hardware_setup.md` section 5)
4. Deploy as Web App (Execute as: Me, Access: Anyone)
5. Copy the Web App URL and configure in Raspberry Pi service:
   ```bash
   sudo systemctl edit nani-beam-api
   # Add: Environment=URL=https://script.google.com/macros/s/YOUR_ID/exec
   ```

---

## 📱 Usage

### For Patients (Maya)

1. **Taking Medication:**
   - Remove medication from container (IR beam detects interruption)
   - System automatically logs the event
   - Receive confirmation via voice or app notification

2. **Asking Questions:**
   - Open iOS app → AI Assistant tab
   - Tap microphone and ask: "What's my next medication?" or "Should I check my blood pressure?"

3. **Checking Schedule:**
   - View Home screen for next medication reminder
   - Browse Medications tab for full schedule and details

### For Caregivers

1. **Monitoring Adherence:**
   - Access Google Sheet for real-time event log
   - View activity in iOS app Care Circle section
   - Receive notifications for missed doses or health concerns

2. **Communication:**
   - Send messages through Care Circle interface
   - View medication logs and adherence patterns
   - Coordinate with other caregivers

---

## 🎯 Impact & Future Vision

### Current Impact

NANI addresses critical challenges in elderly medication management:

- **Reduces medication errors** through passive detection and voice confirmation
- **Improves adherence rates** with timely, culturally-sensitive reminders
- **Enhances family peace of mind** through transparent care circle communication
- **Preserves patient dignity** by enabling independence with safety nets
- **Bridges language barriers** with native Hindi support

### Future Enhancements

- **Machine Learning**: Predictive adherence modeling based on historical patterns
- **Health Integration**: Connect with blood pressure monitors, glucose meters, and other IoT health devices
- **Telemedicine**: Direct integration with healthcare provider systems
- **Expanded Languages**: Support for additional languages (Punjabi, Gujarati, Mandarin, Spanish, etc.)
- **Smart Scheduling**: AI-powered medication timing optimization based on patient routine
- **Emergency Response**: Automatic alerts to emergency services for critical situations

---

## 👥 Team Contributions

### Sonal Bhatia — PM & Systems Engineer

**Responsibilities:**
- **Project Management**: Oversees project structure, system integration, and presentation
- **Hardware Integration**: Handles Raspberry Pi setup, sensor configuration, and GPIO logic
- **System Reliability**: Ensures demo reliability and end-to-end system testing
- **Documentation**: Maintains hardware setup guides and system architecture documentation

**Key Contributions:**
- Designed and implemented IR beam detection system
- Configured FastAPI service with systemd integration
- Established Google Sheets data logging pipeline
- Created comprehensive hardware setup documentation
- Ensured seamless integration between hardware and software layers

### Yash Thakkar — App & AI Engineer

**Responsibilities:**
- **Frontend Development**: Handles iOS app architecture, UI/UX design, and implementation
- **AI Integration**: Manages voice interface, OpenAI API integration, and conversational AI
- **Database & Notifications**: Implements medication logging, care circle messaging, and notification systems
- **Documentation & Design**: Documents app features and designs user experience flows

**Key Contributions:**
- Built native Swift iOS application with tab-based navigation
- Implemented bilingual localization system (English/Hindi)
- Integrated OpenAI voice API for natural language interactions
- Designed and developed Care Circle messaging system
- Created medication tracking and logging infrastructure
- Developed voice assistant service with real-time audio processing

---

## 📄 License

This project was developed for HackPrinceton F25. All rights reserved.

---

## 🙏 Acknowledgments

Special thanks to:
- The HackPrinceton F25 organizers and judges
- OpenAI for providing powerful AI models
- The open-source community for excellent tools and libraries
- Our families for inspiration and support

---

## 📞 Support

For questions, contributions, or collaboration opportunities, please reach out at yt5693@princeton.edu or sb7264@princeton.edu.

---

**Built with ❤️ for our Nanis and millions of patients like them who deserve independence, dignity, and peace of mind.**

