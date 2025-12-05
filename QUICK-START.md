# Quick Start Guide

## How Environment Variables Work

The `docker-compose.yml` file now **automatically reads from your `.env` file**. You only need to configure passwords and secrets in **ONE place** - the `.env` file.

### Example

In `.env`:
```bash
POSTGRES_PASSWORD=my_secure_password_123
```

In `docker-compose.yml`:
```yaml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
```

Docker Compose will automatically substitute `${POSTGRES_PASSWORD}` with `my_secure_password_123`.

### Default Values

Some variables have defaults (using `:-` syntax):
```yaml
POSTGRES_DB: ${POSTGRES_DB:-langfuse}
```

This means:
- If `POSTGRES_DB` is set in `.env`, use that value
- If not set, use the default value `langfuse`

---

## Setup Steps

### 1. Update Docker Images

Edit `docker-compose.yml` and replace **6 image URLs** with your internal registry:

```yaml
# Find these lines and replace:
image: postgres:16-alpine                     → your-registry.company.com/postgres:16-alpine
image: redis:7-alpine                         → your-registry.company.com/redis:7-alpine
image: clickhouse/clickhouse-server:latest    → your-registry.company.com/clickhouse/clickhouse-server:latest
image: minio/minio:latest                     → your-registry.company.com/minio/minio:latest
image: langfuse/langfuse:latest               → your-registry.company.com/langfuse/langfuse:latest
(appears twice - web and worker)
```

### 2. Create .env File

```bash
cp .env.example .env
```

### 3. Generate Secrets

```bash
# Generate NEXTAUTH_SECRET
openssl rand -base64 32

# Generate SALT
openssl rand -base64 32
```

### 4. Edit .env File

Open `.env` and update these required values:

```bash
# Database password
POSTGRES_PASSWORD=YOUR_STRONG_PASSWORD_HERE

# Redis password
REDIS_PASSWORD=YOUR_STRONG_PASSWORD_HERE

# ClickHouse password
CLICKHOUSE_PASSWORD=YOUR_STRONG_PASSWORD_HERE

# NextAuth secret (paste output from: openssl rand -base64 32)
NEXTAUTH_SECRET=PASTE_GENERATED_SECRET_HERE

# Salt (paste output from: openssl rand -base64 32)
SALT=PASTE_GENERATED_SALT_HERE

# MinIO password
MINIO_ROOT_PASSWORD=YOUR_STRONG_PASSWORD_HERE

# The connection strings will be automatically built using these passwords
DATABASE_URL=postgresql://langfuse:YOUR_STRONG_PASSWORD_HERE@postgres:5432/langfuse
DIRECT_URL=postgresql://langfuse:YOUR_STRONG_PASSWORD_HERE@postgres:5432/langfuse
REDIS_CONNECTION_STRING=redis://:YOUR_STRONG_PASSWORD_HERE@redis:6379
S3_SECRET_ACCESS_KEY=YOUR_STRONG_PASSWORD_HERE
```

**Important:** Make sure the passwords in `DATABASE_URL`, `REDIS_CONNECTION_STRING`, and `S3_SECRET_ACCESS_KEY` match the passwords you set above!

### 5. Start Services

```bash
docker-compose up -d
```

### 6. Check Services

```bash
docker-compose ps
```

All services should show "Up" and "healthy".

### 7. Initialize MinIO

```bash
./init-minio.sh
```

### 8. Access Langfuse

Open in browser: http://localhost:3000

---

## Verification

```bash
# Check all services are running
docker-compose ps

# View logs
docker-compose logs -f

# Test health endpoint
curl http://localhost:3000/api/public/health
# Should return: {"status":"OK"}
```

---

## Common Issues

### Passwords Don't Match

**Symptom:** Services fail to connect to each other

**Solution:** Make sure passwords match in ALL places in `.env`:
- `POSTGRES_PASSWORD` must match the password in `DATABASE_URL`
- `REDIS_PASSWORD` must match the password in `REDIS_CONNECTION_STRING`
- `MINIO_ROOT_PASSWORD` must match `S3_SECRET_ACCESS_KEY`

### Port Conflicts

**Symptom:** `Error: port is already allocated`

**Solution:** Change the host port (left side) in docker-compose.yml:
```yaml
ports:
  - "5433:5432"  # Changed from 5432:5432
```

### Image Pull Errors

**Symptom:** `Error response from daemon: pull access denied`

**Solution:**
1. Verify you've replaced image URLs with your internal registry
2. Authenticate with your registry: `docker login your-registry.company.com`

---

## Complete .env Example

Here's what a complete `.env` file looks like (with example values):

```bash
# Database
POSTGRES_DB=langfuse
POSTGRES_USER=langfuse
POSTGRES_PASSWORD=P@ssw0rd123!Secure

# Database URLs (must use same password as above)
DATABASE_URL=postgresql://langfuse:P@ssw0rd123!Secure@postgres:5432/langfuse
DIRECT_URL=postgresql://langfuse:P@ssw0rd123!Secure@postgres:5432/langfuse

# Redis
REDIS_PASSWORD=R3dis!P@ssw0rd456
REDIS_CONNECTION_STRING=redis://:R3dis!P@ssw0rd456@redis:6379

# ClickHouse
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=Click!H0use789!Secure
CLICKHOUSE_DB=default
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000
CLICKHOUSE_CLUSTER_ENABLED=false

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=Xk7mP9nQ2rS5tU8vW1yZ3aB4cD6eF8gH0iJ2kL4mN6oP8qR0sT2uV4wX6yZ8aB0c

# Salt
SALT=A1bC2dE3fG4hI5jK6lM7nO8pQ9rS0tU1vW2xY3zA4bC5dE6fG7hI8jK9lM0nO1p

# MinIO
MINIO_ROOT_USER=minio_admin
MINIO_ROOT_PASSWORD=Min!0P@ssw0rd789
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY_ID=minio_admin
S3_SECRET_ACCESS_KEY=Min!0P@ssw0rd789
S3_BUCKET_NAME=langfuse
S3_REGION=us-east-1

# Application
NODE_ENV=production
TELEMETRY_ENABLED=0
```

---

## What's Next?

For detailed information, see:
- **SETUP-GUIDE.md** - Comprehensive setup and troubleshooting
- **README.md** - Overview and file descriptions

---

## Quick Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Restart a service
docker-compose restart [service-name]

# Check status
docker-compose ps

# Access PostgreSQL
docker exec -it langfuse-postgres psql -U langfuse

# Access MinIO Console
open http://localhost:9001
```
