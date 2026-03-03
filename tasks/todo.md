# TODO

## Plan
- [x] Add a Supabase migration to mark user `1964870f-c0e9-4c72-8c54-6360a6dd605d` as admin in auth metadata.
- [x] Update `memory-bank/progress.md` with this metadata-admin change.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Add verification results in the review section.

## Review
- [x] Implemented and verified.
- Added migration `supabase/migrations/20260304001000_set_user_admin_metadata.sql` to set `auth.users.raw_app_meta_data` admin keys for user `1964870f-c0e9-4c72-8c54-6360a6dd605d`.
- Updated `memory-bank/progress.md` with the metadata-admin change entry.
- Verification: `flutter analyze` passed with no issues.
- Verification: `flutter test` passed; integration test `test/feed_flow_integration_test.dart` was skipped because required Supabase env vars are not set.
