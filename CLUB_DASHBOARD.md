# 🏛️ Club Dashboard — Phase 2 Complete

## Features Implemented

### 2.1 Club Dashboard (`club_dashboard_screen.dart`)
- **Stats Cards**: Members, Live Events, Upcoming Events, Pending Requests
- **Quick Actions**: Create Event, Manage Members, View Requests, Edit Club Profile
- **Recent Activity**: Stream of latest events with approval status
- **Tab Navigation**: Overview | Events | Members

### 2.2 Club Events Management (CRUD) — `club_events_screen.dart` + `create_event_screen_club.dart`
- **Create**: Full form with title, description, location, start/end time pickers, image upload to Firebase Storage
- **Read**: List view with banner images, date/location display, approval badge (Live/Pending), tap to see details
- **Update**: Edit dialog pops up with all fields editable (title, description, location, times)
- **Delete**: Confirmation dialog before permanent deletion
- Image auto-uploaded via Firebase Storage

### 2.3 Club Members Management (`club_members_screen.dart`)
- **Two Tabs**: "Members" (approved) and "Requests" (pending)
- **Search Bar**: Real-time filtering by member name
- **Member List**: Shows avatar, name, "Remove" button per member
- **Request List**: Shows avatar, name, Approve ✅ and Reject ❌ buttons
- **Stats Bar**: Member count + pending request count at top
- Fetches real user data from Firestore `users` collection

### 2.4 Club Profile (`club_profile_screen.dart`)
- **Logo Upload**: Tap camera icon to pick image → uploads to Firebase Storage → updates club doc
- **Club Name**: Editable text field
- **Description**: Editable multi-line text field
- **Save Changes**: Updates Firestore `users/{clubId}` document
- **Password Change**: Re-authenticates with current password, then updates to new one
- Validation: min 6 chars for password, confirm match required

## Navigation Flow

```
Login as club admin
       ↓
ClubDashboardScreen (auto)
       ├── AppBar ───→ Edit Profile icon ──→ ClubProfileScreen
       ├── Quick Action ──→ Create Event ──→ CreateEventScreenClub
       ├── Tab: Overview ──→ Stats + Recent + Quick Actions
       ├── Tab: Events ────→ CRUD list (edit/delete buttons on each event)
       └── Tab: Members ───→ Searchable members + requests
       
Settings → Account → Club Dashboard → Club Profile link
Profile → Joined Clubs → Dashboard (for own clubs)
```

## Firestore Data Model

### users/{clubId} (role == "club")
```
name: string
description: string
email: string
logoUrl: string        // Firebase Storage URL
members: [uid, uid]    // approved student uids
memberRequests: [uid]  // pending request uids
createdAt: Timestamp
role: "club"
```

### users/{studentUid} (role == "student")
```
selectedClubs: [clubId, clubId]  // requested club ids
```

### events/{eventId}
```
title: string
description: string
location: string
imageUrl: string     // Firebase Storage URL
startingTime: Timestamp
endTime: Timestamp
clubId: string        // links to users/{clubId}
approved: boolean
status: "pending" | "live"
restricted: boolean
interestedUsers: [uid]
lovedUsers: [uid]
reactCount: number
createdAt: Timestamp
```

## How to Create a Club Account

Go to Firebase Console or use the Admin panel in the app:
1. Navigate to **Admin Home Screen** (admin role user login)
2. Use "Create New Club" form
3. Enter: Club Name, Description, Email, Password
4. Firestore creates a user document with `role: "club"`
5. Club admin can now login and access the Club Dashboard

OR create manually in Firestore:
```javascript
// In Firebase Console > Firestore > users collection > Add Document
{
  name: "Tech Club",
  email: "tech@diu.edu.bd",
  description: "Technology enthusiasts",
  logoUrl: "",
  role: "club",
  members: [],
  memberRequests: [],
  createdAt: Timestamp.now()
}
```
Then login with the email/password created.
