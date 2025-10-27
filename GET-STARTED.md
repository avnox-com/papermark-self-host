# 🚀 Papermark Self-Hosted - Getting Started

Thank you for choosing to self-host Papermark! This deployment solution provides everything you need for a production-ready installation.

## 📦 What You've Received

This package includes a complete, production-ready deployment solution for Papermark with:

- ✅ **Automated CI/CD** - GitHub Actions workflow for building and pushing images
- ✅ **Docker Swarm Stack** - Production-ready orchestration with Traefik
- ✅ **Multiple Storage Options** - AWS S3, MinIO, or any S3-compatible service
- ✅ **High Availability** - Multi-replica support with load balancing
- ✅ **Automatic Backups** - Daily PostgreSQL backups with retention
- ✅ **Security Hardened** - Rate limiting, SSL, and security headers
- ✅ **Easy Management** - Makefile commands for all operations
- ✅ **Comprehensive Docs** - Step-by-step guides and troubleshooting

## 📋 File Overview

```
papermark-deploy/
├── 📄 README.md                       ← Start here! Full documentation
├── 📄 QUICK-REFERENCE.md              ← Command cheatsheet
├── 📄 DEPLOYMENT.md                   ← Detailed deployment guide
├── 📄 CHECKLIST.md                    ← Step-by-step deployment checklist
│
├── 🔧 .env.example                    ← Configuration template
├── 🐳 Dockerfile.papermark            ← Application container definition
├── 🐳 docker-compose.papermark.yml    ← Main stack (required)
├── 🐳 docker-compose.minio.yml        ← Optional self-hosted storage
│
├── ⚡ Makefile                        ← Management commands
├── 🔨 setup.sh                        ← Interactive setup wizard
│
├── 🔧 next.config.docker.js           ← Next.js Docker configuration
├── 🏥 health-endpoint.ts              ← Health check implementation
│
└── .github/workflows/
    └── build-and-push.yml             ← CI/CD automation
```

## 🎯 Quick Start (5 Minutes)

### Option A: Automated Setup (Recommended)

```bash
# 1. Make setup script executable
chmod +x setup.sh

# 2. Run interactive setup
./setup.sh

# 3. Deploy!
make deploy

# 4. Check status
make status

# Done! Visit https://your-domain.com
```

### Option B: Manual Setup

```bash
# 1. Copy environment template
cp .env.example .env

# 2. Generate secrets
echo "NEXTAUTH_SECRET=$(openssl rand -hex 32)" >> .env
echo "POSTGRES_PASSWORD=$(openssl rand -hex 32)" >> .env

# 3. Edit .env with your values
nano .env

# 4. Deploy
docker stack deploy -c docker-compose.papermark.yml papermark

# 5. Monitor deployment
docker stack ps papermark
```

## 🎓 Documentation Guide

### For First-Time Setup
1. **Start**: [README.md](README.md) - Overview and features
2. **Configure**: [.env.example](.env.example) - All configuration options
3. **Deploy**: [DEPLOYMENT.md](DEPLOYMENT.md) - Step-by-step guide
4. **Verify**: [CHECKLIST.md](CHECKLIST.md) - Complete checklist

### For Daily Operations
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Common commands
- [Makefile](Makefile) - `make help` for all commands

### For CI/CD Setup
- [.github/workflows/build-and-push.yml](.github/workflows/build-and-push.yml) - Automated builds
- [README.md](README.md) - GitHub Actions configuration section

## 🔑 Essential Configuration

### Minimum Required

```bash
# Domain
PAPERMARK_PUBLIC_URL=https://papermark.yourdomain.com
PAPERMARK_DOMAIN=papermark.yourdomain.com

# Security (generate with: openssl rand -hex 32)
NEXTAUTH_SECRET=<32-character-random-string>
POSTGRES_PASSWORD=<secure-password>

# Storage (AWS S3 example)
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
AWS_S3_BUCKET_NAME=<your-bucket>
AWS_REGION=us-east-1

# Email (Resend)
RESEND_API_KEY=re_<your-api-key>
EMAIL_FROM=noreply@yourdomain.com
```

### Recommended Optional

```bash
# Google OAuth
GOOGLE_CLIENT_ID=<your-client-id>
GOOGLE_CLIENT_SECRET=<your-secret>

# GitHub OAuth
GITHUB_CLIENT_ID=<your-client-id>
GITHUB_CLIENT_SECRET=<your-secret>

# Analytics (Tinybird)
TINYBIRD_TOKEN=<your-token>
ENABLE_ANALYTICS=true
```

## 🏗️ Deployment Scenarios

### Scenario 1: Simple Single-Server Deployment
**Best for:** Personal use, small teams
**Resources:** 2GB RAM, 2 CPU cores
**Storage:** AWS S3 or Backblaze B2

