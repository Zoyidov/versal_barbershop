# Deployment guide

## 0. Security — do this first

You pasted a live devsms.uz API token in chat. Treat it as compromised:
rotate it in your devsms.uz dashboard before going live, then store the
new one only via Secret Manager (step 3 below). It must never be hardcoded
into `functions/src/*.ts` or, especially, into any Flutter/Dart file —
anything shipped in the app binary can be extracted by a user.

## 1. One-time GCP setup

```bash
firebase login
firebase use versalbarbershop

# Cloud Tasks powers the exact-time SMS scheduling and needs to be enabled once.
gcloud services enable cloudtasks.googleapis.com --project versalbarbershop

# Create the queue the backend enqueues reminder tasks into.
gcloud tasks queues create sms-reminders --location=us-central1 --project versalbarbershop

# Let the Functions runtime service account create/delete Cloud Tasks.
gcloud projects add-iam-policy-binding versalbarbershop \
  --member="serviceAccount:versalbarbershop@appspot.gserviceaccount.com" \
  --role="roles/cloudtasks.enqueuer"
```

(No `gcloud` locally? Do the same three things from the Cloud Console:
enable "Cloud Tasks API", create a queue named `sms-reminders` in
`us-central1`, then grant the App Engine default service account the
"Cloud Tasks Enqueuer" role under IAM.)

## 2. Install functions dependencies

```bash
cd functions
npm install     # already done in this session
npm run build   # already verified clean in this session
```

## 3. Set secrets

```bash
firebase functions:secrets:set TASK_QUEUE_SECRET
# → paste any long random string; this authenticates Cloud Tasks -> your HTTP endpoint

firebase functions:secrets:set DEVSMS_API_TOKEN
# → paste your (rotated) devsms.uz API token
```

## 4. Wire up the real devsms.uz endpoint

Open `functions/src/smsGateway.ts`. Replace the `default` value of
`devsmsApiUrl` with the real endpoint, and adjust the `fetch(...)` call's
body/header/response handling to match devsms.uz's actual contract once
you have their docs. Everything else in the backend is isolated from this
file and needs no changes.

## 5. Deploy

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## 6. Create your first barber login

```bash
cd functions
node scripts/createBarber.js "+998901234567" "SomeStrongPassword" "Your Name"
```

## 7. Run the app

```bash
flutter pub get   # already done in this session
flutter run
```

## Changing the reminder window later

Sign in → Settings tab → change "Minutes before appointment" → Save. This
writes `settings/global.reminderWindowMinutes`, which `onGlobalSettingsUpdated`
picks up immediately and uses to reschedule every pending, not-yet-sent
reminder — no redeploy needed.
