# Langfuse Local Setup - Corporate Environment

Complete Docker setup for running Langfuse locally in corporate environments with restricted Docker registry access.

## Quick Start

**See [QUICK-START.md](QUICK-START.md) for detailed step-by-step instructions.**

```bash
# 1. Update docker-compose.yml with your internal registry URLs
#    (Search for "REPLACE:" comments - 5 images to update)

# 2. Configure environment (all passwords in ONE place)
cp .env.example .env
openssl rand -base64 32  # For NEXTAUTH_SECRET
openssl rand -base64 32  # For SALT
# Edit .env with generated secrets and passwords

# 3. Start services
docker-compose up -d

# 4. Initialize MinIO
./init-minio.sh

# 5. Access Langfuse
open http://localhost:3000
```

## Files Included

- **docker-compose.yml** - Complete Docker Compose configuration (reads from .env)
- **.env.example** - Environment variables template
- **init-minio.sh** - MinIO bucket initialization script
- **QUICK-START.md** - Step-by-step setup instructions ⭐ START HERE
- **SETUP-GUIDE.md** - Comprehensive setup and troubleshooting guide

## What You Need to Do

### 1. Replace Docker Image URLs

Open `docker-compose.yml` and replace all images with your internal registry URLs:

| Service | Image to Replace |
|---------|-----------------|
| postgres | `postgres:16-alpine` |
| redis | `redis:7-alpine` |
| minio | `minio/minio:latest` |
| langfuse-web | `langfuse/langfuse:latest` |
| langfuse-worker | `langfuse/langfuse:latest` |

Example:
```yaml
# Change from:
image: postgres:16-alpine

# To:
image: your-registry.company.com/postgres:16-alpine
```

### 2. Configure Secrets

```bash
# Generate secrets
openssl rand -base64 32  # For NEXTAUTH_SECRET
openssl rand -base64 32  # For SALT

# Update .env file with generated values
```

### 3. Deploy

```bash
docker-compose up -d
./init-minio.sh
```

## Components

This setup includes:

- **Langfuse Web** (port 3000) - Main application
- **Langfuse Worker** - Background job processor
- **PostgreSQL 16** (port 5432) - Database
- **Redis 7** (port 6379) - Cache
- **MinIO** (ports 9000, 9001) - S3-compatible storage

## Documentation

See **[SETUP-GUIDE.md](SETUP-GUIDE.md)** for:
- Detailed setup instructions
- Configuration options
- Troubleshooting guide
- Maintenance procedures
- Production considerations

## Support

- **Setup issues**: See SETUP-GUIDE.md troubleshooting section
- **Langfuse issues**: https://github.com/langfuse/langfuse/issues
- **Corporate registry**: Contact your platform team

## Security Notes

⚠️ **Before deploying:**
- Change all default passwords
- Generate secure random secrets
- Use HTTPS in production
- Enable authentication on all services
- Review security section in SETUP-GUIDE.md
