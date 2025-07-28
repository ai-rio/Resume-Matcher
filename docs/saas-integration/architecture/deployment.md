# Deployment Architecture

## Overview

The Resume-Matcher SaaS platform deployment strategy focuses on scalability, reliability, and cost-effectiveness using modern cloud infrastructure with automated CI/CD pipelines.

## Deployment Strategy

### Core Principles
- **Infrastructure as Code**: All infrastructure defined in code
- **Blue-Green Deployments**: Zero-downtime deployments
- **Auto-scaling**: Automatic scaling based on demand
- **Multi-environment**: Development, staging, and production environments
- **Monitoring**: Comprehensive monitoring and alerting
- **Security**: Security-first approach with compliance standards

## Infrastructure Overview

```mermaid
graph TB
    subgraph "CDN Layer"
        A[Cloudflare CDN]
        B[Global Edge Locations]
    end
    
    subgraph "Load Balancer"
        C[Application Load Balancer]
        D[SSL Termination]
    end
    
    subgraph "Frontend"
        E[Vercel - Next.js App]
        F[Static Assets]
        G[Edge Functions]
    end
    
    subgraph "Backend Services"
        H[Railway - FastAPI]
        I[Background Workers]
        J[File Processing Queue]
    end
    
    subgraph "Database & Storage"
        K[Supabase PostgreSQL]
        L[Supabase Storage]
        M[Redis Cache]
    end
    
    subgraph "External Services"
        N[Stripe Payments]
        O[SendGrid Email]
        P[Sentry Monitoring]
    end
    
    A --> C
    C --> E
    C --> H
    E --> H
    H --> K
    H --> L
    H --> M
    H --> N
    H --> O
    H --> P
```

## Environment Configuration

### 1. Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - supabase

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=development
      - DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
      - SUPABASE_URL=http://localhost:54321
      - SUPABASE_SERVICE_KEY=${SUPABASE_SERVICE_KEY}
    volumes:
      - ./backend:/app
    depends_on:
      - supabase

  supabase:
    image: supabase/cli:latest
    ports:
      - "54321:54321"
      - "54322:54322"
    command: supabase start
    volumes:
      - ./supabase:/workspace
```

### 2. Staging Environment

**Vercel Configuration (`vercel.json`):**
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-staging-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-staging-anon-key",
    "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY": "@stripe-staging-key",
    "NEXT_PUBLIC_APP_URL": "https://staging.resume-matcher.com"
  },
  "functions": {
    "pages/api/**/*.ts": {
      "maxDuration": 30
    }
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
```

**Railway Configuration (`railway.toml`):**
```toml
[build]
builder = "nixpacks"
buildCommand = "pip install -r requirements.txt"

[deploy]
startCommand = "uvicorn app.main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 10

[env]
ENVIRONMENT = "staging"
DATABASE_URL = "${{Postgres.DATABASE_URL}}"
SUPABASE_URL = "${{SUPABASE_STAGING_URL}}"
SUPABASE_SERVICE_KEY = "${{SUPABASE_STAGING_SERVICE_KEY}}"
STRIPE_SECRET_KEY = "${{STRIPE_STAGING_SECRET_KEY}}"
REDIS_URL = "${{Redis.REDIS_URL}}"
```

### 3. Production Environment

**Terraform Infrastructure (`infrastructure/main.tf`):**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 0.15"
    }
  }
}

# CloudFlare Configuration
resource "cloudflare_zone" "main" {
  zone = "resume-matcher.com"
}

resource "cloudflare_record" "api" {
  zone_id = cloudflare_zone.main.id
  name    = "api"
  value   = var.railway_domain
  type    = "CNAME"
  proxied = true
}

# AWS Application Load Balancer
resource "aws_lb" "main" {
  name               = "resume-matcher-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id

  enable_deletion_protection = true

  tags = {
    Environment = "production"
    Project     = "resume-matcher"
  }
}

