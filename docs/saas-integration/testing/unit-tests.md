# Unit Testing Framework

## Overview

This document outlines the comprehensive unit testing strategy for the Resume-Matcher SaaS platform, covering both frontend (React/TypeScript) and backend (FastAPI/Python) components with modern testing frameworks and best practices.

## Testing Philosophy

### Core Principles
- **Test-Driven Development (TDD)**: Write tests before implementation when possible
- **Comprehensive Coverage**: Aim for 90%+ code coverage on critical paths
- **Fast Feedback**: Unit tests should run quickly and provide immediate feedback
- **Isolated Testing**: Each test should be independent and not rely on external services
- **Readable Tests**: Tests should serve as documentation for expected behavior

### Testing Pyramid

```mermaid
graph TB
    A[Unit Tests - 70%]
    B[Integration Tests - 20%]
    C[E2E Tests - 10%]
    
    A --> B
    B --> C
    
    subgraph "Unit Tests"
        D[Component Tests]
        E[Function Tests]
        F[Service Tests]
        G[Utility Tests]
    end
    
    subgraph "Integration Tests"
        H[API Tests]
        I[Database Tests]
        J[Service Integration]
    end
    
    subgraph "E2E Tests"
        K[User Flows]
        L[Critical Paths]
    end
```

## Frontend Testing (React/TypeScript)

### Technology Stack
- **Test Runner**: Jest
- **Testing Library**: React Testing Library
- **Mocking**: MSW (Mock Service Worker)
- **Coverage**: Istanbul/NYC
- **Assertions**: Jest + Custom Matchers

### Setup Configuration

#### Jest Configuration (`jest.config.js`)

```javascript
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.ts'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy'
  },
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/index.tsx',
    '!src/reportWebVitals.ts',
    '!src/**/*.stories.{ts,tsx}'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/components/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{spec,test}.{js,jsx,ts,tsx}'
  ],
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest'
  }
}
```

#### Test Setup (`src/setupTests.ts`)

```typescript
import '@testing-library/jest-dom'
import { server } from './mocks/server'
import { TextEncoder, TextDecoder } from 'util'

// Polyfills for jsdom
Object.assign(global, { TextDecoder, TextEncoder })

// Mock ResizeObserver
global.ResizeObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn()
}))

// Mock IntersectionObserver
global.IntersectionObserver = jest.fn().mockImplementation(() => ({
  observe: jest.fn(),
  unobserve: jest.fn(),
  disconnect: jest.fn()
}))

// Setup MSW server
beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn()
  }))
})

// Custom matchers
expect.extend({
  toBeVisible: (element) => {
    const pass = element && element.style.display !== 'none'
    return {
      message: () => `expected element to ${pass ? 'not ' : ''}be visible`,
      pass
    }
  }
})
```

### Component Testing Examples

#### Authentication Component Tests

```typescript
// components/auth/__tests__/SignInForm.test.tsx
import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { SignInForm } from '../SignInForm'
import { AuthProvider } from '@/contexts/AuthContext'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'

// Test wrapper for providers
const TestWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  })

  return (
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          {children}
        </AuthProvider>
      </QueryClientProvider>
    </BrowserRouter>
  )
}

describe('SignInForm', () => {
  const user = userEvent.setup()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders all form elements correctly', () => {
    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
    expect(screen.getByText(/forgot password/i)).toBeInTheDocument()
  })

  it('validates email format', async () => {
    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    const emailInput = screen.getByLabelText(/email address/i)
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'invalid-email')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/please enter a valid email address/i)).toBeInTheDocument()
    })
  })

  it('validates required fields', async () => {
    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    const submitButton = screen.getByRole('button', { name: /sign in/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/email is required/i)).toBeInTheDocument()
      expect(screen.getByText(/password is required/i)).toBeInTheDocument()
    })
  })

  it('submits form with valid credentials', async () => {
    const mockSignIn = jest.fn().mockResolvedValue({})
    
    // Mock the auth context
    jest.mock('@/contexts/AuthContext', () => ({
      useAuth: () => ({
        signIn: mockSignIn,
        loading: false,
        user: null
      })
    }))

    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'user@example.com')
    await user.type(passwordInput, 'password123')
    await user.click(submitButton)

    await waitFor(() => {
      expect(mockSignIn).toHaveBeenCalledWith('user@example.com', 'password123')
    })
  })

  it('displays error message on failed authentication', async () => {
    const mockSignIn = jest.fn().mockRejectedValue(
      new Error('Invalid credentials')
    )

    jest.mock('@/contexts/AuthContext', () => ({
      useAuth: () => ({
        signIn: mockSignIn,
        loading: false,
        user: null
      })
    }))

    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'user@example.com')
    await user.type(passwordInput, 'wrongpassword')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/invalid credentials/i)).toBeInTheDocument()
    })
  })

  it('disables form during submission', async () => {
    let resolveSignIn: () => void
    const mockSignIn = jest.fn(() => 
      new Promise<void>((resolve) => {
        resolveSignIn = resolve
      })
    )

    render(
      <TestWrapper>
        <SignInForm />
      </TestWrapper>
    )

    const emailInput = screen.getByLabelText(/email address/i)
    const passwordInput = screen.getByLabelText(/password/i)
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'user@example.com')
    await user.type(passwordInput, 'password123')
    await user.click(submitButton)

    // Form should be disabled during submission
    expect(submitButton).toBeDisabled()
    expect(emailInput).toBeDisabled()
    expect(passwordInput).toBeDisabled()

    // Resolve the promise
    resolveSignIn!()

    await waitFor(() => {
      expect(submitButton).not.toBeDisabled()
    })
  })
})
```

