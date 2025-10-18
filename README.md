This project is a multi-tenant, role-based attendance management system**.

* **Multi-tenant**: This means the application is designed to serve multiple "institutes" (like different coaching classes) from a single backend and database. The `institute_id` in your database tables is the key to keeping data separate and secure for each institute.
* **Role-Based**: The system has two main user roles with different permissions:
    1.  **Owner (Admin)**: Manages the institute, teachers, and can view/mark *teacher* attendance.
    2.  **Teacher**: Manages *student* attendance for their classes and can view their *own* attendance history.

## 1. Project Architecture

The system is built on a classic client-server model:

1.  **Flutter Frontend (Client)**:
    * This is the mobile app that teachers and owners use.
    * It handles all user interface (UI) and user experience (UX).
    * It **does not** contain any sensitive data.
    * It uses the `http` package to send API requests (like `GET`, `POST`, `PUT`, `DELETE`) to your backend for all actions.
    * It manages its own state (e.g., loading spinners, lists of students) based on the server's responses.

2.  **Node.js/Express Backend (Server)**:
    * This is the "brain" of your operation. It runs on a server.
    * **Receives** requests from the Flutter app (e.g., `POST /api/attendance/student`).
    * **Validates** the request (e.g., "Is this user a real teacher?", "Is the date valid?").
    * **Executes** business logic (e.g., fetching, creating, or updating data in the database).
    * **Sends** a JSON response back to the Flutter app (e.g., `{"message": "Success"}` or an error).

3.  **PostgreSQL (Database)**:
    * This is the "memory" of your application.
    * It only stores and retrieves data. It never talks directly to the Flutter app.
    * The Node.js server is the *only* thing that can access the database, which is a critical security feature.

**Simple Data Flow:**
(Flutter App) ➡️ (Node.js API Request) ➡️ (Node.js Logic) ➡️ (PostgreSQL Database) ➡️ (Node.js Response) ➡️ (Flutter App UI Update)

---

## 2. Authentication & Authorization Flow

This is how you protect your data and control who sees what.

* **Authentication (Login)**:
    1.  A user (owner or teacher) enters their credentials in the Flutter app.
    2.  The app sends these to a (presumed) `/api/auth/login` endpoint on your server.
    3.  The server checks the credentials against the database.
    4.  If correct, the server generates a **JWT (JSON Web Token)**. This token is a long, an-crypted string containing user info (like `userId`, `instituteId`, and `role`).
    5.  The server sends this JWT back to the Flutter app.
    6.  The Flutter app saves this token securely (like in `shared_preferences`).

* **Authorization (Making Requests)**:
    1.  Now, for *every future API call* (like fetching students), the Flutter app includes this JWT in the `Authorization` header.
    2.  Your `authMiddleware` (like `isTeacher` or `isOwner`) on the backend intercepts *every* request.
    3.  It reads the JWT from the header and verifies it.
    4.  If valid, it extracts the user's data (e.g., `req.teacher = { id: '...', role: 'teacher' }`) and passes the request to the next function (the controller).
    5.  If the token is missing, invalid, or the user's role doesn't have permission (e.g., a teacher trying to access an owner route), the middleware immediately sends a `401 Unauthorized` or `403 Forbidden` error, and the request is blocked.

---

## 3. Core Functionality: "Mark Student Attendance" (Full-Stack Flow)

Here is a step-by-step walkthrough of the main feature you're building:

1.  **User Opens Page (Flutter)**:
    * The `MarkStudentAttendancePage` opens.
    * `initState()` is called.
    * The UI shows a loading spinner (`_isLoading = true`).
    * The `ApiService.getStudents()` and `ApiService.getAttendanceForDate()` functions are called simultaneously.

2.  **API Call 1: Get Students (Backend)**:
    * Flutter sends a `GET /api/students` request with the teacher's auth token.
    * Backend `isTeacher` middleware verifies the token.
    * `studentController.getAllStudents` runs.
    * It fetches all students for that teacher's `institute_id` from the `Students` table.
    * It returns a JSON array of student objects to the app.

3.  **API Call 2: Get Today's Attendance (Backend)**:
    * Flutter sends a `GET /api/attendance/student?date=...` request.
    * Backend `isTeacher` middleware verifies the token.
    * `attendanceController.getStudentAttendanceByDate` runs.
    * It fetches records from `StudentAttendance` for that date and institute.
    * It returns a JSON *map* (e.g., `{"studentId1": "present", "studentId2": "leave"}`) to the app.

4.  **UI Renders (Flutter)**:
    * Both API calls complete. `_isLoading` becomes `false`.
    * The `_allStudents` list is filled.
    * The `_todayAttendance` map is populated. If a student had no record, your code smartly defaults them to `absent`.
    * The student list appears on the screen, with the `ToggleButtons` correctly showing "present", "absent", or "leave" for each student based on the data.