# Auto Scaling Group for Backend
resource "aws_autoscaling_group" "backend" {
  name                = "resume-matcher-backend"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.backend.arn]
  health_check_type   = "ELB"

  min_size         = 2
  max_size         = 10
  desired_capacity = 3

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "resume-matcher-backend"
    propagate_at_launch = true
  }
}

# RDS for PostgreSQL (if not using Supabase)
resource "aws_db_instance" "main" {
  identifier     = "resume-matcher-db"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  allocated_storage = 20
  
  db_name  = "resumematcher"
  username = "postgres"
  password = var.db_password
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"
  
  skip_final_snapshot = false
  deletion_protection = true
  
  tags = {
    Environment = "production"
    Project     = "resume-matcher"
  }
}

# Redis for Caching
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "resume-matcher-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  tags = {
    Environment = "production"
    Project     = "resume-matcher"
  }
}
```

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.11'

jobs:
  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        working-directory: ./frontend
        run: npm ci
      
      - name: Run type check
        working-directory: ./frontend
        run: npm run type-check
      
      - name: Run tests
        working-directory: ./frontend
        run: npm run test:ci
      
      - name: Build application
        working-directory: ./frontend
        run: npm run build

  test-backend:
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
          python-version: ${{ env.PYTHON_VERSION }}
      
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
      
      - name: Run tests
        working-directory: ./backend
        run: |
          pytest --cov=app --cov-report=xml
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: ./backend/coverage.xml

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --all-projects

  deploy-staging:
    needs: [test-frontend, test-backend, security-scan]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy Frontend to Vercel (Staging)
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
          alias-domains: staging.resume-matcher.com
      
      - name: Deploy Backend to Railway (Staging)
        uses: railway-app/railway-action@v1
        with:
          api-token: ${{ secrets.RAILWAY_TOKEN }}
          service: backend-staging
          environment: staging

  deploy-production:
    needs: [test-frontend, test-backend, security-scan]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy Frontend to Vercel (Production)
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./frontend
          vercel-args: '--prod'
          alias-domains: app.resume-matcher.com
      
      - name: Deploy Backend to Railway (Production)
        uses: railway-app/railway-action@v1
        with:
          api-token: ${{ secrets.RAILWAY_TOKEN }}
          service: backend-production
          environment: production
      
      - name: Run Database Migrations
        run: |
          python -m alembic upgrade head
        env:
          DATABASE_URL: ${{ secrets.PRODUCTION_DATABASE_URL }}
      
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Container Configuration

### Frontend Dockerfile

```dockerfile
# frontend/Dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash app
RUN chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Monitoring and Observability

### Application Monitoring

```python
# app/monitoring.py
import os
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from prometheus_client import Counter, Histogram, generate_latest
import time

# Initialize Sentry
sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN"),
    integrations=[
        FastApiIntegration(auto_enabling_integrations=False),
        SqlalchemyIntegration(),
    ],
    traces_sample_rate=0.1,
    environment=os.getenv("ENVIRONMENT", "development")
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total', 
    'Total HTTP requests', 
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

# Middleware for metrics collection
async def metrics_middleware(request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response
```

### Health Checks

```python
# app/health.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.redis_client import redis_client
import asyncio

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": "2024-01-15T10:30:00Z"}

@router.get("/health/detailed")
async def detailed_health_check(db: Session = Depends(get_db)):
    checks = {}
    
    # Database check
    try:
        db.execute("SELECT 1")
        checks["database"] = "healthy"
    except Exception as e:
        checks["database"] = f"unhealthy: {str(e)}"
    
    # Redis check
    try:
        await redis_client.ping()
        checks["redis"] = "healthy"
    except Exception as e:
        checks["redis"] = f"unhealthy: {str(e)}"
    
    # Supabase check
    try:
        # Add Supabase connectivity check
        checks["supabase"] = "healthy"
    except Exception as e:
        checks["supabase"] = f"unhealthy: {str(e)}"
    
    overall_status = "healthy" if all(
        status == "healthy" for status in checks.values()
    ) else "unhealthy"
    
    return {
        "status": overall_status,
        "checks": checks,
        "timestamp": "2024-01-15T10:30:00Z"
    }
```