#### Hook Testing

```typescript
// hooks/__tests__/useAuth.test.tsx
import { renderHook, act } from '@testing-library/react'
import { useAuth } from '../useAuth'
import { AuthProvider } from '@/contexts/AuthContext'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  })

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        {children}
      </AuthProvider>
    </QueryClientProvider>
  )
}

describe('useAuth', () => {
  it('initializes with loading state', () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: createWrapper()
    })

    expect(result.current.loading).toBe(true)
    expect(result.current.user).toBe(null)
  })

  it('signs in user successfully', async () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: createWrapper()
    })

    await act(async () => {
      await result.current.signIn('user@example.com', 'password123')
    })

    expect(result.current.user).toBeTruthy()
    expect(result.current.loading).toBe(false)
  })

  it('handles sign in error', async () => {
    const { result } = renderHook(() => useAuth(), {
      wrapper: createWrapper()
    })

    await act(async () => {
      try {
        await result.current.signIn('invalid@example.com', 'wrongpassword')
      } catch (error) {
        expect(error).toBeInstanceOf(Error)
      }
    })

    expect(result.current.user).toBe(null)
  })
})
```

### Utility Function Testing

```typescript
// utils/__tests__/validation.test.ts
import { validateEmail, validatePassword, getPasswordStrength } from '../validation'

describe('validation utilities', () => {
  describe('validateEmail', () => {
    it('validates correct email formats', () => {
      const validEmails = [
        'user@example.com',
        'test.email+tag@domain.co.uk',
        'user123@sub.domain.org'
      ]

      validEmails.forEach(email => {
        expect(validateEmail(email)).toBe(true)
      })
    })

    it('rejects invalid email formats', () => {
      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user..double.dot@domain.com'
      ]

      invalidEmails.forEach(email => {
        expect(validateEmail(email)).toBe(false)
      })
    })
  })

  describe('validatePassword', () => {
    it('accepts strong passwords', () => {
      const strongPasswords = [
        'StrongPass123!',
        'MyP@ssw0rd',
        'C0mpl3x_P@ss'
      ]

      strongPasswords.forEach(password => {
        expect(validatePassword(password)).toBe(true)
      })
    })

    it('rejects weak passwords', () => {
      const weakPasswords = [
        'password',
        '12345678',
        'PASSWORD',
        'Pass123'
      ]

      weakPasswords.forEach(password => {
        expect(validatePassword(password)).toBe(false)
      })
    })
  })

  describe('getPasswordStrength', () => {
    it('calculates password strength correctly', () => {
      const testCases = [
        { password: 'weak', expectedScore: 1 },
        { password: 'Password123', expectedScore: 4 },
        { password: 'Str0ng!P@ssw0rd', expectedScore: 5 }
      ]

      testCases.forEach(({ password, expectedScore }) => {
        const result = getPasswordStrength(password)
        expect(result.score).toBe(expectedScore)
      })
    })
  })
})
```

## Backend Testing (FastAPI/Python)

### Technology Stack
- **Test Framework**: pytest
- **HTTP Testing**: httpx
- **Database Testing**: pytest-postgresql
- **Mocking**: pytest-mock
- **Fixtures**: pytest fixtures
- **Coverage**: pytest-cov

### Setup Configuration