```bash
# Use default configuration
PAPERMARK_REPLICAS=1
./setup.sh
make deploy
```

### Scenario 2: High Availability Deployment
**Best for:** Business critical applications
**Resources:** 8GB+ RAM, 4+ CPU cores across multiple nodes
**Storage:** AWS S3 with CDN

```bash
# Scale to multiple replicas
PAPERMARK_REPLICAS=3
./setup.sh
make deploy
make scale REPLICAS=3
```

### Scenario 3: Fully Self-Hosted
**Best for:** Data sovereignty, air-gapped environments
**Resources:** 4GB+ RAM, 4 CPU cores
**Storage:** MinIO (included)

```bash
# Deploy with MinIO
docker stack deploy \
  -c docker-compose.papermark.yml \
  -c docker-compose.minio.yml \
  papermark
```

## 🤝 Common Tasks

### Update Papermark
```bash
# Automated (via GitHub Actions)
git push origin main
make update

# Manual
docker service update --image your-registry/papermark:latest papermark_papermark
```

### Backup Database
```bash
# Manual backup
make backup

# Backups are automatic! Check ./backups/
ls -lh ./backups/
```

### Scale Services
```bash
# Scale up
make scale REPLICAS=4

# Scale down
make scale REPLICAS=1
```

### View Logs
```bash
# Application logs
make logs

# Database logs
make logs-db

# All services
make logs-all
```

### Troubleshooting
```bash
# Check health
make health

# Service status
make status

# Access shell
make shell         # Papermark
make db-shell      # PostgreSQL
```

## 🆘 Getting Help

### Common Issues

**Service won't start?**
```bash
docker service logs papermark_papermark --tail 100
```

**Database connection error?**
- Check DATABASE_URL in .env
- Verify PostgreSQL is running: `docker service ps papermark_postgres`

**Can't upload files?**
- Verify S3 credentials
- Check bucket permissions
- Review storage configuration in .env

**Email not working?**
- Verify Resend API key
- Check domain is verified in Resend
- Review email logs

### Resources

- 📚 [Full Documentation](README.md)
- 🔧 [Deployment Guide](DEPLOYMENT.md)
- ✅ [Setup Checklist](CHECKLIST.md)
- ⚡ [Quick Reference](QUICK-REFERENCE.md)
- 🐛 [Papermark Issues](https://github.com/mfts/papermark/issues)
- 💬 [Papermark Discussions](https://github.com/mfts/papermark/discussions)

## 🎉 Next Steps

1. ✅ Complete setup using [CHECKLIST.md](CHECKLIST.md)
2. 🔐 Configure authentication providers
3. 📧 Set up email notifications
4. 📊 Enable analytics (optional)
5. 👥 Invite team members
6. 📱 Test all features
7. 🎨 Customize branding
8. 📈 Monitor performance
9. 💾 Verify backups
10. 🎓 Train your team

## 🔒 Security Reminders

- ✅ Use strong, unique passwords
- ✅ Enable HTTPS (automatic with Traefik)
- ✅ Configure OAuth providers
- ✅ Regular backups (automated)
- ✅ Keep software updated
- ✅ Monitor logs for suspicious activity
- ✅ Review security headers
- ✅ Use firewall rules

## 📈 Performance Tips

1. **Scale horizontally** for more users
2. **Use CDN** for static assets
3. **Enable Redis caching** (included)
4. **Optimize database** queries
5. **Monitor resources** regularly

## 🌟 Advanced Features

### Custom Domains
Enable in .env and configure Vercel API integration

### Analytics Dashboard
Integrate Tinybird for detailed document analytics

### Webhook Integrations
Connect to Slack, Discord, or custom webhooks

### API Access
Use Papermark's REST API for automation

### White-Label
Customize branding and domains for your organization

## 📝 Support This Project

Papermark is open-source and maintained by the community:

- ⭐ Star the [Papermark repo](https://github.com/mfts/papermark)
- 🐛 Report issues
- 💡 Suggest features
- 🤝 Contribute code
- 📢 Spread the word

## 📜 License

- **This deployment configuration**: MIT License
- **Papermark software**: AGPL-3.0 (some features may require enterprise license)

## 🙏 Credits

Built with:
- [Papermark](https://github.com/mfts/papermark) - Amazing open-source DocSend alternative
- [Next.js](https://nextjs.org/) - React framework
- [Docker](https://docker.com/) - Containerization
- [Traefik](https://traefik.io/) - Reverse proxy
- [PostgreSQL](https://postgresql.org/) - Database

---

## 🚀 Ready to Deploy?

```bash
# Let's go!
chmod +x setup.sh
./setup.sh
```

**Need help?** Review [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

**Questions?** Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for common commands.

**Stuck?** See troubleshooting section in [README.md](README.md).

---

Made with ❤️ for the self-hosting community

*Happy self-hosting! 🎉*
