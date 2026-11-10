# HR Management System - Project Overview

This is a **Next.js-based HR Management System** built for **TericSoft** (a software company). It's a comprehensive web application that manages employees, departments, projects, forms, and performance evaluations.

## 🏗️ Technology Stack
- **Frontend**: Next.js 12.1.6, React 17.0.2, Tailwind CSS
- **Backend**: Node.js with Next.js API routes
- **Database**: PostgreSQL (hosted on AWS)
- **Authentication**: OTP-based login system
- **Deployment**: Fly.io (containerized with Docker)
- **Package Manager**: pnpm

## 👥 User Roles & Access Control

The system has **3 main user types**:

1. **Admin** (`admin@tericsoft.com`)
   - Full system access
   - Can create/manage employees, departments, projects
   - Can assign team members and manage forms
   - Can view all reports and analytics

2. **Project Managers**
   - Can manage their assigned projects
   - Can view team performance
   - Limited administrative access

3. **Employees**
   - Personal dashboard with their projects and forms
   - Can submit forms and view their performance reports
   - Access to their own data only

## 📊 Core Features

### 1. Employee Management
- Add/edit/delete employees
- Assign employees to departments
- Track employee information (name, email, phone, designation)
- Team lead assignments

### 2. Department Management
- Create and manage departments
- Assign team leads to departments
- View department members
- Department-specific analytics

### 3. Project Management
- Create and track projects
- Assign project managers
- Add team members to projects
- Project allocation system (monthly resource allocation)
- Project status tracking

### 4. Forms & Assessments
- Create custom forms with various question types
- Form submission tracking
- Performance evaluations
- Self-assessments and manager reviews
- Form status management (pending/completed)

### 5. Reports & Analytics
- Performance reports
- Form submission analytics
- Project progress tracking
- Employee performance metrics

## 🔐 Authentication System

The system uses a **dual authentication approach**:

1. **Admin Login**: Email/password for admin access
2. **Employee Login**: Email + OTP verification
   - Employee enters email
   - System sends OTP to email
   - Employee enters OTP to verify
   - System fetches employee data from database

## 🗄️ Database Structure

The PostgreSQL database includes these main tables:
- `employees` - Employee information
- `departments` - Department data
- `projects` - Project information
- `project_members` - Project team assignments
- `project_allocations` - Monthly resource allocation
- `forms` - Form definitions
- `form_submissions` - Form responses
- `otps` - OTP verification data

## 🎯 Key Functionality

### Dashboard
- **Admin Dashboard**: Overview of all employees, departments, projects, forms
- **Employee Dashboard**: Personalized view with their projects, pending forms, performance metrics

### Project Management
- Create projects with start dates and managers
- Assign team members to projects
- Track project allocations by month
- Copy allocations from previous months

### Form System
- Create forms with multiple question types (text, dropdown, rating, etc.)
- Assign forms to specific audiences (employees, managers, etc.)
- Track form completion status
- Generate performance reports

### Reports & Analytics
- Employee performance reports
- Form submission analytics
- Project progress tracking
- Department-wise statistics

## 🚀 Deployment & Infrastructure

- **Hosted on**: Fly.io
- **Database**: PostgreSQL on AWS
- **Containerized**: Docker deployment
- **Domain**: `tericsoft-hr-management.fly.dev`

## 📱 Recent Updates & Fixes

Based on the documentation, recent major fixes include:

1. **Access Control**: Fixed admin-only operations (only admins can create employees/departments/projects)
2. **Project Visibility**: Fixed issue where employees couldn't see projects they were assigned to
3. **Form Status**: Fixed forms showing "pending" instead of "completed" after submission
4. **Employee Portal**: Complete implementation of employee-specific views and functionality

## 🔧 Development Setup

To run this project locally:
```bash
# Install dependencies
pnpm install

# Set up environment variables
# (Database connection, email service, etc.)

# Run development server
pnpm dev
```

## 📁 Project Structure

```
hr_management/
├── components/          # Reusable UI components
├── lib/                # Database and utility functions
├── pages/              # Next.js pages and API routes
│   ├── api/           # Backend API endpoints
│   ├── employees/     # Employee management pages
│   ├── departments/   # Department management pages
│   ├── projects/      # Project management pages
│   ├── forms/         # Form creation and submission
│   └── reports/       # Analytics and reporting
├── db/                # Database schema and migrations
├── styles/            # Global CSS styles
└── public/            # Static assets
```

## 🎯 Current Status

The system appears to be **fully functional** with:
- ✅ Complete employee portal implementation
- ✅ Fixed critical access control issues
- ✅ Working authentication system
- ✅ Comprehensive project management
- ✅ Form submission and reporting system
- ✅ Role-based access control
- ✅ Production deployment ready

## 🔑 Key Files

### Core Application Files
- `pages/index.js` - Main dashboard
- `pages/login.js` - Authentication system
- `lib/database.js` - Database operations
- `lib/data.js` - Data access layer
- `lib/auth.js` - Authentication utilities

### API Endpoints
- `/api/employees/` - Employee management
- `/api/departments/` - Department management
- `/api/projects/` - Project management
- `/api/forms/` - Form system
- `/api/auth/` - Authentication APIs

### Database
- `db/schema.sql` - Database schema
- `migrations/` - Database migrations

## 🧪 Testing

The system includes comprehensive testing for:
- Employee authentication with OTP
- Role-based access control
- Project visibility for employees
- Form submission and status tracking
- Admin operations security

## 📈 Features Summary

This is a **production-ready HR management system** that handles:
- Complete employee lifecycle management
- Project allocation and tracking
- Performance evaluation through forms
- Role-based access control
- Modern, responsive interface
- Real-time data synchronization
- Secure authentication system

The system is designed to scale and can handle multiple departments, projects, and employees with proper access controls and data integrity.



