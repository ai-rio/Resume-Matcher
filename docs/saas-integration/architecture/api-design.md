# API Design

## Overview

The Resume-Matcher SaaS API is built on FastAPI with RESTful principles, providing secure, scalable endpoints for all platform functionality. This document outlines the complete API architecture, authentication, and endpoint specifications.

## Core Design Principles

- **RESTful**: Standard HTTP methods and status codes
- **Secure**: JWT-based authentication with role-based access
- **Versioned**: API versioning for backward compatibility
- **Rate Limited**: Subscription-based rate limiting
- **Well-Documented**: OpenAPI/Swagger auto-documentation
- **Consistent**: Standardized request/response formats

## API Architecture

### Base URL Structure
```
https://api.resume-matcher.com/v1/
```

### Authentication
- **Method**: JWT tokens via Supabase Auth
- **Header**: `Authorization: Bearer <jwt_token>`
- **Refresh**: Automatic token refresh mechanism
- **Scopes**: Role-based permissions (user, admin, api_key)

### Rate Limiting
- **Free Tier**: 100 requests/hour
- **Pro Tier**: 1,000 requests/hour  
- **Enterprise**: 10,000 requests/hour
- **Headers**: Rate limit info in response headers

## API Endpoints Overview

### 1. Authentication Endpoints

#### POST /auth/signup
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "full_name": "John Doe",
  "company": "Tech Corp"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe"
  },
  "session": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 3600
  }
}
```

#### POST /auth/login
Authenticate existing user.

#### POST /auth/logout
Invalidate user session.

#### POST /auth/refresh
Refresh JWT token.

#### POST /auth/forgot-password
Request password reset.

#### POST /auth/reset-password
Reset password with token.

### 2. User Profile Endpoints

#### GET /users/profile
Get current user profile.

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "full_name": "John Doe",
  "company": "Tech Corp",
  "job_title": "Software Engineer",
  "avatar_url": "https://...",
  "subscription": {
    "plan": "pro",
    "status": "active",
    "current_period_end": "2024-02-01T00:00:00Z"
  },
  "usage": {
    "resumes_uploaded": 5,
    "analyses_this_month": 23,
    "storage_used": 15728640
  }
}
```

#### PUT /users/profile
Update user profile.

#### DELETE /users/account
Delete user account and all data.

### 3. Resume Management Endpoints

#### GET /resumes
List user's resumes with pagination.

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `sort`: Sort field (created_at, title, updated_at)
- `order`: Sort order (asc, desc)

**Response:**
```json
{
  "resumes": [
    {
      "id": "uuid",
      "title": "Software Engineer Resume",
      "filename": "resume.pdf",
      "file_size": 1048576,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "analysis_summary": {
        "skills_count": 15,
        "experience_years": 5,
        "education_level": "Bachelor's"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "total_pages": 1
  }
}
```

#### POST /resumes/upload
Upload a new resume file.

**Request:** Multipart form data
- `file`: Resume file (PDF, DOC, DOCX)
- `title`: Optional title override