## Database Migrations

### Alembic Configuration

```python
# alembic/env.py
import asyncio
from logging.config import fileConfig
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context
from app.models import Base

config = context.config
fileConfig(config.config_file_name)
target_metadata = Base.metadata

def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

## Performance Optimization

### CDN Configuration

```javascript
// next.config.js
const nextConfig = {
  images: {
    domains: ['supabase-storage-url'],
    loader: 'custom',
    loaderFile: './lib/imageLoader.js'
  },
  async headers() {
    return [
      {
        source: '/_next/static/(.*)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable'
          }
        ]
      },
      {
        source: '/api/(.*)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-cache, no-store, must-revalidate'
          }
        ]
      }
    ]
  }
}

module.exports = nextConfig
```

### Caching Strategy

```python
# app/cache.py
import redis
import json
from typing import Any, Optional
from functools import wraps

redis_client = redis.from_url(os.getenv("REDIS_URL"))

def cache(expiration: int = 3600):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Create cache key
            cache_key = f"{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Try to get from cache
            cached_result = redis_client.get(cache_key)
            if cached_result:
                return json.loads(cached_result)
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            redis_client.setex(
                cache_key, 
                expiration, 
                json.dumps(result, default=str)
            )
            
            return result
        return wrapper
    return decorator
```

## Disaster Recovery

### Backup Strategy

```bash
#!/bin/bash
# scripts/backup.sh

# Database backup
pg_dump $DATABASE_URL > "backup_$(date +%Y%m%d_%H%M%S).sql"

# Upload to S3
aws s3 cp backup_*.sql s3://resume-matcher-backups/database/

# File storage backup (if not using Supabase)
rclone sync supabase:storage s3:resume-matcher-backups/storage/

# Clean up old backups (keep 30 days)
find . -name "backup_*.sql" -mtime +30 -delete
aws s3 ls s3://resume-matcher-backups/database/ | while read -r line; do
  createDate=$(echo $line | awk '{print $1" "$2}')
  createDate=$(date -d"$createDate" +%s)
  olderThan=$(date -d"30 days ago" +%s)
  if [[ $createDate -lt $olderThan ]]; then
    fileName=$(echo $line | awk '{print $4}')
    aws s3 rm s3://resume-matcher-backups/database/$fileName
  fi
done
```

### Recovery Procedures

```bash
#!/bin/bash
# scripts/recovery.sh

# Restore database from backup
psql $DATABASE_URL < backup_20240115_103000.sql

# Restore file storage
rclone sync s3:resume-matcher-backups/storage/ supabase:storage

# Verify data integrity
python scripts/verify_data_integrity.py
```

## Security Measures

### WAF Configuration

```yaml
# cloudflare-waf-rules.yml
rules:
  - description: "Block known malicious IPs"
    expression: "(ip.src in $malicious_ips)"
    action: "block"
  
  - description: "Rate limit API calls"
    expression: "(http.request.uri.path matches \"/api/.*\")"
    action: "rate_limit"
    rate_limit:
      threshold: 100
      period: 60
  
  - description: "Block file upload attacks"
    expression: "(http.request.method eq \"POST\" and http.request.uri.path matches \"/api/resumes/upload\")"
    action: "challenge"
```

### SSL/TLS Configuration

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.resume-matcher.com;
    
    ssl_certificate /etc/ssl/certs/resume-matcher.crt;
    ssl_certificate_key /etc/ssl/private/resume-matcher.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

**Next Steps**: Review `deployment/environments.md` for detailed environment setup and `monitoring/performance.md` for comprehensive monitoring configuration.