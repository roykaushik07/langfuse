# Langfuse Local Setup Guide - Corporate Environment

This guide will help you set up Langfuse locally in a corporate environment where external Docker registries are restricted.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Image Preparation](#image-preparation)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

---

## Prerequisites

### Required Software

- Docker Engine 20.10+
- Docker Compose v2.0+
- MinIO Client (mc) - will be installed by init script if not present
- Access to your corporate Docker registry

### Required Docker Images

Ensure the following images are available in your internal Docker registry:

| Component | Public Image | Description |
|-----------|--------------|-------------|
| Langfuse Web | `langfuse/langfuse:latest` | Main Langfuse application |
| Langfuse Worker | `langfuse/langfuse:latest` | Background worker (same image) |
| PostgreSQL | `postgres:16-alpine` | Transactional database |
| ClickHouse | `clickhouse/clickhouse-server:latest` | OLAP database for traces/observations (v24.3+) |
| Redis | `redis:7-alpine` | Cache and session store |
| MinIO | `minio/minio:latest` | S3-compatible object storage |

---

## Image Preparation

### Step 1: Update docker-compose.yml with Internal Registry URLs

Open `docker-compose.yml` and replace all image references with your internal registry URLs. Look for comments marked with `REPLACE:`.

**Example replacements:**

```yaml
# Before
image: postgres:16-alpine

# After (replace with your actual registry URL)
image: your-registry.company.com/postgres:16-alpine
```

**All images to replace:**

1. **PostgreSQL** (service: `postgres`)
   ```yaml
   image: your-registry.company.com/postgres:16-alpine
   ```

2. **Redis** (service: `redis`)
   ```yaml
   image: your-registry.company.com/redis:7-alpine
   ```

3. **ClickHouse** (service: `clickhouse`)
   ```yaml
   image: your-registry.company.com/clickhouse/clickhouse-server:latest
   ```

4. **MinIO** (service: `minio`)
   ```yaml
   image: your-registry.company.com/minio/minio:latest
   ```

5. **Langfuse Web** (service: `langfuse-web`)
   ```yaml
   image: your-registry.company.com/langfuse/langfuse:latest
   ```

6. **Langfuse Worker** (service: `langfuse-worker`)
   ```yaml
   image: your-registry.company.com/langfuse/langfuse:latest
   ```

### Step 2: Pull Images to Internal Registry (If Not Already Available)

If you need to pull and push images to your internal registry:

```bash
# Pull from public registry (on a machine with external access)
docker pull langfuse/langfuse:latest
docker pull postgres:16-alpine
docker pull redis:7-alpine
docker pull clickhouse/clickhouse-server:latest
docker pull minio/minio:latest

# Tag for your internal registry
docker tag langfuse/langfuse:latest your-registry.company.com/langfuse/langfuse:latest
docker tag postgres:16-alpine your-registry.company.com/postgres:16-alpine
docker tag redis:7-alpine your-registry.company.com/redis:7-alpine
docker tag clickhouse/clickhouse-server:latest your-registry.company.com/clickhouse/clickhouse-server:latest
docker tag minio/minio:latest your-registry.company.com/minio/minio:latest

# Push to internal registry
docker push your-registry.company.com/langfuse/langfuse:latest
docker push your-registry.company.com/postgres:16-alpine
docker push your-registry.company.com/redis:7-alpine
docker push your-registry.company.com/clickhouse/clickhouse-server:latest
docker push your-registry.company.com/minio/minio:latest
```

---

## Configuration

### Step 1: Create Environment File

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

### Step 2: Generate Secrets

Generate secure random secrets for sensitive configuration:

```bash
# Generate NEXTAUTH_SECRET (minimum 32 characters)
openssl rand -base64 32

# Generate SALT
openssl rand -base64 32
```

### Step 3: Update .env File

Edit `.env` and update at minimum:

```bash
# Database
POSTGRES_PASSWORD=<strong-password>

# Redis
REDIS_PASSWORD=<strong-password>

# NextAuth (use output from openssl rand -base64 32)
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=<generated-secret>

# Salt (use output from openssl rand -base64 32)
SALT=<generated-salt>

# MinIO
MINIO_ROOT_PASSWORD=<strong-password>
S3_SECRET_ACCESS_KEY=<strong-password>
```

### Step 4: Configure for Production (Optional)

For production deployments, also configure:

- **Custom Domain**: Update `NEXTAUTH_URL` to your actual domain
- **SMTP**: Configure email settings for notifications
- **SSO**: Set up OAuth providers (Google, Azure AD, Okta, etc.)
- **TLS/SSL**: Add reverse proxy configuration (nginx, Traefik, etc.)

---

## Deployment

### Step 1: Start Services

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Step 2: Verify Services Are Running

```bash
# Check status
docker-compose ps

# All services should show "Up" and "healthy"
```

Expected output:
```
NAME                 STATUS
langfuse-postgres    Up (healthy)
langfuse-redis       Up (healthy)
langfuse-minio       Up (healthy)
langfuse-web         Up (healthy)
langfuse-worker      Up (healthy)
```

### Step 3: Initialize MinIO Bucket

```bash
# Run the MinIO initialization script
./init-minio.sh
```

This script will:
- Create the required `langfuse` bucket
- Set appropriate permissions
- Configure access policies

### Step 4: Run Database Migrations

The Langfuse container automatically runs migrations on startup. Check logs to verify:

```bash
docker-compose logs langfuse-web | grep -i migration
```

---

## Verification

### Access Points

1. **Langfuse Web UI**: http://localhost:3000
2. **MinIO Console**: http://localhost:9001
3. **PostgreSQL**: localhost:5432
4. **Redis**: localhost:6379

### Create First User

1. Open http://localhost:3000 in your browser
2. Click "Sign Up"
3. Create an account with your email
4. Verify you can log in successfully

### Test API Health

```bash
# Check health endpoint
curl http://localhost:3000/api/public/health

# Expected response: {"status":"OK"}
```

### Verify Worker is Processing Jobs

```bash
# Check worker logs
docker-compose logs -f langfuse-worker

# You should see periodic activity
```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker-compose logs <service-name>
```

**Common issues:**

1. **Port conflicts**: Another service is using ports 3000, 5432, 6379, 9000, or 9001
   - Solution: Change port mappings in docker-compose.yml

2. **Image pull errors**: Cannot access internal registry
   - Solution: Verify registry URL and authentication
   ```bash
   docker login your-registry.company.com
   ```

3. **Health check failures**: Service not responding
   - Solution: Increase health check intervals or start_period

### Database Connection Issues

**Symptoms:** Langfuse cannot connect to PostgreSQL

**Checks:**
```bash
# Verify PostgreSQL is accessible
docker exec langfuse-postgres pg_isready -U langfuse

# Test connection from langfuse-web container
docker exec langfuse-web psql $DATABASE_URL -c "SELECT 1"
```

**Solutions:**
- Verify DATABASE_URL format in .env
- Ensure passwords match between services
- Check PostgreSQL logs for authentication errors

### MinIO/S3 Upload Failures

**Symptoms:** Cannot upload files or media

**Checks:**
```bash
# Verify bucket exists
docker exec langfuse-minio mc ls local/

# Check MinIO logs
docker-compose logs minio
```

**Solutions:**
- Re-run `./init-minio.sh`
- Verify S3 credentials match in .env and docker-compose.yml
- Check network connectivity between services

### Worker Not Processing Jobs

**Symptoms:** Background tasks not completing

**Checks:**
```bash
# Verify worker is running
docker-compose ps langfuse-worker

# Check worker logs
docker-compose logs langfuse-worker
```

**Solutions:**
- Verify Redis connection string
- Restart worker: `docker-compose restart langfuse-worker`
- Check for errors in worker logs

### Memory or Performance Issues

**Checks:**
```bash
# Check resource usage
docker stats

# Check available disk space
df -h
```

**Solutions:**
- Increase Docker memory allocation
- Add resource limits in docker-compose.yml:
  ```yaml
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
  ```

---

## Maintenance

### Backup

#### Database Backup

```bash
# Create backup
docker exec langfuse-postgres pg_dump -U langfuse langfuse > backup_$(date +%Y%m%d).sql

# Restore from backup
docker exec -i langfuse-postgres psql -U langfuse langfuse < backup_20231201.sql
```

#### Volume Backup

```bash
# Backup all volumes
docker run --rm \
  -v langfuse_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data_backup.tar.gz -C /data .

# Repeat for redis_data and minio_data volumes
```

### Updates

#### Update Langfuse Version

```bash
# Pull new image (from your internal registry)
docker pull your-registry.company.com/langfuse/langfuse:v2.x.x

# Update docker-compose.yml with new version tag
# Then restart services
docker-compose down
docker-compose up -d
```

#### Update Other Components

Follow the same process for PostgreSQL, Redis, and MinIO updates.

**Important:** Always backup before updating!

### Logs Management

```bash
# View logs
docker-compose logs -f [service-name]

# Clear logs (restart containers)
docker-compose restart

# Configure log rotation in docker-compose.yml:
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Cleanup

```bash
# Stop services
docker-compose down

# Stop and remove volumes (⚠️ DELETES ALL DATA)
docker-compose down -v

# Remove unused images
docker image prune -a
```

---

## Production Considerations

### Security

1. **Change all default passwords** in .env file
2. **Use strong secrets** for NEXTAUTH_SECRET and SALT
3. **Enable HTTPS** with reverse proxy (nginx, Traefik)
4. **Restrict network access** using Docker networks
5. **Regular security updates** for all components
6. **Enable authentication** on Redis and PostgreSQL
7. **Use secrets management** (Docker secrets, Vault, etc.)

### Scalability

1. **External Database**: Use managed PostgreSQL for production
2. **External Redis**: Use managed Redis/ElastiCache
3. **External S3**: Use corporate S3 or cloud storage
4. **Multiple Workers**: Scale workers horizontally:
   ```bash
   docker-compose up -d --scale langfuse-worker=3
   ```
5. **Load Balancer**: Add nginx/Traefik for multiple web instances

### Monitoring

Add monitoring tools:

1. **Prometheus + Grafana** for metrics
2. **Loki** for log aggregation
3. **Health checks** for uptime monitoring
4. **Alerting** for critical issues

Example monitoring stack addition:
```yaml
# Add to docker-compose.yml
prometheus:
  image: your-registry.company.com/prom/prometheus:latest
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: your-registry.company.com/grafana/grafana:latest
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

### High Availability

For HA setup:

1. **Multiple web instances** behind load balancer
2. **Multiple worker instances** for job processing
3. **PostgreSQL replication** (primary + replicas)
4. **Redis Sentinel** for automatic failover
5. **Distributed MinIO** cluster

---

## Additional Resources

- **Langfuse Documentation**: https://langfuse.com/docs
- **Docker Documentation**: https://docs.docker.com
- **PostgreSQL Documentation**: https://www.postgresql.org/docs
- **Redis Documentation**: https://redis.io/docs
- **MinIO Documentation**: https://min.io/docs

---

## Support

For issues specific to:
- **Langfuse**: https://github.com/langfuse/langfuse/issues
- **Corporate setup**: Contact your internal platform team

---

## Quick Reference Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service]

# Restart service
docker-compose restart [service]

# Check status
docker-compose ps

# Execute command in container
docker-compose exec [service] [command]

# Backup database
docker exec langfuse-postgres pg_dump -U langfuse langfuse > backup.sql

# Access PostgreSQL
docker exec -it langfuse-postgres psql -U langfuse

# Access Redis
docker exec -it langfuse-redis redis-cli -a <password>

# Check health
curl http://localhost:3000/api/public/health
```
