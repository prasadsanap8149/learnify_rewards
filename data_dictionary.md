# Firestore Data Dictionary (summary)

This file summarizes the primary collections used by the Learn & Earn app.

- `/users/{uid}`: user profile, roles, encrypted sensitive fields, stats, device info.
- `/activities/{activityId}`: activity content (math/word/puzzle), difficulty, ageGroup.
- `/userActivityState/{uid}`: per-user locks, lastAnswered, streaks, performance.
- `/lpEvents/{uid}/{eventId}`: Learning Point events; points awarded for correct answers, streaks.
- `/adEvents/{uid}/{eventId}`: raw ad impressions/engagement records (client-provisional).
- `/aerEvents/{uid}/{eventId}`: validated Ad Engagement Rewards (server-created after verification).
- `/withdrawals/{uid}/{withdrawId}`: withdrawal requests and payout status.
- `/config/{doc}`: Remote-config-like settings stored in Firestore for live tuning.
- `/auditLogs/{id}`: immutable audit trail entries written by server-side code.

Keep sensitive writes (AER issuance, final LP tallies, audit logs) server-authoritative via Cloud Functions.