#### Pytest Configuration (`pytest.ini`)

```ini
[tool:pytest]
testpaths = tests
python_files = test_*.py *_test.py
python_functions = test_*
python_classes = Test*
addopts = 
    --strict-markers
    --strict-config
    --cov=app
    --cov-report=term-missing
    --cov-report=html
    --cov-report=xml
    --cov-fail-under=80
    -ra
    --tb=short
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow running tests
    external: Tests that require external services
asyncio_mode = auto
```

#### Test Configuration (`tests/conftest.py`)

```python
import pytest
import asyncio
from typing import AsyncGenerator, Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.database import get_db, Base
from app.models import User, Resume, Subscription
from app.core.security import create_access_token
from app.core.config import settings

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def db_session():
    """Create a fresh database session for each test."""
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client(db_session):
    """Create a test client with dependency overrides."""
    def override_get_db():
        try:
            yield db_session
        finally:
            db_session.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()

@pytest.fixture
def test_user(db_session):
    """Create a test user."""
    user = User(
        email="test@example.com",
        hashed_password="hashed_password",
        full_name="Test User",
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

@pytest.fixture
def test_user_token(test_user):
    """Create an access token for the test user."""
    return create_access_token(subject=test_user.id)

@pytest.fixture
def authenticated_client(client, test_user_token):
    """Create an authenticated test client."""
    client.headers["Authorization"] = f"Bearer {test_user_token}"
    return client

@pytest.fixture
def mock_file_upload():
    """Mock file upload for testing."""
    from io import BytesIO
    return ("test_resume.pdf", BytesIO(b"fake pdf content"), "application/pdf")
```

### API Endpoint Testing

```python
# tests/api/test_auth.py
import pytest
from fastapi import status
from app.core.security import verify_password

class TestAuthEndpoints:
    """Test authentication endpoints."""

    def test_signup_success(self, client):
        """Test successful user registration."""
        signup_data = {
            "email": "newuser@example.com",
            "password": "StrongPass123!",
            "full_name": "New User",
            "company": "Test Corp"
        }
        
        response = client.post("/api/v1/auth/signup", json=signup_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["user"]["email"] == signup_data["email"]
        assert data["user"]["full_name"] == signup_data["full_name"]
        assert "password" not in data["user"]

    def test_signup_duplicate_email(self, client, test_user):
        """Test registration with existing email."""
        signup_data = {
            "email": test_user.email,
            "password": "StrongPass123!",
            "full_name": "Duplicate User"
        }
        
        response = client.post("/api/v1/auth/signup", json=signup_data)
        
        assert response.status_code == status.HTTP_409_CONFLICT
        assert "already exists" in response.json()["detail"]

    def test_signup_weak_password(self, client):
        """Test registration with weak password."""
        signup_data = {
            "email": "weakpass@example.com",
            "password": "weak",
            "full_name": "Weak Password User"
        }
        
        response = client.post("/api/v1/auth/signup", json=signup_data)
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    def test_signin_success(self, client, test_user, db_session):
        """Test successful sign in."""
        # Set a known password for the test user
        from app.core.security import get_password_hash
        test_user.hashed_password = get_password_hash("testpass123")
        db_session.commit()
        
        signin_data = {
            "email": test_user.email,
            "password": "testpass123"
        }
        
        response = client.post("/api/v1/auth/signin", json=signin_data)
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["user"]["email"] == test_user.email

    def test_signin_invalid_credentials(self, client, test_user):
        """Test sign in with invalid credentials."""
        signin_data = {
            "email": test_user.email,
            "password": "wrongpassword"
        }
        
        response = client.post("/api/v1/auth/signin", json=signin_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_signin_nonexistent_user(self, client):
        """Test sign in with non-existent user."""
        signin_data = {
            "email": "nonexistent@example.com",
            "password": "password123"
        }
        
        response = client.post("/api/v1/auth/signin", json=signin_data)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_get_current_user(self, authenticated_client, test_user):
        """Test getting current user info."""
        response = authenticated_client.get("/api/v1/auth/me")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["email"] == test_user.email
        assert data["full_name"] == test_user.full_name

    def test_get_current_user_unauthorized(self, client):
        """Test getting current user without authentication."""
        response = client.get("/api/v1/auth/me")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
```

### Service Layer Testing

