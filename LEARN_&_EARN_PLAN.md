Awesome brief. Here’s a complete, end-to-end development plan you can hand to engineering, design, ops, and compliance. I’ve filled in missing details (RBAC, Firestore schema, security rules, ad/earning logic, payouts, anti-fraud, privacy, and Play policy guardrails) and shaped it so you can build, ship, and pass review.

---

# Product vision & guardrails

**Goal:** A “learn & earn” app where users practice bite-sized skills (math/word/puzzles). Ads help fund the experience. Users see *transparent, day-wise earnings estimates* and can withdraw monthly above a threshold.

**Critical guardrails (must-haves to pass stores & avoid account risk):**

* **Do not compensate users with real-world money *for viewing or clicking ads*.** Google considers incentivized ad traffic a policy violation. “Rewarded” formats are allowed only for *in-app* benefits, not cash equivalents. Plan your earnings model so cash payouts are **not** tied to ad views or impressions (details below). ([Google Help][1])
* If your **target audience includes children**, you must comply with **Google Play Families** (age gating, Families-certified ad SDKs, limited formats, stricter data handling). If you want to keep the product “for all ages,” implement a robust **age-screen** with a separate “under-13” experience (no cash, limited ads), or **target 13+** to reduce compliance burden. ([Google Help][2])
* Follow **Play Developer Program Policies** (User Data, Ads, Deceptive Behavior, Payments) and watch ongoing deadlines. ([Google Help][3])
* India market: plan for **DPDP Act** (consent, purpose limitation, notices, access/erasure) and watch tax rules if your model crosses into **“online gaming winnings”** territory (TDS 30% under 194BA/115BBJ). We keep your core model outside that zone (no cash for game outcomes or ad views). If you ever move toward cash “winnings,” add KYC & tax withholding workflows. ([MeitY][4], [BDO India][5], [Figment][6])

---

# Tech stack

* **Client:** Flutter (Dart), Gradle build flavors (dev/stage/prod), Android first (iOS later).
* **Backend:** Firebase Auth, Firestore, Cloud Functions (Node.js 20), Cloud Storage, Cloud Scheduler, Cloud Tasks, Cloud KMS.
* **Analytics/Crash:** Firebase Analytics, Crashlytics, Performance Monitoring.
* **Ads:** Google Mobile Ads SDK (banner, interstitial, rewarded, rewarded-interstitial), mediation optional later.
* **Secrets & Config:** Remote Config + Firestore `/config` docs + build-time `.env` per flavor.
* **Security:** AES-256 client-side envelope encryption for sensitive fields; Firestore Security Rules v2; App Check; reCAPTCHA/Play Integrity.

---

# Roles & RBAC

**Roles:**

* **User** – uses activities, sees estimates, requests withdrawals, manages profile.
* **Moderator** – reviews suspicious activity flags, handles support tickets.
* **Finance Ops** – reviews payout batch, marks payouts settled, edits rates/fees (with 2-person approval).
* **Admin** – all above + user actions (deactivate/reactivate), config management, read audit logs.
* **Super Admin** – IAM-level ownership, break-glass.

**RBAC matrix (high-level):**

* Content/activities: User (read), Admin (CRUD).
* Rates/fees/cooldowns: Finance Ops (propose/update), Admin (approve/apply).
* Payouts: Finance Ops (create batch/mark paid), Admin (override), User (request/see statements).
* Users: User (self), Admin (deactivate/reactivate, role change), Moderator (flag/unflag).
* Audit logs: Admin/Super Admin (read); immutable to everyone else.

---

# User journeys

1. **Onboarding & auth**

* Google Sign-In → create user doc with role=`user`, status=`active`, createdOn, referralCode (optional), ageGroup (13-17 / 18+), country.
* Post-onboarding profile form (mobile, address, PIN/ZIP, UPI ID or PayPal ID). Sensitive fields stored encrypted.

2. **Choose activity → answer → ad gating**

* User picks **Math / Word / Puzzle** → sub-type (e.g., Math→random mix of + − × ÷ √).
* Show question. **Two lifelines** (50/50, reveal digit/letter, or extra time).
* If **correct** → proceed to **ad-eligible state** → (show the selected ad *format*, not a promise of earnings for viewing).
* If **incorrect or skipped** → back to activities; do **not** show ad.

3. **Cooling period & lock**

* After a successful ad show (not tied to earnings), **lock that activity** for X seconds (Remote Config/Firestore). Cooldown applies app-wide.

4. **Earnings model (policy-safe design)**

