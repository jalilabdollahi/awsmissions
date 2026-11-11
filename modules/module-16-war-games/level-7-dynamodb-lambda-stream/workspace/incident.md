# ORBIT-1893 - Leaderboard stopped moving after the table migration

Orbit Fitness, "Challenges" squad.

## What users see
The weekly step-challenge leaderboard has shown the same numbers since Tuesday
night. Workouts are being logged (the activity feed is fine), but nobody's
score changes.

## How the leaderboard is fed
    app --PutItem--> DynamoDB orbit-workouts  (workoutId, userId, points)
                         |  DynamoDB Stream (new images)
                         v
                     Lambda orbit-leaderboard-updater
                         |  UpdateItem  ADD score :points
                         v
                  DynamoDB orbit-leaderboard   (key: userId)

## Tuesday night's change log
- 21:40 "Cost trim": streams switched off on `orbit-workouts` because "nothing
  was reading them" (the Lambda trigger was).
- 22:05 Streams switched back on during rollback... on a different table
  setting, then someone went home.
- 22:30 Function config cleaned up; the leaderboard table was renamed in the
  design doc from `orbit-leaderboards` (plural) to `orbit-leaderboard`.
- The updater's role was rewritten from a template by the security team.

## Not negotiable
The workouts table keeps its data. Do not recreate it or the leaderboard
table; the scores are the product.
