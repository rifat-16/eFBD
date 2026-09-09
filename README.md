# eFootballers Bangladesh Management System

A comprehensive tournament and player management system for the eFootball community in Bangladesh.

## Core Features

### 1. Profile & Identity Management (New)
- **Profile Update Requests:** Players can request changes to sensitive data (Real Name, IGN, eFootball UID, WhatsApp). 
- **Admin Approval Workflow:** Admins review change requests, seeing a side-by-side comparison of old vs. new data before approving or rejecting with a reason.
- **Pending State Protection:** Users are prevented from submitting multiple overlapping update requests.
- **Resilient Error Handling:** Technical Firebase "Internal Assertion" errors are intercepted and presented as user-friendly advice (e.g., "Database synchronization error. Please refresh.").

### 2. Community & Social Integration (New)
- **Centralized Social Links:** Admins can manage global community links (Facebook Group, Facebook Page, WhatsApp Community) from the Admin Dashboard.
- **Dynamic App Drawer:** Social buttons automatically appear in the side navigation based on active admin configuration.
- **Tournament WhatsApp Groups:** Each tournament can have a unique WhatsApp group link, visible only to verified participants to ensure a secure and focused environment.

### 3. Tournament Progression System
- **Unlimited Player Support:** Supports any number of players (200, 300, 500+).
- **Dynamic Round Naming:** Automated naming based on scale (e.g., Round of 512, Round of 256, etc.).
- **BYE System:** Handles non-power-of-two player counts automatically.
- **Group Stage Transition:** Transition from knockout rounds into group stages with automated seed assignment.
- **Alphabetical Group Naming:** Supports unlimited groups (A, B... Z, AA, AB...).

### 4. Match Management & Verification
- **Participant-Only Actions:** "WhatsApp" and "Report Score" buttons are only visible to the two players involved in the match.
- **Result Verification:** Multi-step verification with screenshot proof.
- **Automated Season Reset:** Firebase Cloud Functions reset monthly stats on the 1st of every month at 00:00 UTC.
- **Season History Archive:** Automated snapshots of Top 100 players archived before each reset.
- **Match Deadlines:** Admins can set time limits for match completion.
- **3rd Place Matches:** Automated generation for semi-final losers.

## Technical Highlights

### 1. Web-Safe Architecture
- **CORS Bypass:** Custom `HtmlElementView` implementation for Flutter Web to ensure profile pictures and match proof screenshots load regardless of strict browser policies.
- **Responsive Design:** Fully adaptive UI using `Rajdhani` for headers and `Poppins` for body text, optimized for both Mobile and Web views.

### 2. Firestore Optimization
- **Future-based Fetching:** Static views use one-time `get()` calls to minimize Firestore Read costs.
- **Memory Caching:** 10-minute TTL cache in `DatabaseService` for player profiles.
- **Failsafe Filtering:** Admin views use client-side filtering and in-memory sorting to remain functional even without complex database indexes.

## Troubleshooting (Flutter Web)

### Screenshot Loading (CORS)
We have implemented a **Web-Safe Image Loading** system that automatically bypasses most browser CORS restrictions.

1. **Direct View:** Screenshots load automatically inside the app.
2. **Interactive View:** Tap any screenshot to view full-screen with zoom.
3. **Fallback:** "Open in New Tab" provided for extremely strict browser environments.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get`.
3. Configure Firebase using `flutterfire configure`.
4. Deploy Firestore Rules and Cloud Functions.
5. Run the app: `flutter run -d chrome` or `flutter run`.