* **Learning Points (LP):** Users earn LP for *completing activities correctly* (and streaks), **not** for ad views. Ads are ancillary.
* **Cash Eligibility Pool (CEP):** Platform allocates a daily/weekly **budget pool** (from ad revenue, sponsors, or subscription income). Users’ **share** of the pool is proportional to LP (with fraud and fairness constraints).
* End of day, compute **Estimated Earnings = Pool \* (User LP / Total LP)** with **caps/mins** from `/config`. This keeps payouts *decoupled from ad impressions/clicks*, aligning with AdMob policies. ([Google Help][1])

5. **Statements & payout**

* Daily statement: LP earned, share %, estimated earnings, adjustments, platform fees.
* Month end: auto-settle if ≥ threshold; Finance Ops performs manual payout (initial releases) then marks transaction settled; user sees receipt & breakdown.

---

# Firestore data model (first pass)

```
/users/{uid}
  displayName, email, photoUrl
  role: "user"|"moderator"|"finance"|"admin"|"superadmin"
  status: "active"|"deactivated"|"suspended"
  ageGroup: "13-17"|"18+"
  profileEnc: { mobileEnc, addressEnc, pinEnc, upiEnc, paypalEnc }   // AES-256
  stats: { totalLP, totalEarnings, totalWithdrawals, remaining }
  adStats: { impressionsByFormat: {banner: n, interstitial: n, rewarded: n, rewardedInterstitial: n}, lastAdAt }
  flags: { suspicious: bool, reasons: [..] }
  createdAt, updatedAt

/activities/{activityId}
  type: "math"|"word"|"puzzle"
  subType: "add"|"mix"|...
  difficulty: "easy"|"med"|"hard"
  content: {...}                       // questions, options
  validFrom, validTo, active

/userActivityState/{uid}
  locks: { math:{until:ts}, word:{until:ts}, puzzle:{until:ts} }
  lastAnswered: { activityId, correct:bool, at:ts }

/lpEvents/{uid}/{eventId}
  lp: int, reason: "correct_answer"|"streak"|"bonus"
  activityRef, createdAt

/adEvents/{uid}/{eventId}
  format: "banner"|"interstitial"|"rewarded"|"rewardedInterstitial"
  adNetwork: "admob"
  impression: bool, clicked: bool
  adUnitId, at: ts                                   // do not use for cash calc

/earningDaily/{uid}/{yyyyMMdd}
  lpTotal
  userSharePct
  grossEstimate
  platformFee
  netEstimate
  breakdown: { poolId, rulesVersion, notes }
  computedAt

/withdrawals/{uid}/{withdrawId}
  month: "2025-08"
  amount, platformFee, method:"upi"|"paypal"
  status: "requested"|"approved"|"settled"|"rejected"
  settledAt, txRef, notes

/config/global
  cooldownSecondsByActivity: {math:5,word:5,puzzle:5}
  dailyPoolUSD
  platformFeePct
  withdrawThresholdUSD: 50
  monthEndSettlementDay: 1
  lifelinesPerSession: 2
  allowedCountries: ["IN","..."]
  minAge: 13
  ads: { bannersAlwaysOn:true, interstitialEnabled:true, rewardedEnabled:true }

/auditLogs/{id}
  actorUid, action, targetRef, before, after, at
```

---

# Firebase Security Rules (sketch)

