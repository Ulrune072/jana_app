# JANA — Demo & Examiner Preparation

## How to run the project for the demo

### Step 1 — Backend
```bash
cd jana-backend
npm install
# copy .env.example to .env and fill in your keys
npm run dev
```

### Step 2 — Simulator (separate terminal)
```bash
# get a JWT by temporarily printing it in the app after login:
# print(Supabase.instance.client.auth.currentSession?.accessToken)
# paste it as SIMULATOR_TEST_TOKEN in .env, then:
npm run simulate
```

### Step 3 — Flutter
```bash
cd jana-flutter
flutter pub get
flutter run
```

---

## Questions you will be asked and how to answer them

**"Walk me through what happens when a reading comes in."**
The simulator posts an array of readings to POST /api/biomarkers/ingest.
Express validates the type and value, inserts them into biomarker_readings in Supabase,
then calls checkThresholdsAndAlert for each one. That function compares the value
against our clinical threshold constants. If it's outside the warning range, it inserts
a row into the alerts table and sends an email to the doctor_email on the profile.
The Flutter dashboard uses RefreshIndicator so pulling down fetches the latest data.

**"Why did you use Riverpod instead of setState?"**
The dashboard needs to share state between multiple widgets — the biomarker cards,
the alert badge, and the manual input form all need to trigger the same reload.
With setState you'd have to pass callbacks down through the widget tree.
Riverpod lets any widget watch the same provider and react when it updates.

**"What is Row Level Security and why does it matter here?"**
RLS is a Postgres feature where the database itself enforces access control.
Without it, any authenticated user could call the Supabase API and query
another user's biomarker readings by guessing their UUID — which in a health
app would be a GDPR violation. With RLS enabled, Postgres reads the JWT
from the request, extracts the user's ID using auth.uid(), and silently filters
every query so users only ever see their own rows. It works even if our Express
code has a bug.

**"Why does the chatbot check rules before calling Gemini?"**
Gemini has a rate limit on the free tier and adds latency. The most common
questions — "what is my heart rate", "show my summary" — don't need AI at all,
they just need to look up a value in the database. The rules engine handles
those instantly at zero cost. Gemini only gets called for open-ended questions
that the rules can't match. This is called a hybrid approach.

**"Why Gemini instead of OpenAI?"**
Google's Gemini 1.5 Flash has a genuinely free tier with no credit card needed,
which is appropriate for a student project. The API structure is nearly identical
to OpenAI so switching later requires changing about 10 lines of code.

**"What does the Dio interceptor do?"**
It runs before every HTTP request and attaches the current Supabase access token
to the Authorization header. The key word is "current" — Supabase tokens expire
after one hour. If you stored the token at login and reused it, every request
would silently fail with 401 after 60 minutes. The interceptor reads
currentSession at the exact moment of each request, so it always has a fresh token.

**"Why did you use 10.0.2.2 instead of localhost for the backend URL?"**
On Android emulator, localhost resolves to the emulator's own network stack,
not the host machine. 10.0.2.2 is a special alias the Android emulator provides
to reach the host machine's localhost. On a real physical device you'd use
the host machine's local network IP instead.

**"How does the mock simulator work?"**
It's a standalone Node.js script that runs on a 10-second interval.
Each tick it generates realistic random readings for all biomarker types.
Every 7th tick it generates slightly abnormal values that trigger the threshold
checker and create alerts — this makes the demo more interesting because you
can show the alert badge appearing in real time.

**"What would you improve if you had more time?"**
Push notifications instead of just email alerts. A proper doctor portal
instead of one-way emails. Persistent session handling with token refresh.
Actual Bluetooth device integration. The current BLE support is scaffolded
but not wired up because we prioritised the data pipeline and chatbot for MVP.

---

## Things to demonstrate in order

1. Open app -> shows login screen (auth guard working)
2. Register a new user -> lands on dashboard (profile trigger working)
3. Dashboard shows -- for all readings (empty state handled)
4. Start simulator in terminal -> pull to refresh on dashboard -> cards populate
5. Tap Blood Pressure card -> chart shows line graph with coloured zones
6. Toggle Day/Week/Month on chart
7. Tap Chat Bot in bottom nav -> Medi greets you
8. Tap "1" shortcut button -> Medi returns current heart rate from DB
9. Type a natural language question -> Gemini gives personalised response
10. In simulator terminal, wait for a spike tick (7th) -> red badge appears on dashboard
11. Scroll down on dashboard -> alert tile shows the warning message
12. Use manual input button -> add a reading -> dashboard refreshes
