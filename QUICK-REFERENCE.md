# Papermark Quick Reference

## 🚀 Quick Commands

### Initial Setup
```bash
# 1. Run setup wizard
./setup.sh

# 2. Deploy stack
make deploy

# 3. Check status
make status
```

### Daily Operations
```bash
# View logs
make logs                    # Papermark logs
make logs-db                 # Database logs
make logs-all               # All services

# Check health
make health

# Scale up/down
make scale REPLICAS=4

# Restart service
make restart
```

### Maintenance
```bash
# Backup database
make backup

# Restore database
make restore BACKUP=./backups/backup.sql

# Update to latest version
make update

# Run migrations
make migrations
```

### Troubleshooting
```bash
# Check service status
docker stack ps papermark

# View service details
docker service inspect papermark_papermark

# Access shell
make shell                   # Papermark container
make db-shell               # PostgreSQL shell
```

## 📁 Directory Structure

```
papermark-self-host/
├── .github/workflows/
│   └── build-and-push.yml       # CI/CD workflow
├── .env                         # Your configuration (create from .env.example)
├── .env.example                 # Configuration template
├── docker-compose.papermark.yml # Main stack definition
├── docker-compose.minio.yml     # Optional MinIO storage
├── Dockerfile.papermark         # Application image build
├── Makefile                     # Management commands
├── setup.sh                     # Interactive setup
├── README.md                    # Full documentation
├── DEPLOYMENT.md                # Deployment guide
├── next.config.docker.js        # Next.js Docker config
└── health-endpoint.ts           # Health check endpoint
```

## 🔧 Essential Environment Variables

```bash
# Required
PAPERMARK_PUBLIC_URL=https://papermark.yourdomain.com
PAPERMARK_DOMAIN=papermark.yourdomain.com
NEXTAUTH_SECRET=<random-32-char-string>
POSTGRES_PASSWORD=<secure-password>

# Storage (pick one)
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
AWS_S3_BUCKET_NAME=<bucket-name>

# Email
RESEND_API_KEY=re_<your-key>

# Auth (optional)
GOOGLE_CLIENT_ID=<client-id>
GOOGLE_CLIENT_SECRET=<secret>
```

## 🌐 URLs After Deployment

- **Papermark**: https://papermark.yourdomain.com
- **MinIO Console** (if enabled): https://minio.yourdomain.com
- **MinIO API** (if enabled): https://minio-api.yourdomain.com

## 🔑 GitHub Secrets (for CI/CD)

```
REGISTRY=ghcr.io
REGISTRY_USERNAME=<github-username>
REGISTRY_PASSWORD=<github-token>
IMAGE_PREFIX=ghcr.io/<org-name>
```

## 📊 Default Ports (Internal)

- Papermark: 3000
- PostgreSQL: 5432
- Redis: 6379
- MinIO: 9000 (API), 9001 (Console)

## 🔒 Security Checklist

- [ ] Strong NEXTAUTH_SECRET generated
- [ ] Strong POSTGRES_PASSWORD set
- [ ] Resend API key configured
- [ ] OAuth providers configured
- [ ] Backups enabled and tested
- [ ] DNS properly configured
- [ ] Traefik SSL certificates working
- [ ] Rate limiting enabled (default in config)

## 🐛 Common Issues

### Service won't start
```bash
docker service logs papermark_papermark --tail 100
```

### Database connection error
```bash
# Check database is running
docker service ps papermark_postgres

# Test connection
docker exec -it $(docker ps -q -f name=papermark_postgres) \
  psql -U papermark -d papermark -c "SELECT version();"
```

### SSL certificate issues
```bash
# Check Traefik logs
docker service logs traefik_traefik | grep -i certificate

# Verify DNS
dig papermark.yourdomain.com
```

### Can't upload files
- Check storage configuration in .env
- Test S3 credentials
- Check bucket permissions
- Review Papermark logs for storage errors

## 📈 Performance Tips

1. **Scale horizontally**: `make scale REPLICAS=4`
2. **Increase resources**: Edit limits in docker-compose.yml
3. **Enable Redis caching**: Ensure Redis service is running
4. **Database tuning**: Adjust PostgreSQL settings
5. **Use CDN**: Consider CloudFlare for static assets

## 🔄 Update Process

1. **Via CI/CD** (Recommended):
   ```bash
   git push origin main
   # Wait for GitHub Actions to build and push
   make update
   ```

2. **Manual**:
   ```bash
   docker service update --image \
     ghcr.io/avnox-com/papermark:latest \
     papermark_papermark
   ```

## 💾 Backup Strategy

- **Automatic**: Daily backups via postgres-backup service
- **Manual**: `make backup` before updates
- **Test restores**: Monthly `make restore BACKUP=...`
- **Off-site**: Copy ./backups to remote location

## 📞 Support

- GitHub Issues: https://github.com/mfts/papermark/issues
- Documentation: https://www.papermark.com/help
- Your Deploy Repo: https://github.com/avnox-com/papermark-self-host

## 🎯 Next Steps After Deployment

1. Create first user account
2. Test document upload
3. Configure custom domain (optional)
4. Set up email templates
5. Configure Tinybird analytics (optional)
6. Enable Stripe for payments (optional)
7. Set up monitoring alerts
8. Schedule regular backups
9. Document your specific configuration
10. Train your team

---

For detailed information, see README.md and DEPLOYMENT.md