> You’ll tune these as code evolves; keep rules versioned and tested with the emulator.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function isSignedIn() { return request.auth != null; }
    function uid() { return request.auth.uid; }
    function hasRole(r) { return isSignedIn() && r in request.auth.token.roles; }

    // Users can read themselves; write only to their own allowed fields
    match /users/{userId} {
      allow read: if isSignedIn() && userId == uid();
      allow update: if isSignedIn() && userId == uid()
        && !('role' in request.resource.data)  // cannot escalate
        && !('status' in request.resource.data);
      allow create: if isSignedIn() && userId == uid();
      allow delete: if false;
    }

    // Admin-only collections
    match /config/{doc} {
      allow read: if isSignedIn();
      allow write: if hasRole('admin') || hasRole('finance');
    }

    match /auditLogs/{id} {
      allow read: if hasRole('admin') || hasRole('superadmin');
      allow write: if false; // server only via Cloud Functions
    }

    // Events: user can create their own entries; server validates via Functions
    match /lpEvents/{userId}/{eventId} {
      allow read: if isSignedIn() && userId == uid();
      allow create: if isSignedIn() && userId == uid();
      allow update, delete: if false;
    }

    match /adEvents/{userId}/{eventId} {
      allow read: if isSignedIn() && userId == uid();
      allow create: if isSignedIn() && userId == uid();
      allow update, delete: if false;
    }

    match /earningDaily/{userId}/{date} {
      allow read: if isSignedIn() && userId == uid();
      allow write: if hasRole('admin') || hasRole('finance'); // computed server-side
    }

    match /withdrawals/{userId}/{wid} {
      allow read: if isSignedIn() && userId == uid();
      allow create: if isSignedIn() && userId == uid();
      allow update: if hasRole('finance') || hasRole('admin'); // status updates
      allow delete: if false;
    }

    match /activities/{activityId} {
      allow read: if isSignedIn();
      allow write: if hasRole('admin');
    }

    match /userActivityState/{userId} {
      allow read, write: if isSignedIn() && userId == uid();
    }
  }
}
```

(Use Firebase’s official rules guides to refine and test with the emulator/CI.) ([Firebase][7])

---

# Client architecture (Flutter)

* **Project structure**

  * `lib/`

    * `main.dart` (flavors: dev/stage/prod)
    * `core/` (constants, env, helpers, encryption utils)
    * `routes/` (GoRouter or Navigator 2.0)
    * `data/` (repos for auth, users, activities, earnings, ads)
    * `domain/` (entities, use-cases)
    * `ui/` (themes, widgets, screens)
    * `state/` (Riverpod/Bloc)
* **Themes:** Light/Dark + High-contrast; per-user setting in `/users`.
* **Encryption:**

  * Generate per-device key (Android Keystore) to wrap a random data key.
  * Use AES-256-GCM for `profileEnc` fields.
  * Rotate wrapped keys on logout or device change (store encrypted DEK in Firestore under user, or derive using passphrase + KMS).
* **Constants/helpers/routes:**

  * `AppEnv` for flavor; `BuildConfig` flags; `AppRoutes`; `Validators`; `Formatters`.
* **Ads integration:**

  * Banner pinned bottom on every screen (respect layout & safe areas).
  * Other formats shown **only** after correct answer → “You’re eligible for a bonus” type message (no cash mention).
  * Separate ad units per flavor; register test devices; frequency capping; handle consent (UMP SDK if serving to EEA).

---

# Server architecture (Cloud Functions)

* **Daily earnings job** (scheduled 00:30 local):

  * Read total LP by day; compute `userSharePct`, `grossEstimate`, `platformFee`, `netEstimate` → write `/earningDaily/{uid}/{date}` and aggregate to user totals.
* **Monthly settlement job** (1st day, 02:00):

  * Check users with `remaining >= threshold`, create `/withdrawals` doc with status `approved`; Finance Ops exports batch CSV, pays (UPI/PayPal) manually, then sets status `settled` + `txRef`.
* **Fraud & integrity worker:**

  * Velocity checks, device/app integrity (Play Integrity verdict), VPN/proxy heuristic, duplicate device IDs, anomalous ad event ratios → write to `/users.flags`.
* **Audit logger:**

  * Wrap privileged writes (config, user status, payouts) and write immutable `/auditLogs`.

---

# Ads flow logic (policy-safe)

```dart
// After correct answer:
if (cooldownOver(activityType)) {
  // choose format from config & user segment
  final format = pickAdFormatForUser(user, activityType);
  final shown = await tryShowAd(format);
  await logAdEvent(uid, format, shown);
  if (shown) {
    lockActivity(activityType, cooldownSecondsFromConfig); // applies globally
  }
}
// No ad? user still earns LP for the correct answer.
```

**Important:** LP and earnings are **independent** from `adEvents`. Ads improve monetization, but **LP comes from learning progress**, streaks, difficulty, and quiz outcomes.

---

# Earnings, fees, and thresholds

* **Base values from DB (`/config/global`):** `dailyPoolUSD`, `platformFeePct`, `withdrawThresholdUSD`.
* **End-of-day calculation (server only):**

  * `userSharePct = userLP / totalLPAllUsers` (bounded by min/max share to avoid whales).
  * `grossEstimate = dailyPoolUSD * userSharePct`
  * `platformFee = grossEstimate * platformFeePct`
  * `netEstimate = grossEstimate - platformFee`
* **Statements:** Show breakdown (LP by activity, pool ID, fee, adjustments, notes).
* **History:** Daily and monthly rollups; “Total Earnings”, “Total Withdrawals”, “Remaining”.

---

# Anti-fraud & abuse

* Device fingerprint (non-PII app signals), Play Integrity verdict, emulator detection, rooted device heuristic.
* IP risk checks and geo anomalies.
* Cooldowns & rate limits: answers/minute, mistakes vs correct ratio, ad-show eligibility ratio.
* Soft blocks (cooldowns) → hard blocks (temporary suspension) → deactivation (admin).
* Auto-rules + human review (Moderator role).
* Audit trail for all admin actions.

---

# Edge cases to cover

* Offline answers queuing → reconcile on sync (no duplicate LP).
* Ad load failures (fallback to another ad format or skip silently).
* Age gate failures (unknown age → treat as child: limit ads, no payouts).
* Multiple devices per user (locks & cooldown synced in `/userActivityState`).
* Profile encryption key rotation; lost device.
* Payout method missing/invalid (UPI VPA validation, PayPal country restrictions).
* Suspicious activity: auto-email for re-verification; account deactivation flow & “email us to reactivate” screen.
* Data export & delete (DPDP/“download my data”, “delete my account”).

---

# Privacy, security & compliance

* **Client & server encryption:** AES-256-GCM for sensitive PII; envelope keys via Android Keystore + Cloud KMS.
* **Firebase Rules:** strict least-privilege; all sensitive writes via Functions; App Check enabled; HTTP Callable Functions enforce ID token, roles.
* **DPDP Act (India):** clear consent text, purpose limitation, data minimization, retention schedule, breach notification playbook, parental consent for minors where applicable, honor access/erasure. Watch evolving consent-manager norms. ([MeitY][4], [DLA Piper Data Protection][8], [Global Investigations Review][9])
* **Google Play declarations:** target audience & content, data safety form (SDK data sharing), ads disclosure, financial features if any. Track policy updates. ([Google Help][10])
* **Ad policies:** no incentivized ad views/clicks for cash; use rewarded only for in-app benefits; if children could use the app, serve ads only via Families-certified SDKs and ad formats, or age-gate to 13+. ([Google Help][1])
* **Tax (if you ever pay “winnings”):** Sections **115BBJ/194BA** require 30% TDS on net winnings; consult tax counsel before any gameplay-based cash. Our proposed LP-based pool allocation (not tied to ads or single “game win”) avoids the “winnings” construct, but get legal review before launch messaging. ([BDO India][5], [Figment][6])

---

# Admin console (web or Flutter desktop)

* **Dashboards:** user growth, LP distribution, ad fill rates (aggregated), pool utilization, suspicious events.
* **Users:** search, view history, deactivate/reactivate, role changes (with 2-person approval for admin/finance), notes.
* **Finance:** edit `/config` (pool, fees, thresholds), preview daily allocation, create/export payout batch, mark settlements, receipts.
* **Moderation:** review flags, actions log.
* **Audit:** immutable log viewer with filters.

---

# Ads inventory & placements

* **Banner:** persistent at bottom of every screen (as requested). Ensure it doesn’t obstruct interactive elements.
* **Interstitial / Rewarded / Rewarded-Interstitial:** after correct answers or at activity transitions (respect frequency caps & consent).
* **Consent (UMP):** if EEA users, request and store consent string before personalized ads.
* **Test/dev:** use test ad unit IDs per flavor and register test devices; never ship with real units in dev builds.

> **Important:** Even though your brief asked that “if the user answers correctly, show selected ad,” keep the UX copy free of any *money* phrasing (“watch ad to earn cash”). Ads are shown because the user progressed, *not* as a quid-pro-quo for money. ([Google Help][1])

---

# Build, config, and release

* **Flavors & env:** `dev`, `staging`, `prod` (separate Firebase projects, AdMob apps, Remote Config namespaces).
* **Files:**

  * `lib/core/constants.dart`, `lib/core/env.dart`
  * `android/app/proguard-rules.pro` (**R8/ProGuard**, correct spelling)
  * `firebase.json`, `firestore.rules`, `storage.rules`
* **CI/CD:**

  * Lint (Dart/Flutter), unit tests, widget tests
  * Firebase Emulator tests for rules
  * Play Console internal testing → closed testing → production staged rollout (10% → 50% → 100%)
* **Privacy Policy + Terms:** public URL; explain data collected, purposes, retention, contact, children’s policy, payout terms, account deactivation/recovery.
* **Store listing:** target audience, data safety form, ads label, screenshots (no misleading earnings claims).

---

# QA checklist

* Age gate & child experience (if “all ages”): ad formats limited, data handling verified.
* Ad flow: frequency caps, fail-safe if no fill, test device registrations.
* Cooldown locks synced across devices.
* Encryption tests: profile fields unreadable in plain; rotation works.
* Fraud: emulator/root detection; VPN heuristic; Play Integrity token verified.
* Payout math correctness (rounding, caps, fee calculations).
* Daily/Monthly jobs idempotence (retry safe).
* Accessibility: large fonts/high contrast; talkback labels.
* Performance: 40% faster transaction/entry target for forms; cold start < 2s on mid devices.

---

# Delivery milestones (8–10 weeks, Android)

1. **Week 1–2 – Foundations**

   * Project scaffolding, themes, routing, auth (Google), profile encryption, RBAC tokens.
   * Firestore schema + initial rules; emulator tests.

2. **Week 3–4 – Activities & Ads**

   * Math/Word/Puzzle engines, lifelines, cooldown logic; ad placements & eligibility; ad logging.

3. **Week 5 – Earnings Engine**

   * LP accrual; daily pool computation (Functions); daily statements; history screens.

4. **Week 6 – Admin & Finance**

   * Admin console MVP; config editing; payout batch flow; audit logging.

5. **Week 7 – Privacy & Compliance**

   * Data Safety form prep, Privacy Policy page, UMP consent, age-gate path; anti-fraud v1.

6. **Week 8 – QA & Release**

   * Test plans, closed testing, staged rollout; monitoring dashboards; incident runbooks.

---

# Open decisions

* **Audience strategy:** “13+” with clear age gate (recommended) vs “all ages” with Families compliance overhead. ([Google Help][2])
* **Funding the pool:** share of monthly budget (sponsors/subscriptions) vs revenue allocation (never 1:1 per ad impression).
* **Payout rails:** start with **manual UPI/PayPal** by Finance Ops; integrate automated payouts only after policy/legal green-light.

---

# Sample Flutter bits (just to de-risk)

**Route guard for RBAC:**

```dart
bool canAccess(String role, Set<String> allowed) => allowed.contains(role);
```

**Activity cooldown check:**

```dart
bool cooldownOver(DateTime? until) => until == null || DateTime.now().isAfter(until);
```

**AES-GCM wrapper (pseudo-interface):**

```dart
final enc = await Encryption.forUser(uid); // loads wrapped DEK, unwraps via keystore
final mobileEnc = enc.encryptString(mobile);
```

---

# One more thing: what to put on the “How payouts work” screen

* How LP works and which actions earn LP
* Daily pool explained (variable, not guaranteed; not tied to ad views/clicks)
* Fees, thresholds, monthly settlement timeline
* Fraud policy (what triggers review/suspension)
* Country restrictions & tax notes (users responsible for local tax compliance; platform may request KYC if required)

---

If you want, I can turn this into:

* a **Firestore security rules file** ready to paste,
* a **Flutter folder scaffold** with providers, routes, and example widgets,
* and a **data dictionary** + **Remote Config defaults** JSON.

[1]: https://support.google.com/admob/answer/6128543?hl=en&utm_source=chatgpt.com "AdMob policies and restrictions - Google Help"
[2]: https://support.google.com/googleplay/android-developer/answer/9867159?hl=en&utm_source=chatgpt.com "Manage target audience and app content settings - Play Console Help"
[3]: https://support.google.com/googleplay/android-developer/answer/16329168?utm_source=chatgpt.com "Developer Program Policy - Play Console Help - Google Help"
[4]: https://www.meity.gov.in/static/uploads/2024/06/2bf1f0e9f04e6fb4f8fef35e82c42aa5.pdf?utm_source=chatgpt.com "[PDF] THE DIGITAL PERSONAL DATA PROTECTION ACT, 2023 (NO. 22 ..."
[5]: https://www.bdo.in/en-gb/insights/alerts-updates/direct-tax-alert-cbdt-notifies-rules-and-issues-guidelines-on-winnings-from-online-games?utm_source=chatgpt.com "Direct Tax Alert: CBDT Notifies Rules & Guidelines on ... - BDO"
[6]: https://figmentglobal.com/tds-on-winnings-from-online-gaming-section-194ba/?utm_source=chatgpt.com "TDS on Winnings from Online Gaming (Section 194BA)"
[7]: https://firebase.google.com/docs/firestore/security/get-started?utm_source=chatgpt.com "Get started with Cloud Firestore Security Rules - Firebase - Google"
[8]: https://www.dlapiperdataprotection.com/?c=IN&t=law&utm_source=chatgpt.com "Data protection laws in India"
[9]: https://globalinvestigationsreview.com/guide/the-guide-cyber-investigations/fourth-edition/article/india-examining-the-digital-personal-data-protection-act-government-publishes-draft-rules-ahead-of-implementation?utm_source=chatgpt.com "India: examining the Digital Personal Data Protection Act as ..."
[10]: https://support.google.com/googleplay/android-developer/announcements/13412212?hl=en&utm_source=chatgpt.com "Announcements - Play Console Help - Google Help"
