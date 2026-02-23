# App Store Connect - Review Response

**Guideline 2.1 - Information Needed (App Tracking Transparency)**

Dear App Review Team,

Thank you for your feedback. We have investigated the issue regarding the App Tracking Transparency (ATT) permission request not appearing on iPadOS.

We found that the `requestTrackingAuthorization` method was being called slightly too early in the app's lifecycle (before the UI window fully transitioned to the "Active" state), which caused the iOS system to suppress the prompt. 

We have resolved this in the latest build. The ATT request is now lifecycle-gated and shown only after the app reaches the active (`resumed`) state, instead of using a fixed startup delay. 

**Where to find it:**
The App Tracking Transparency permission request will now reliably appear on the first launch of the app, immediately after the initial loading screen completes. This occurs strictly before any analytics data is collected or transmitted.

We also moved ad SDK startup and ad preloading to run only after ATT authorization is resolved, and kept `FIREBASE_ANALYTICS_COLLECTION_ENABLED = false` until consent handling completes. We have reviewed the documentation and confirmed `NSUserTrackingUsageDescription` is correctly implemented.

Please review the newly submitted build. Thank you for your continued guidance!

Best regards,
PetTomo Team
