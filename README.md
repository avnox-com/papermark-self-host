# Papermark Self-Hosted Deployment

> 🚀 Complete Docker Swarm deployment solution for [Papermark](https://github.com/mfts/papermark) - the open-source DocSend alternative with built-in analytics and custom domains.

[![Build & Push Papermark](https://github.com/avnox-com/papermark-deploy/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/avnox-com/papermark-deploy/actions/workflows/build-and-push.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🐳 **Production-Ready Docker Deployment** - Optimized multi-stage builds
- 🔄 **Automated CI/CD** - GitHub Actions workflow with PR merging support
- 🌐 **Traefik Integration** - Automatic SSL certificates and load balancing
- 🗄️ **PostgreSQL Database** - Included with automatic backups
- 📦 **S3-Compatible Storage** - AWS S3, MinIO, Backblaze B2, or any S3-compatible service
- 📧 **Email Support** - Resend integration for transactional emails
- 🔐 **OAuth Authentication** - Google and GitHub login support
- 📊 **Optional Analytics** - Tinybird integration for document tracking
- 🔄 **High Availability** - Multi-replica support with sticky sessions
- 🔒 **Security Hardened** - Rate limiting, security headers, and best practices

## 📋 What's Included

```
.
├── .github/
│   └── workflows/
│       └── build-and-push.yml      # Automated build and push workflow
├── docker-compose.papermark.yml     # Production stack configuration
├── Dockerfile.papermark             # Optimized multi-stage Dockerfile
├── .env.example                     # Environment configuration template
├── DEPLOYMENT.md                    # Comprehensive deployment guide
├── setup.sh                         # Interactive setup script
└── README.md                        # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+ with Swarm mode
- Traefik v2+ reverse proxy
- Minimum 2GB RAM (4GB recommended)
- Domain name with DNS configured

### 1. Clone Repository

```bash
git clone https://github.com/avnox-com/papermark-deploy.git
cd papermark-deploy
```

### 2. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

The interactive script will help you configure:
- Domain name
- Database credentials (auto-generated)
- Storage backend (S3, MinIO, etc.)
- Email service (Resend)
- OAuth providers (Google, GitHub)

### 3. Deploy Stack

```bash
# Deploy to Docker Swarm
docker stack deploy -c docker-compose.papermark.yml papermark

# Check status
docker stack ps papermark
```

### 4. Access Your Instance

Visit `https://your-domain.com` and create your first account!

## 🔧 Configuration

### Essential Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Core Settings
PAPERMARK_PUBLIC_URL=https://papermark.yourdomain.com
PAPERMARK_DOMAIN=papermark.yourdomain.com
NEXTAUTH_SECRET=your-secret-here

# Database
POSTGRES_PASSWORD=your-secure-password

# Storage (choose one)
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET_NAME=your-bucket

# Email
RESEND_API_KEY=re_your-key
EMAIL_FROM=noreply@yourdomain.com

# Authentication (optional)
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-secret
```

See [.env.example](.env.example) for all available options.

## 🏗️ Architecture

```
┌─────────────┐
│   Traefik   │ ← Reverse Proxy + SSL
└──────┬──────┘
       │
       ├─→ ┌──────────────┐
       │   │  Papermark   │ ← Next.js Application (Multi-replica)
       │   │  (2 replicas)│
       │   └──────┬───────┘
       │          │
       │          ├─→ ┌────────────┐
       │          │   │ PostgreSQL │ ← Database
       │          │   └────────────┘
       │          │
       │          └─→ ┌────────────┐
       │              │   Redis    │ ← Caching
       │              └────────────┘
       │
       └─→ S3-Compatible Storage (AWS S3, MinIO, etc.)
```

## 🤖 CI/CD Workflow

The GitHub Actions workflow automatically:

1. ✅ Checks out your repository
2. ✅ Clones the latest Papermark source
3. ✅ Optionally merges PRs for testing
4. ✅ Builds optimized Docker images
5. ✅ Pushes to your container registry
6. ✅ Supports WireGuard for private registries

### Configure GitHub Secrets

```bash
# Required
REGISTRY=ghcr.io
REGISTRY_USERNAME=your-github-username
REGISTRY_PASSWORD=your-github-token
IMAGE_PREFIX=ghcr.io/avnox-com

# Optional
REGISTRY_IP=10.0.0.1        # For private registry via WireGuard
WG_CONF=<wireguard-config>   # Full wg0.conf content
```

### Merge PRs During Build

Edit `.github/workflows/build-and-push.yml`:

```yaml
env:
  PAPERMARK_PRS: "123,456"  # PR numbers to merge and test
```

## 📚 Storage Configuration

### AWS S3

```bash
BLOB_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_S3_BUCKET_NAME=papermark-uploads
AWS_REGION=us-east-1
```

### MinIO (Self-Hosted)

```bash
# Add MinIO to docker-compose and configure:
BLOB_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
S3_ENDPOINT=http://minio:9000
S3_FORCE_PATH_STYLE=true
AWS_S3_BUCKET_NAME=papermark
```

### Other S3-Compatible (Backblaze B2, etc.)

```bash
BLOB_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=your-key-id
AWS_SECRET_ACCESS_KEY=your-app-key
S3_ENDPOINT=https://s3.us-west-001.backblazeb2.com
AWS_S3_BUCKET_NAME=your-bucket
AWS_REGION=us-west-001
```

## 🔐 Authentication Setup

### Google OAuth

1. Create project at [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google+ API
3. Create OAuth 2.0 credentials
4. Add redirect URI: `https://yourdomain.com/api/auth/callback/google`
5. Add credentials to `.env`

### GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set callback: `https://yourdomain.com/api/auth/callback/github`
4. Add credentials to `.env`

## 🛠️ Management

### View Logs

```bash
# All services
docker stack ps papermark

# Specific service
docker service logs -f papermark_papermark
docker service logs -f papermark_postgres
```

### Scale Services

```bash
# Scale Papermark horizontally
docker service scale papermark_papermark=4

# Or edit .env and redeploy
PAPERMARK_REPLICAS=4
docker stack deploy -c docker-compose.papermark.yml papermark
```

### Update Papermark

```bash
# Automatic via GitHub Actions
git push origin main

# Or manual
docker service update --image ghcr.io/avnox-com/papermark:latest papermark_papermark
```

### Database Backups

Backups are automatic! Configure in `.env`:

```bash
BACKUP_PATH=./backups
BACKUP_SCHEDULE=@daily
BACKUP_KEEP_DAYS=7
BACKUP_KEEP_WEEKS=4
BACKUP_KEEP_MONTHS=6
```

Manual backup:

```bash
docker exec -it $(docker ps -q -f name=papermark_postgres) \
  pg_dump -U papermark papermark > backup-$(date +%Y%m%d).sql
```

## 📊 Monitoring

### Health Checks

```bash
# Check service health
curl https://your-domain.com/api/health

# Service status
docker service ps papermark_papermark
```

### Resource Usage

```bash
# Container stats
docker stats $(docker ps -q -f name=papermark)

# Service details
docker service inspect papermark_papermark --pretty
```

## 🐛 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker service logs papermark_papermark --tail 100 --follow

# Inspect service
docker service ps papermark_papermark --no-trunc
```

### Database Connection Issues

```bash
# Test connection
docker exec -it $(docker ps -q -f name=papermark_postgres) \
  psql -U papermark -d papermark -c "SELECT version();"
```

### Storage Issues

```bash
# Test AWS S3
aws s3 ls s3://your-bucket --profile papermark

# Test MinIO
docker exec -it $(docker ps -q -f name=minio) \
  mc alias set local http://localhost:9000 minioadmin minioadmin
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for comprehensive troubleshooting.

## 🔒 Security Best Practices

✅ Use strong, randomly generated secrets  
✅ Enable HTTPS only (enforced by Traefik)  
✅ Configure rate limiting (included)  
✅ Regular backups (automated)  
✅ Keep software updated  
✅ Use separate credentials for each service  
✅ Review logs for suspicious activity  
✅ Use firewall rules to restrict access  

## 📈 Performance Optimization

- **Horizontal Scaling**: Increase `PAPERMARK_REPLICAS`
- **Resource Limits**: Adjust CPU/Memory in docker-compose
- **Redis Caching**: Ensure Redis is running
- **CDN**: Consider CloudFlare or similar for static assets
- **Database**: Regular `VACUUM ANALYZE` and indexing

## 🤝 Contributing

Found a bug or have a feature request? Please open an issue!

Want to improve this deployment? PRs are welcome!

## 📝 License

This deployment configuration is licensed under MIT.

Papermark itself is licensed under AGPL-3.0 - some features may require enterprise license for commercial use.

## 🔗 Links

- [Papermark Official Website](https://www.papermark.com/)
- [Papermark GitHub](https://github.com/mfts/papermark)
- [Papermark Documentation](https://www.papermark.com/help)
- [Report Issues](https://github.com/avnox-com/papermark-deploy/issues)

## 🙏 Acknowledgments

- [Papermark](https://github.com/mfts/papermark) - The amazing open-source project
- [Traefik](https://traefik.io/) - Modern HTTP reverse proxy
- [Docker](https://www.docker.com/) - Container platform

---

Made with ❤️ for the self-hosting community