```python
# tests/services/test_resume_service.py
import pytest
from unittest.mock import Mock, patch
from app.services.resume_service import ResumeService
from app.models import Resume, User
from app.schemas.resume import ResumeCreate

class TestResumeService:
    """Test resume service business logic."""

    @pytest.fixture
    def resume_service(self, db_session):
        """Create resume service instance."""
        return ResumeService(db_session)

    @pytest.fixture
    def sample_resume_data(self):
        """Sample resume data for testing."""
        return ResumeCreate(
            title="Software Engineer Resume",
            content="John Doe\nSoftware Engineer\nPython, React, SQL"
        )

    def test_create_resume(self, resume_service, test_user, sample_resume_data):
        """Test creating a new resume."""
        resume = resume_service.create_resume(
            user_id=test_user.id,
            resume_data=sample_resume_data
        )
        
        assert resume.user_id == test_user.id
        assert resume.title == sample_resume_data.title
        assert resume.content_text == sample_resume_data.content

    def test_parse_resume_content(self, resume_service):
        """Test resume content parsing."""
        content = """
        John Doe
        Software Engineer
        Email: john@example.com
        
        SKILLS
        Python, JavaScript, React, SQL
        
        EXPERIENCE
        Senior Developer at TechCorp (2020-2023)
        """
        
        parsed_data = resume_service.parse_resume_content(content)
        
        assert parsed_data["personal_info"]["name"] == "John Doe"
        assert parsed_data["personal_info"]["email"] == "john@example.com"
        assert "Python" in parsed_data["skills"]
        assert len(parsed_data["experience"]) > 0

    @patch('app.services.resume_service.extract_text_from_pdf')
    def test_process_pdf_resume(self, mock_extract, resume_service, test_user):
        """Test processing PDF resume."""
        mock_extract.return_value = "Extracted text from PDF"
        
        file_content = b"fake pdf content"
        resume = resume_service.process_uploaded_file(
            user_id=test_user.id,
            filename="resume.pdf",
            file_content=file_content,
            content_type="application/pdf"
        )
        
        mock_extract.assert_called_once_with(file_content)
        assert resume.content_text == "Extracted text from PDF"

    def test_get_user_resumes(self, resume_service, test_user, db_session):
        """Test retrieving user resumes."""
        # Create test resumes
        resume1 = Resume(
            user_id=test_user.id,
            title="Resume 1",
            content_text="Content 1"
        )
        resume2 = Resume(
            user_id=test_user.id,
            title="Resume 2",
            content_text="Content 2"
        )
        db_session.add_all([resume1, resume2])
        db_session.commit()
        
        resumes = resume_service.get_user_resumes(test_user.id)
        
        assert len(resumes) == 2
        assert all(r.user_id == test_user.id for r in resumes)

    def test_delete_resume(self, resume_service, test_user, db_session):
        """Test deleting a resume."""
        resume = Resume(
            user_id=test_user.id,
            title="To Delete",
            content_text="Content"
        )
        db_session.add(resume)
        db_session.commit()
        
        result = resume_service.delete_resume(resume.id, test_user.id)
        
        assert result is True
        deleted_resume = db_session.query(Resume).filter_by(id=resume.id).first()
        assert deleted_resume is None

    def test_delete_resume_unauthorized(self, resume_service, test_user, db_session):
        """Test deleting resume by wrong user."""
        other_user = User(
            email="other@example.com",
            hashed_password="hash",
            full_name="Other User"
        )
        db_session.add(other_user)
        db_session.commit()
        
        resume = Resume(
            user_id=other_user.id,
            title="Other's Resume",
            content_text="Content"
        )
        db_session.add(resume)
        db_session.commit()
        
        with pytest.raises(PermissionError):
            resume_service.delete_resume(resume.id, test_user.id)
```

### Database Model Testing

```python
# tests/models/test_user.py
import pytest
from sqlalchemy.exc import IntegrityError
from app.models import User, Resume

class TestUserModel:
    """Test User model and relationships."""

    def test_create_user(self, db_session):
        """Test creating a user."""
        user = User(
            email="test@example.com",
            hashed_password="hashed_password",
            full_name="Test User"
        )
        db_session.add(user)
        db_session.commit()
        
        assert user.id is not None
        assert user.email == "test@example.com"
        assert user.is_active is True

    def test_user_email_unique_constraint(self, db_session):
        """Test email uniqueness constraint."""
        user1 = User(
            email="duplicate@example.com",
            hashed_password="hash1",
            full_name="User 1"
        )
        user2 = User(
            email="duplicate@example.com",
            hashed_password="hash2",
            full_name="User 2"
        )
        
        db_session.add(user1)
        db_session.commit()
        
        db_session.add(user2)
        with pytest.raises(IntegrityError):
            db_session.commit()

    def test_user_resume_relationship(self, db_session):
        """Test user-resume relationship."""
        user = User(
            email="user@example.com",
            hashed_password="hash",
            full_name="User"
        )
        db_session.add(user)
        db_session.commit()
        
        resume = Resume(
            user_id=user.id,
            title="Test Resume",
            content_text="Resume content"
        )
        db_session.add(resume)
        db_session.commit()
        
        assert len(user.resumes) == 1
        assert user.resumes[0].title == "Test Resume"
        assert resume.user.email == "user@example.com"
```