5.  **Teacher Marks Attendance (Flutter)**:
    * The teacher taps the "Present" button for a student.
    * `setState()` is called.
    * The `_todayAttendance` map is updated *locally* (e.g., `_todayAttendance['studentId5'] = AttendanceStatus.present`).
    * The UI of that one button changes color. This is very fast because it doesn't involve the network.

6.  **Teacher Saves (Flutter)**:
    * The teacher taps the "Save Attendance" `FloatingActionButton`.
    * A loading dialog appears.
    * `ApiService.saveAttendance()` is called. It converts the `_todayAttendance` map into a list of objects and sends it as JSON in the body of a `POST /api/attendance/student` request.

7.  **Data Saved (Backend)**:
    * Backend `isTeacher` middleware verifies the token.
    * `attendanceController.markStudentAttendance` runs.
    * It uses a database **transaction** (a safety feature) to run an `INSERT ... ON CONFLICT DO UPDATE` query.
    * This single, powerful SQL command inserts new records and updates existing ones simultaneously.
    * The backend sends a `201 Created` response.

8.  **Confirmation (Flutter)**:
    * The app receives the `201` response.
    * It closes the loading dialog and shows a "Success" `SnackBar`.

---

## 4. Database Schema 

Here is the likely structure of your main tables and their relationships:

* `Institutes`
    * `id` (Primary Key)
    * `name`

* `Users` (Or separate `Owners` and `Teachers` tables)
    * `id` (Primary Key)
    * `full_name`
    * `email` / `username`
    * `password_hash`
    * `role` (e.g., 'owner', 'teacher')
    * `institute_id` (Foreign Key to `Institutes`)

* `Students`
    * `id` (Primary Key)
    * `full_name`
    * `standard`
    * `institute_id` (Foreign Key to `Institutes`)

* `TeacherAttendance`
    * `id` (Primary Key)
    * `teacher_id` (Foreign Key to `Users`)
    * `institute_id` (Foreign Key to `Institutes`)
    * `attendance_date`
    * `status` (e.g., 'present', 'absent', 'leave')
    * **Unique Constraint**: `(teacher_id, attendance_date)` - This is crucial. It prevents marking a teacher's attendance twice on the same day.

* `StudentAttendance`
    * `id` (Primary Key)
    * `student_id` (Foreign Key to `Students`)
    * `teacher_id` (Foreign Key to `Users`) - *This is important!* It tracks **which teacher** marked the attendance.
    * `institute_id` (Foreign Key to `Institutes`)
    * `attendance_date`
    * `status`
    * **Unique Constraint**: `(student_id, attendance_date)` - Prevents marking a student twice on the same day.

  ##  5. Prerequisites
Before you begin, ensure you have the following installed on your system:Node.js (v16 or newer recommended)PostgreSQLFlutter SDK (v3.0 or newer)An IDE like VS Code with Flutter & Dart extensions.A code editor for the backend (e.g., VS Code).

    **6. Backend Setup**
  Clone the repository:
  Bash
  git clone <your-repository-url>
  cd <project-folder>/backend
  
  Install dependencies:
  Bash
  npm install

 ## 7.Setup Environment Variables:Create a .env file in the backend root directory and add your database credentials and other secrets
DB_USER=your_postgres_user
DB_HOST=localhost
DB_DATABASE=your_database_name
DB_PASSWORD=your_password
DB_PORT=5432
JWT_SECRET=your_jwt_secret_key

**8. Setup the Database:** 
Connect to your PostgreSQL instance and create the database. Then, run the SQL scripts to create the necessary tables (Students, Teachers, StudentAttendance, TeacherAttendance, etc.).

**9. Run the server:**
Bash
npm start

The server will start, typically on http://localhost:3000.

**10. Frontend Setup**
Navigate to the frontend directory:
Bash
cd <project-folder>/frontend
Get Flutter packages:
Bash
flutter pub get
**11. Configure API Connection:** 
Open the lib/services/api_service.dart file and update the _baseUrl to match your backend server's IP address and port. It's crucial to use your machine's network IP, not localhost, for a physical device to connect.

Dart
// lib/services/api_service.dart
// IMPORTANT: Replace this with your actual backend URL
// Use your computer's network IP address, not 'localhost'
static const String _baseUrl = "http://192.168.1.10:3000/api";

// IMPORTANT: Replace this with your actual auth token after login
static const String _authToken = "your_jwt_token_here";

**12. Run the application:** Connect a device or start an emulator and run:
Bash
flutter run

