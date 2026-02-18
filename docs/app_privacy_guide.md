# App Store Connect: App Privacy Guide

Based on your current codebase (`1.0.0+12`), here is the guide to filling out the **App Privacy** section in App Store Connect.

## 1. Data Collection

**"Do you or your third-party partners collect data from this app?"**
> **Yes**

**"Do you or your third-party partners process any data collected... for tracking purposes?"**
> **Yes** (Because you use AdMob and request `NSUserTrackingUsageDescription` permission).

---

## 2. Data Types

Select the following data types:

### 👤 Contact Info
- [x] **Name** (Supabase Auth profiles)
- [x] **Email Address** (Supabase Auth)

### 🆔 Identifiers
- [x] **User ID** (Supabase, Firebase, RevenueCat)
- [x] **Device ID** (AdMob, Firebase, RevenueCat)

### 💶 Financial Info
- [x] **Purchase History** (RevenueCat - In-App Purchases)

### 🖼️ User Content
- [x] **Photos or Videos** (Feed / Pet Photos)
- [x] **Other User Content** (Chat messages, if stored/analyzed)

### 📊 Usage Data
- [x] **Product Interaction** (Firebase Analytics - button taps, screen views)
- [x] **Advertising Data** (AdMob - ad impressions/clicks)

### 🛠️ Diagnostics
- [x] **Crash Data** (Firebase Crashlytics)
- [x] **Performance Data** (Crashlytics/Firebase often collect launch times etc.)

---

## 3. Data Usage & Linking

For each selected data type, you will need to specify **how it is used** and **if it is linked to the user**.

| Data Type | Usage Purposes | Linked to User? | Tracking? |
| :--- | :--- | :--- | :--- |
| **Name** | App Functionality, Personalization | **Yes** | No |
| **Email Address** | App Functionality, Account Management | **Yes** | No |
| **User ID** | App Functionality, Analytics, Customization | **Yes** | **Yes** (if used for cross-app tracking) |
| **Device ID** | Third-Party Advertising, Analytics | **Yes** | **Yes** |
| **Purchase History** | App Functionality, Analytics | **Yes** | No |
| **Photos/Videos** | App Functionality | **Yes** | No |
| **Product Interaction**| Analytics, App Functionality | **Yes** | No |
| **Advertising Data** | Third-Party Advertising | **Yes** | **Yes** |
| **Crash Data** | Diagnostics | **Yes** (firebase links it) | No |
| **Performance Data** | Diagnostics | **Yes** | No |

### 🚨 Crucial: Tracking
Since you use **AdMob** and request the **ATT permission**:
- You MUST declare that **Device ID** and **Advertising Data** are used for **Tracking**.
- "Tracking" in Apple's definition means linking data collected from your app with data from other companies' apps for advertising or data broker purposes. AdMob does this.

## 4. Privacy Policy URL
Ensure your privacy policy (e.g., `https://pet-app-702be.web.app/privacy_policy.html`) discloses:
1.  Use of **Google AdMob** and **Firebase**.
2.  Use of **RevenueCat**.
3.  User's right to delete data (which you handle via Supabase).

---
*Note: This guide is based on your `pubspec.yaml` dependencies (AdMob, Firebase, RevenueCat, Supabase).*