## Test Data Factories

### Frontend Test Factories

```typescript
// src/test-utils/factories.ts
import { User, Resume, JobDescription } from '@/types'

export const createMockUser = (overrides: Partial<User> = {}): User => ({
  id: 'user-123',
  email: 'test@example.com',
  full_name: 'Test User',
  company: 'Test Corp',
  job_title: 'Software Engineer',
  avatar_url: null,
  email_confirmed: true,
  onboarding_completed: true,
  subscription: {
    plan: 'pro',
    status: 'active',
    current_period_end: '2024-12-31T23:59:59Z'
  },
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
})

export const createMockResume = (overrides: Partial<Resume> = {}): Resume => ({
  id: 'resume-123',
  user_id: 'user-123',
  title: 'Software Engineer Resume',
  filename: 'resume.pdf',
  file_size: 1048576,
  content_text: 'John Doe\nSoftware Engineer\nPython, React, SQL',
  parsed_data: {
    personal_info: {
      name: 'John Doe',
      email: 'john@example.com'
    },
    skills: ['Python', 'React', 'SQL'],
    experience: []
  },
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
})

export const createMockJobDescription = (overrides: Partial<JobDescription> = {}): JobDescription => ({
  id: 'job-123',
  user_id: 'user-123',
  title: 'Senior Software Engineer',
  company: 'TechCorp',
  description: 'Looking for a skilled software engineer...',
  requirements: '5+ years experience with Python and React',
  parsed_data: {
    required_skills: ['Python', 'React'],
    experience_level: 'Senior',
    min_years_experience: 5
  },
  is_active: true,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
  ...overrides
})
```

### Backend Test Factories

```python
# tests/factories.py
import factory
from factory.alchemy import SQLAlchemyModelFactory
from app.models import User, Resume, Subscription, SubscriptionPlan
from app.core.security import get_password_hash

class UserFactory(SQLAlchemyModelFactory):
    """Factory for creating test users."""
    
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    hashed_password = factory.LazyFunction(lambda: get_password_hash("testpass123"))
    full_name = factory.Faker("name")
    company = factory.Faker("company")
    job_title = factory.Faker("job")
    is_active = True

class SubscriptionPlanFactory(SQLAlchemyModelFactory):
    """Factory for creating subscription plans."""
    
    class Meta:
        model = SubscriptionPlan
        sqlalchemy_session_persistence = "commit"

    name = factory.Iterator(["Free", "Pro", "Team", "Enterprise"])
    slug = factory.LazyAttribute(lambda obj: obj.name.lower())
    price_monthly = factory.Faker("random_int", min=0, max=99999)
    features = factory.LazyFunction(lambda: {
        "resume_uploads_per_month": 10,
        "job_analyses_per_month": 50,
        "advanced_analytics": True
    })
    limits = factory.LazyFunction(lambda: {
        "max_resumes": 25,
        "max_file_size": 10485760,
        "rate_limit_per_hour": 100
    })
    is_active = True

class SubscriptionFactory(SQLAlchemyModelFactory):
    """Factory for creating subscriptions."""
    
    class Meta:
        model = Subscription
        sqlalchemy_session_persistence = "commit"

    user = factory.SubFactory(UserFactory)
    plan = factory.SubFactory(SubscriptionPlanFactory)
    status = "active"
    stripe_subscription_id = factory.Faker("uuid4")
    stripe_customer_id = factory.Faker("uuid4")

class ResumeFactory(SQLAlchemyModelFactory):
    """Factory for creating resumes."""
    
    class Meta:
        model = Resume
        sqlalchemy_session_persistence = "commit"

    user = factory.SubFactory(UserFactory)
    title = factory.Faker("sentence", nb_words=3)
    filename = factory.Faker("file_name", extension="pdf")
    file_path = factory.LazyAttribute(lambda obj: f"resumes/{obj.user.id}/{obj.filename}")
    file_size = factory.Faker("random_int", min=100000, max=10000000)
    mime_type = "application/pdf"
    content_text = factory.Faker("text", max_nb_chars=2000)
    parsed_data = factory.LazyFunction(lambda: {
        "personal_info": {
            "name": "John Doe",
            "email": "john@example.com"
        },
        "skills": ["Python", "React", "SQL"],
        "experience": []
    })
    is_active = True

# Usage in tests
def test_user_with_resume(db_session):
    user = UserFactory(db_session=db_session)
    resume = ResumeFactory(user=user, db_session=db_session)
    
    assert resume.user == user
    assert len(user.resumes) == 1
```