**Response:**
```json
{
  "id": "uuid",
  "title": "Software Engineer Resume",
  "filename": "resume.pdf",
  "file_size": 1048576,
  "status": "processing",
  "upload_url": "https://...",
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### GET /resumes/{resume_id}
Get specific resume details.

#### PUT /resumes/{resume_id}
Update resume metadata.

#### DELETE /resumes/{resume_id}
Delete resume file and data.

#### GET /resumes/{resume_id}/download
Download original resume file.

#### GET /resumes/{resume_id}/analysis
Get resume parsing analysis.

**Response:**
```json
{
  "id": "uuid",
  "resume_id": "uuid",
  "analysis_type": "full_parse",
  "results": {
    "personal_info": {
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "location": "San Francisco, CA"
    },
    "skills": {
      "technical": ["Python", "React", "PostgreSQL"],
      "soft": ["Leadership", "Communication"],
      "certifications": ["AWS Certified"]
    },
    "experience": [
      {
        "title": "Senior Software Engineer",
        "company": "Tech Corp",
        "location": "San Francisco, CA",
        "start_date": "2022-01",
        "end_date": "present",
        "duration_months": 24,
        "description": "Led development of...",
        "technologies": ["Python", "React"]
      }
    ],
    "education": [
      {
        "degree": "Bachelor of Science",
        "field": "Computer Science",
        "institution": "Stanford University",
        "graduation_year": "2020",
        "gpa": "3.8"
      }
    ]
  },
  "confidence_score": 0.95,
  "created_at": "2024-01-15T10:35:00Z"
}
```

### 4. Job Description Endpoints

#### GET /jobs
List user's job descriptions.

#### POST /jobs
Create new job description.

**Request:**
```json
{
  "title": "Senior Software Engineer",
  "company": "Tech Startup",
  "description": "We are looking for...",
  "requirements": "5+ years experience...",
  "location": "Remote",
  "salary_range": "$120k - $180k"
}
```

#### GET /jobs/{job_id}
Get specific job description.

#### PUT /jobs/{job_id}
Update job description.

#### DELETE /jobs/{job_id}
Delete job description.

### 5. Analysis & Matching Endpoints

#### POST /analysis/match
Analyze resume against job description.

**Request:**
```json
{
  "resume_id": "uuid",
  "job_id": "uuid",
  "analysis_type": "comprehensive"
}
```

**Response:**
```json
{
  "id": "uuid",
  "overall_score": 85.5,
  "analysis_summary": {
    "strengths": [
      "Strong technical skill match (92%)",
      "Relevant experience (88%)",
      "Education requirements met"
    ],
    "gaps": [
      "Missing specific framework experience",
      "Could benefit from additional certifications"
    ],
    "recommendations": [
      "Highlight Python experience more prominently",
      "Add specific project outcomes",
      "Consider getting AWS certification"
    ]
  },
  "detailed_scores": {
    "skills_match": {
      "score": 92,
      "matched_skills": ["Python", "React", "PostgreSQL"],
      "missing_skills": ["Kubernetes", "AWS"],
      "additional_skills": ["Docker", "Redis"]
    },
    "experience_match": {
      "score": 88,
      "years_required": 5,
      "years_candidate": 4,
      "relevant_roles": 2,
      "industry_match": true
    },
    "education_match": {
      "score": 95,
      "degree_match": true,
      "field_relevance": "high",
      "institution_tier": "top"
    }
  },
  "keyword_analysis": {
    "resume_keywords": 145,
    "job_keywords": 89,
    "matching_keywords": 67,
    "keyword_density": 0.46
  },
  "created_at": "2024-01-15T11:00:00Z"
}
```

#### GET /analysis/history
Get user's analysis history.

#### GET /analysis/{analysis_id}
Get specific analysis details.

#### POST /analysis/batch
Analyze multiple resume-job combinations.

**Request:**
```json
{
  "combinations": [
    {"resume_id": "uuid1", "job_id": "uuid1"},
    {"resume_id": "uuid1", "job_id": "uuid2"},
    {"resume_id": "uuid2", "job_id": "uuid1"}
  ],
  "analysis_type": "quick"
}
```

### 6. Subscription Endpoints

#### GET /subscriptions/plans
Get available subscription plans.

**Response:**
```json
{
  "plans": [
    {
      "id": "uuid",
      "name": "Free",
      "slug": "free",
      "description": "Get started with basic features",
      "price_monthly": 0,
      "price_yearly": 0,
      "features": {
        "resume_uploads_per_month": 3,
        "job_analyses_per_month": 10,
        "advanced_analytics": false,
        "api_access": false,
        "priority_support": false
      },
      "limits": {
        "max_resumes": 3,
        "max_file_size": 5242880,
        "rate_limit_per_hour": 50
      }
    },
    {
      "id": "uuid",
      "name": "Pro",
      "slug": "pro",
      "description": "Advanced features for professionals",
      "price_monthly": 1999,
      "price_yearly": 19990,
      "features": {
        "resume_uploads_per_month": 25,
        "job_analyses_per_month": 100,
        "advanced_analytics": true,
        "api_access": true,
        "priority_support": true
      }
    }
  ]
}
```

#### GET /subscriptions/current
Get current user subscription.

#### POST /subscriptions/checkout
Create Stripe checkout session.

#### POST /subscriptions/portal
Create Stripe customer portal session.

#### PUT /subscriptions/cancel
Cancel current subscription.

### 7. Usage & Analytics Endpoints

#### GET /usage/current
Get current month usage.

**Response:**
```json
{
  "current_period": {
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-01-31T23:59:59Z"
  },
  "usage": {
    "analyses_count": 23,
    "resumes_uploaded": 5,
    "jobs_analyzed": 8,
    "api_calls": 145,
    "storage_used": 15728640
  },
  "limits": {
    "analyses_limit": 100,
    "uploads_limit": 25,
    "storage_limit": 104857600,
    "api_calls_limit": 1000
  },
  "remaining": {
    "analyses": 77,
    "uploads": 20,
    "storage": 89128960,
    "api_calls": 855
  }
}
```

#### GET /usage/history
Get usage history with trends.

### 8. Admin Endpoints

#### GET /admin/users
List all users (admin only).

#### GET /admin/analytics
Get platform analytics.

#### POST /admin/users/{user_id}/suspend
Suspend user account.

#### GET /admin/subscriptions
Manage subscriptions.

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    },
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "req_123456"
  }
}
```

### HTTP Status Codes
- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **422**: Validation Error
- **429**: Rate Limited
- **500**: Internal Server Error

## API Versioning

### Version Strategy
- **URL Versioning**: `/v1/`, `/v2/`
- **Backward Compatibility**: 2 versions supported
- **Deprecation**: 6-month notice period
- **Documentation**: Version-specific docs

### Version Headers
```
API-Version: v1
Supported-Versions: v1, v2
Deprecated-Versions: v1 (sunset: 2024-12-31)
```

## Security Considerations

### Authentication Security
- JWT tokens with 1-hour expiration
- Refresh tokens with secure rotation
- Rate limiting per user and IP
- Request signing for API keys

### Data Validation
- Input sanitization and validation
- File type and size restrictions
- SQL injection prevention
- XSS protection

### API Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'
```

## Performance Optimization

### Caching Strategy
- Redis for session data
- CDN for static responses
- Database query optimization
- Response compression

### Database Optimization
- Connection pooling
- Query optimization
- Proper indexing
- Read replicas for analytics

## Monitoring & Logging

### API Metrics
- Response time distribution
- Error rate by endpoint
- Rate limit violations
- Usage patterns by plan

### Logging Standards
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "request_id": "req_123456",
  "user_id": "uuid",
  "method": "POST",
  "path": "/v1/analysis/match",
  "status_code": 200,
  "response_time": 145,
  "user_agent": "ResumeMatcherApp/1.0"
}
```

---

**Next Steps**: Review `api/endpoints/` for detailed endpoint specifications and `api/schemas/` for request/response schemas.