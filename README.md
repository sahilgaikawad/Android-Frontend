# Comprehensive Institute Management System

This is a full-stack, multi-tenant application designed for educational institutes to seamlessly manage **student & teacher attendance** and **student fees**. The system features a Flutter mobile application for admins, teachers, and students, supported by a robust Node.js (Express) backend and a PostgreSQL database.

## 🌟 Core Modules

1.  **Role-Based Access Control**: Secure and distinct dashboards for three user roles: Owner (Admin), Teacher, and Student.
2.  **Attendance Management**: A complete solution for marking and tracking daily attendance for both teachers and students.
3.  **Fees Management**: An end-to-end module for creating fee structures, tracking payments, and viewing financial status.
4.  **Multi-Tenancy**: A secure architecture that allows multiple institutes to operate independently on the same platform, with data completely isolated via `institute_id`.



## ✨ Features by Role

### 👑 Owner (Admin) Features

  * **Teacher Management**:
      * View a complete list of all teachers in the institute.
      * Mark daily attendance (Present, Absent, Leave) for all teachers.
      * View, update, and delete historical attendance records for any teacher.
  * **Fees Management**:
      * Define and create dynamic fee structures for different standards (e.g., 12th Science Tuition Fee).
      * Assign fee structures to individual students or entire classes.
      * Record and manage fee payments received from students (Cash, Online, etc.).
      * View a comprehensive dashboard of fee collection: total due, total paid, and outstanding balances.
      * Generate financial reports.
  * **Student Oversight**:
      * View a complete list of all students across all standards.
      * Track the attendance and fee status of any student in the institute.

### 👨‍🏫 Teacher Features

  * **Student Attendance**:
      * Mark daily attendance for students in their assigned classes.
      * View, update, and delete historical student attendance records.
      * Instantly search for students by name and filter by standard.
  * **Student Oversight**:
      * View the fee payment status for students in their classes to send reminders.
  * **Personal Dashboard**:
      * View their own personal attendance history.

### 🎓 Student Features

  * **Academic Dashboard**:
      * View their own complete, day-by-day attendance history.
      * Check attendance percentage and track regularity.
  * **Financial Dashboard**:
      * View their assigned fee structure (total fees, due dates).
      * Track their payment history and view receipts.
      * Check their current outstanding balance.



## 🛠️ Technology Stack

**Frontend** | Flutter (Dart)         
**Backend** | Node.js, Express.js    
**Database** | PostgreSQL             
**Authentication** | JWT (JSON Web Tokens)  
**HTTP Client** | `http` (Flutter Package) 



## 🏗️ Project Architecture & Data Flow

The system uses a secure and scalable client-server model.

**`Flutter App (Client)`** ➡️ **`Node.js API (Server)`** ➡️ **`PostgreSQL (Database)`**

