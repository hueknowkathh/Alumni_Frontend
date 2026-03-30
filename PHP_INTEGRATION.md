# Alumni Tracer - PHP Integration Guide

## Overview
The landing page is now connected to PHP backends for:
1. Fetching announcements and jobs
2. Submitting contact form data
3. Authenticating users before viewing job details

## Required PHP Files

### Existing Endpoints (Already in alumni_php/)
- `get_announcements.php` - Fetch all announcements
- `get_job.php` - Fetch all job postings

### New Endpoint
- `submit_contact.php` - Handle contact form submissions

## Database Schema

### Create contact_messages table
```sql
CREATE TABLE contact_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'unread',
    INDEX(created_at)
);
```

## Flutter App Changes

### 1. Contact Form Submission
The contact form now posts data to `http://localhost/alumni_php/submit_contact.php`
- Email validation is performed
- Messages are stored in the database

### 2. Authentication Required for Job Details
Users must login to view full details of:
- Job postings (Announcement cards + Job cards)
- When a user clicks "Read More" or "Apply Now" without being logged in, they see a dialog prompting them to login or register

### 3. Job Data Flow
```
Landing Page (Job Cards)
    ↓
User clicks "Apply Now" or "Read More"
    ↓
Check if user is logged in
    ↓
If NO → Show login/register dialog
If YES → Show job details
```

## Configuration

### Update Database Credentials
Edit the PHP files and update these values:

**In submit_contact.php (line 60-65):**
```php
$db_host = 'localhost';    // Your database host
$db_user = 'root';         // Your database username
$db_pass = '';             // Your database password
$db_name = 'alumni_tracer'; // Your database name
```

### API Endpoints
- Base URL: `http://localhost/alumni_php/`
- Contact Submit: `POST /submit_contact.php`
- Get Announcements: `GET /get_announcements.php`
- Get Jobs: `GET /get_job.php`

## Authentication Implementation

Currently, the `_isUserLoggedIn()` method in landing_page.dart always returns `false` to demonstrate the login requirement.

To implement actual authentication:
1. Store user session/token in SharedPreferences when user logs in
2. Update `_isUserLoggedIn()` to check for stored token:

```dart
bool _isUserLoggedIn() {
  // TODO: Implement with actual authentication
  // Example:
  // final prefs = await SharedPreferences.getInstance();
  // return prefs.getString('user_token') != null;
  return false;
}
```

## Testing the Contact Form

### Manual Test:
1. Navigate to Contact section on landing page
2. Enter email and message
3. Click "SEND MESSAGE"
4. Check database for new entry in `contact_messages` table

### Expected Response:
```json
{
  "success": true,
  "message": "Thank you! Your message has been received. We will get back to you soon."
}
```

## Error Handling

The following error messages are returned:
- Missing email or message: "Missing required fields"
- Invalid email format: "Invalid email address"
- Message too short: "Message must be at least 10 characters"
- Database error: "An error occurred while processing your request"

## Notes

- All data is validated on both client (Flutter) and server (PHP) side
- CORS headers are enabled in PHP files to allow requests from any origin
- Messages are stored with a timestamp and status field for admin tracking
- Email validation uses PHP's built-in `FILTER_VALIDATE_EMAIL`

## Publishing Jobs and Announcements

When admins post jobs and announcements through your admin panel, they should be stored in your database and fetched by:
- `get_job.php` - SELECT from jobs table
- `get_announcements.php` - SELECT from announcements table

These endpoints should return JSON in this format:

### Jobs Response:
```json
{
  "jobs": [
    {
      "id": 1,
      "title": "Software Engineer",
      "company": "Tech Corp",
      "description": "Join our team...",
      "date_posted": "2026-03-29"
    }
  ]
}
```

### Announcements Response:
```json
{
  "announcements": [
    {
      "id": 1,
      "title": "Alumni Event",
      "description": "Upcoming event details...",
      "category": "Event",
      "created_at": "2026-03-29"
    }
  ]
}
```