## Mock Service Worker (MSW) Setup

```typescript
// src/mocks/handlers.ts
import { rest } from 'msw'
import { createMockUser, createMockResume } from '@/test-utils/factories'

export const handlers = [
  // Auth endpoints
  rest.post('/api/v1/auth/signin', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        user: createMockUser(),
        session: {
          access_token: 'mock-jwt-token',
          refresh_token: 'mock-refresh-token',
          expires_in: 3600
        }
      })
    )
  }),

  rest.post('/api/v1/auth/signup', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        user: createMockUser(),
        message: 'Account created successfully'
      })
    )
  }),

  rest.get('/api/v1/auth/me', (req, res, ctx) => {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return res(ctx.status(401), ctx.json({ detail: 'Unauthorized' }))
    }

    return res(ctx.status(200), ctx.json(createMockUser()))
  }),

  // Resume endpoints
  rest.get('/api/v1/resumes', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        resumes: [createMockResume()],
        pagination: {
          page: 1,
          limit: 20,
          total: 1,
          total_pages: 1
        }
      })
    )
  }),

  rest.post('/api/v1/resumes/upload', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json(createMockResume())
    )
  }),

  // Error scenarios
  rest.post('/api/v1/auth/signin', (req, res, ctx) => {
    return res.once(
      ctx.status(401),
      ctx.json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      })
    )
  })
]

// src/mocks/server.ts
import { setupServer } from 'msw/node'
import { handlers } from './handlers'

export const server = setupServer(...handlers)
```

## Performance Testing

```typescript
// tests/performance/component-performance.test.tsx
import React from 'react'
import { render } from '@testing-library/react'
import { ResumeList } from '@/components/ResumeList'
import { createMockResume } from '@/test-utils/factories'

describe('ResumeList Performance', () => {
  it('renders large list efficiently', () => {
    const largeResumeList = Array.from({ length: 1000 }, (_, i) =>
      createMockResume({ id: `resume-${i}`, title: `Resume ${i}` })
    )

    const startTime = performance.now()
    
    render(<ResumeList resumes={largeResumeList} />)
    
    const endTime = performance.now()
    const renderTime = endTime - startTime

    // Should render in less than 100ms
    expect(renderTime).toBeLessThan(100)
  })

  it('handles rapid re-renders', () => {
    const { rerender } = render(<ResumeList resumes={[]} />)

    const startTime = performance.now()
    
    // Simulate 100 rapid updates
    for (let i = 0; i < 100; i++) {
      rerender(<ResumeList resumes={[createMockResume({ id: `resume-${i}` })]} />)
    }
    
    const endTime = performance.now()
    const totalTime = endTime - startTime

    // Should handle 100 re-renders in less than 500ms
    expect(totalTime).toBeLessThan(500)
  })
})
```

## Test Automation & CI Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  frontend-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: frontend/package-lock.json
    
    - name: Install dependencies
      working-directory: ./frontend
      run: npm ci
    
    - name: Run type check
      working-directory: ./frontend
      run: npm run type-check
    
    - name: Run linting
      working-directory: ./frontend
      run: npm run lint
    
    - name: Run unit tests
      working-directory: ./frontend
      run: npm run test:ci
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./frontend/coverage/lcov.info
        flags: frontend

  backend-tests:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      working-directory: ./backend
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run linting
      working-directory: ./backend
      run: |
        flake8 app/
        black --check app/
        isort --check-only app/
    
    - name: Run type checking
      working-directory: ./backend
      run: mypy app/
    
    - name: Run unit tests
      working-directory: ./backend
      run: pytest -xvs
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./backend/coverage.xml
        flags: backend
```

---

**Next Steps**: Review `integration-tests.md` for API and database integration testing and `e2e-tests.md` for end-to-end user flow testing.