1.  **Client (Flutter)**: Handles all UI/UX. The user interacts with the app, which sends requests to the server.
2.  **Server (Node.js)**: Acts as the central authority. It receives requests, validates them using `authMiddleware` (to check the user's role and permissions), processes the logic, interacts with the database, and sends a JSON response.
3.  **Database (PostgreSQL)**: The single source of truth. It stores all data and is only accessible by the Node.js server, ensuring data integrity and security.



## 🗄️ Database Schema

The schema is designed to support multi-tenancy and role-based features, including the new fees module.

  * `Institutes` (`id`, `name`)
  * `Users` (`id`, `full_name`, `email`, `password_hash`, `role`, `institute_id`)
  * `Students` (`id`, `full_name`, `standard`, `institute_id`)
  * `TeacherAttendance` (`id`, `teacher_id`, `attendance_date`, `status`, `institute_id`)
      * *Unique Constraint*: `(teacher_id, attendance_date)`
  * `StudentAttendance` (`id`, `student_id`, `teacher_id`, `attendance_date`, `status`, `institute_id`)
      * *Unique Constraint*: `(student_id, attendance_date)`

#### New Tables for Fees Management

  * `FeeStructures`
      * `id` (Primary Key)
      * `institute_id` (Foreign Key to `Institutes`)
      * `standard` (e.g., '10th', '12th Science')
      * `fee_type` (e.g., 'Tuition Fee', 'Exam Fee')
      * `amount`
  * `StudentFees`
      * `id` (Primary Key)
      * `student_id` (Foreign Key to `Students`)
      * `fee_structure_id` (Foreign Key to `FeeStructures`)
      * `total_due`
      * `amount_paid`
      * `status` (e.g., 'Paid', 'Due', 'Partially Paid', 'Overdue')
  * `FeePayments`
      * `id` (Primary Key)
      * `student_fee_id` (Foreign Key to `StudentFees`)
      * `amount_paid`
      * `payment_date`
      * `payment_mode` (e.g., 'Cash', 'UPI', 'Card')
      * `transaction_id` (Optional, for online payments)
      * `recorded_by` (Foreign Key to `Users`, tracks which admin recorded the payment)

-----

## 🌐 API Endpoints

All routes are prefixed with `/api`. Authorization is handled by `isOwner`, `isTeacher`, or `isStudent` middleware.

| Method   | Endpoint                                   | Protected By     | Description                                         |
| -------  | -----------------------------------------  | ---------------  |  -------------------------------------------------- |
| **Attendance** |
| `GET`    | `/attendance/student`                      | Teacher          | Get student attendance for a date.                  |
| `POST`   | `/attendance/student`                      | Teacher          | Mark or update student attendance.                  |
| `GET`    | `/attendance/student/history/:studentId`   | Teacher, Student | Get a student's attendance history.                 |
| `PUT`    | `/attendance/student/record/:recordId`     | Teacher          | Update a single student attendance record.          |
| `DELETE` | `/attendance/student/records`              | Teacher          | Delete multiple student attendance records.         |
| `GET`    | `/attendance/teacher/my-history`           | Teacher          | Get the logged-in teacher's own history.            |

| **Fees Management** |
| `POST`   | `/fees/structure`                          | Owner            | Create a new fee structure.                         |
| `POST`   | `/fees/assign`                             | Owner            | Assign a fee structure to a student.                |
| `POST`   | `/fees/payment`                            | Owner            | Record a fee payment for a student.                 |
| `GET`    | `/fees/student/:studentId`                 | Owner, Teacher   | Get the fee status of a specific student.           |
| `GET`    | `/fees/my-fees`                            | Student          | Get the logged-in student's own fee details.        |



## 🚀 Getting Started

### Prerequisites

  * Node.js (v16+)
  * PostgreSQL
  * Flutter SDK (v3.0+)
  * An IDE like VS Code with Flutter & Dart extensions.

### Backend Setup

1.  **Clone & Navigate**:
    bash
    git clone <your-repository-url>
    cd <project-folder>/backend
    
2.  **Install Dependencies**: `npm install`
3.  **Setup `.env` file**: Create a `.env` file and add your database and JWT credentials.
    env
    DB_USER=your_postgres_user
    DB_HOST=localhost
    DB_DATABASE=your_database_name
    DB_PASSWORD=your_password
    DB_PORT=5432
    JWT_SECRET=your_super_secret_key_for_jwt
    
4.  **Setup Database**: Create the database and run the provided SQL scripts to set up all tables.
5.  **Run Server**: `npm start`

### Frontend Setup

1.  **Navigate**: `cd <project-folder>/frontend`
2.  **Install Dependencies**: `flutter pub get`
3.  **Configure API**: Open `lib/services/api_service.dart` and set the `_baseUrl` to your backend's network IP address.
    dart
    // Use your computer's network IP, not 'localhost', for physical devices
    static const String _baseUrl = "http://Your_IP:3000/api";
    
4.  **Run App**: Connect a device/emulator and run `flutter run`.
