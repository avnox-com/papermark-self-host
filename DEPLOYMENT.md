# Papermark Self-Hosted Deployment Guide

Complete guide for deploying Papermark on Docker Swarm with Traefik.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Maintenance](#maintenance)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- Docker Engine 20.10+ with Swarm mode enabled
- Traefik v2+ configured as reverse proxy
- Minimum 2GB RAM, 4GB recommended
- 20GB disk space minimum

### Required External Services

1. **PostgreSQL Database** (included in stack) OR external PostgreSQL
2. **S3-Compatible Storage** (AWS S3, MinIO, Backblaze B2, etc.)
3. **Email Service** (Resend recommended)
4. **Optional**: Redis (included), Tinybird (analytics)

### DNS Configuration

Ensure your domain points to your Docker Swarm cluster:

```bash
# Example DNS records
papermark.yourdomain.com    A     YOUR_SERVER_IP
```

## Quick Start

### 1. Clone Your Repository

```bash
git clone https://github.com/your-org/your-papermark-deploy.git
cd your-papermark-deploy
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with your values
nano .env
```

**Minimum required configuration:**

```bash
# Core
PAPERMARK_PUBLIC_URL=https://papermark.yourdomain.com
PAPERMARK_DOMAIN=papermark.yourdomain.com

# Security
NEXTAUTH_SECRET=$(openssl rand -hex 32)

# Database
POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Storage (choose one)
# Option 1: AWS S3
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_S3_BUCKET_NAME=papermark-uploads
AWS_REGION=us-east-1

# Email
RESEND_API_KEY=re_xxxxxxxxxxxxx

# Authentication (at least one)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### 3. Initialize Docker Swarm

```bash
# If not already initialized
docker swarm init

# Create external network for Traefik
docker network create --driver=overlay traefik_public
```

### 4. Label Nodes (Optional)

For advanced placement strategies:

```bash
# Label node for PostgreSQL
docker node update --label-add papermark.postgres=true $(docker node ls -q)

# Label node for backups
docker node update --label-add papermark.backup=true $(docker node ls -q)
```

### 5. Deploy Stack

```bash
# Deploy to swarm
docker stack deploy -c docker-compose.papermark.yml papermark

# Check status
docker stack services papermark
docker stack ps papermark
```

## Configuration

### Storage Options

#### Option 1: AWS S3

```bash
BLOB_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_S3_BUCKET_NAME=my-papermark-bucket
AWS_REGION=us-east-1
```

**S3 Bucket Policy Example:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-papermark-bucket/*",
        "arn:aws:s3:::my-papermark-bucket"
      ]
    }
  ]
}
```

#### Option 2: MinIO (Self-Hosted S3-Compatible)

First, deploy MinIO:

```yaml
# Add to docker-compose.papermark.yml
  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio_data:/data
    networks:
      - papermark_internal
    deploy:
      mode: replicated
      replicas: 1
```

Then configure:

```bash
BLOB_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
S3_ENDPOINT=http://minio:9000
S3_FORCE_PATH_STYLE=true
AWS_S3_BUCKET_NAME=papermark
AWS_REGION=us-east-1
```

### Authentication Configuration

#### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `https://papermark.yourdomain.com/api/auth/callback/google`
6. Copy Client ID and Secret to `.env`

#### GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set Homepage URL: `https://papermark.yourdomain.com`
4. Set Authorization callback URL: `https://papermark.yourdomain.com/api/auth/callback/github`
5. Copy Client ID and Secret to `.env`

### Email Configuration (Resend)

1. Sign up at [Resend](https://resend.com/)
2. Verify your domain
3. Create API key
4. Add to `.env`:

```bash
RESEND_API_KEY=re_xxxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
```

### Analytics (Optional - Tinybird)

1. Sign up at [Tinybird](https://www.tinybird.co/)
2. Create a workspace
3. Get API token
4. Configure:

```bash
TINYBIRD_TOKEN=p.xxxxxxxxxxxxx
ENABLE_ANALYTICS=true
```

## Deployment

### GitHub Actions Workflow Setup

1. **Create GitHub Repository Secrets:**

```bash
# Navigate to: Settings > Secrets and variables > Actions

# Required secrets:
REGISTRY=ghcr.io
REGISTRY_USERNAME=your-github-username
REGISTRY_PASSWORD=your-github-token
IMAGE_PREFIX=ghcr.io/your-org

# Optional (for WireGuard):
REGISTRY_IP=10.0.0.1
WG_CONF=<your-wireguard-config>
```

2. **Trigger Build:**

```bash
# Push to main branch
git push origin main

# Or trigger manually
# Go to Actions tab > Build & Push Papermark > Run workflow
```

3. **Monitor Build:**

```bash
# Check GitHub Actions for build status
# Images will be pushed to your container registry
```

### Manual Build (Alternative)

If you prefer to build locally:

```bash
# Clone Papermark
git clone https://github.com/mfts/papermark.git papermark-src
cd papermark-src

# Build image
docker build -f ../Dockerfile.papermark -t your-registry/papermark:latest .

# Push to registry
docker push your-registry/papermark:latest
```

### Applying PRs During Build

To test or apply open PRs:

```yaml
# In .github/workflows/build-and-push.yml
env:
  PAPERMARK_PRS: "123,456,789"  # PR numbers to merge
```

## Maintenance

### Update Papermark

```bash
# Pull latest image
docker service update --image ghcr.io/your-org/papermark:latest papermark_papermark

# Or update entire stack
docker stack deploy -c docker-compose.papermark.yml papermark
```

### Scale Services

```bash
# Scale Papermark horizontally
docker service scale papermark_papermark=4

# Or edit .env
PAPERMARK_REPLICAS=4
```

### View Logs

```bash
# All services
docker stack ps papermark

# Specific service logs
docker service logs -f papermark_papermark
docker service logs -f papermark_postgres

# Follow logs with timestamps
docker service logs -f --timestamps papermark_papermark
```

### Database Backups

Backups are automatic with the included `postgres-backup` service.

**Manual Backup:**

```bash
# Create backup
docker exec -it $(docker ps -q -f name=papermark_postgres) \
  pg_dump -U papermark papermark > backup-$(date +%Y%m%d).sql

# Restore backup
docker exec -i $(docker ps -q -f name=papermark_postgres) \
  psql -U papermark papermark < backup-20241027.sql
```

**Backup Location:**

Backups are stored in `./backups` by default. Configure in `.env`:

```bash
BACKUP_PATH=/mnt/backups/papermark
BACKUP_SCHEDULE=@daily
BACKUP_KEEP_DAYS=7
```

### Database Migrations

Migrations run automatically on startup. To run manually:

```bash
# Access Papermark container
docker exec -it $(docker ps -q -f name=papermark_papermark) sh

# Run migrations
npx prisma db push
```

## Monitoring

### Health Checks

```bash
# Check service health
docker service ps papermark_papermark --no-trunc

# Check specific service
curl https://papermark.yourdomain.com/api/health
```

### Resource Usage

```bash
# Service stats
docker stats $(docker ps -q -f name=papermark)

# Detailed service info
docker service inspect papermark_papermark --pretty
```

### Traefik Dashboard

Access Traefik dashboard (if enabled) to monitor:
- Request rates
- Response times
- SSL certificates
- Service health

## Troubleshooting

### Service Won't Start

```bash
# Check service logs
docker service logs papermark_papermark --tail 100

# Check for errors
docker service ps papermark_papermark --no-trunc

# Inspect service configuration
docker service inspect papermark_papermark
```

### Database Connection Issues

```bash
# Test database connectivity
docker exec -it $(docker ps -q -f name=papermark_postgres) \
  psql -U papermark -d papermark -c "SELECT version();"

# Check DATABASE_URL format
echo $DATABASE_URL
# Should be: postgresql://user:pass@postgres:5432/papermark
```

### Storage Issues

```bash
# Test S3 connectivity (for AWS)
aws s3 ls s3://your-bucket-name --profile papermark

# Test MinIO (if self-hosted)
docker exec -it $(docker ps -q -f name=minio) \
  mc alias set local http://localhost:9000 minioadmin minioadmin
```

### Email Not Sending

```bash
# Verify Resend API key
curl -X GET https://api.resend.com/domains \
  -H "Authorization: Bearer YOUR_RESEND_API_KEY"

# Check service logs for email errors
docker service logs papermark_papermark | grep -i resend
```

### Authentication Issues

**Google OAuth:**
- Verify redirect URI: `https://yourdom.com/api/auth/callback/google`
- Check Google Cloud Console for API quotas
- Ensure OAuth consent screen is published

**GitHub OAuth:**
- Verify callback URL matches exactly
- Check GitHub App settings

### SSL/TLS Certificate Issues

```bash
# Check Traefik logs
docker service logs traefik_traefik | grep -i certificate

# Verify DNS records
dig papermark.yourdomain.com

# Test ACME challenge
curl http://papermark.yourdomain.com/.well-known/acme-challenge/test
```

### Performance Issues

1. **Scale horizontally:**
   ```bash
   docker service scale papermark_papermark=4
   ```

2. **Increase resources:**
   ```yaml
   # In docker-compose
   resources:
     limits:
       cpus: "4"
       memory: 4G
   ```

3. **Enable caching:**
   - Ensure Redis is running
   - Configure Upstash Redis for better performance

4. **Database optimization:**
   ```sql
   -- Run in PostgreSQL
   VACUUM ANALYZE;
   REINDEX DATABASE papermark;
   ```

## Security Best Practices

1. **Use strong secrets:**
   ```bash
   openssl rand -hex 32
   ```

2. **Enable rate limiting** (already configured in Traefik labels)

3. **Regular updates:**
   ```bash
   # Update weekly
   docker service update --image ghcr.io/your-org/papermark:latest papermark_papermark
   ```

4. **Monitor logs for suspicious activity**

5. **Regular backups** (automated in stack)

6. **Use HTTPS only** (enforced by Traefik)

## Advanced Configuration

### Using External PostgreSQL

```bash
# Comment out postgres service in docker-compose
# Update DATABASE_URL
DATABASE_URL=postgresql://user:pass@external-host:5432/dbname
```

### Custom Domains Feature

Requires Vercel API integration:

```bash
ENABLE_CUSTOM_DOMAINS=true
PROJECT_ID_VERCEL=prj_xxxxx
TEAM_ID_VERCEL=team_xxxxx
AUTH_BEARER_TOKEN=xxxxxx
```

### Multiple Environments

```bash
# Development
docker stack deploy -c docker-compose.papermark.yml -c docker-compose.dev.yml papermark-dev

# Staging
docker stack deploy -c docker-compose.papermark.yml -c docker-compose.staging.yml papermark-staging

# Production
docker stack deploy -c docker-compose.papermark.yml papermark
```

## Support

- **GitHub Issues**: [mfts/papermark/issues](https://github.com/mfts/papermark/issues)
- **Documentation**: [papermark.com/docs](https://www.papermark.com/help)
- **Community**: Join discussions on GitHub

## License

Papermark is licensed under AGPL-3.0. Some features may require enterprise license for commercial use.
