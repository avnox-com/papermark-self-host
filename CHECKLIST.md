# Papermark Deployment Checklist

Use this checklist to ensure a smooth deployment of Papermark.

## ✅ Pre-Deployment Checklist

### Infrastructure Requirements
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Swarm initialized (`docker swarm init`)
- [ ] Minimum 2GB RAM available (4GB recommended)
- [ ] 20GB+ free disk space
- [ ] Traefik v2+ reverse proxy deployed and running
- [ ] `traefik_public` overlay network created

### Domain & DNS
- [ ] Domain name purchased/available
- [ ] DNS A record pointing to server IP
  - [ ] `papermark.yourdomain.com` → YOUR_SERVER_IP
- [ ] If using MinIO:
  - [ ] `minio.yourdomain.com` → YOUR_SERVER_IP
  - [ ] `minio-api.yourdomain.com` → YOUR_SERVER_IP
- [ ] DNS propagation verified (`dig papermark.yourdomain.com`)

### External Services
- [ ] **Storage** - Choose ONE:
  - [ ] AWS S3 bucket created and credentials ready
  - [ ] MinIO will be deployed (no action needed)
  - [ ] Other S3-compatible service configured
  
- [ ] **Email** (Resend):
  - [ ] Account created at https://resend.com
  - [ ] Domain verified in Resend
  - [ ] API key generated
  
- [ ] **Authentication** (Optional but recommended):
  - [ ] Google OAuth configured:
    - [ ] Project created in Google Cloud Console
    - [ ] OAuth consent screen configured
    - [ ] Redirect URI added: `https://papermark.yourdomain.com/api/auth/callback/google`
    - [ ] Client ID and Secret generated
  
  - [ ] GitHub OAuth configured:
    - [ ] OAuth App created at https://github.com/settings/developers
    - [ ] Callback URL set: `https://papermark.yourdomain.com/api/auth/callback/github`
    - [ ] Client ID and Secret generated

- [ ] **Analytics** (Optional):
  - [ ] Tinybird account created
  - [ ] Workspace configured
  - [ ] Token generated

### Repository Setup
- [ ] Repository cloned or created
- [ ] All deployment files in place
- [ ] `.env.example` reviewed

## ✅ Configuration Checklist

### Environment File
- [ ] Copy `.env.example` to `.env`
- [ ] Set `PAPERMARK_PUBLIC_URL`
- [ ] Set `PAPERMARK_DOMAIN`
- [ ] Generate and set `NEXTAUTH_SECRET` (32+ chars)
- [ ] Generate and set `POSTGRES_PASSWORD`
- [ ] Configure storage credentials
- [ ] Set `RESEND_API_KEY`
- [ ] Set `EMAIL_FROM`
- [ ] Configure OAuth providers (if using)
- [ ] Set `PAPERMARK_IMAGE` (your registry path)
- [ ] Review and adjust `PAPERMARK_REPLICAS`

### GitHub Actions (for CI/CD)
- [ ] Repository created on GitHub
- [ ] Code pushed to repository
- [ ] GitHub Secrets configured:
  - [ ] `REGISTRY`
  - [ ] `REGISTRY_USERNAME`
  - [ ] `REGISTRY_PASSWORD`
  - [ ] `IMAGE_PREFIX`
- [ ] Optional WireGuard secrets (if needed):
  - [ ] `REGISTRY_IP`
  - [ ] `WG_CONF`
- [ ] Workflow file at `.github/workflows/build-and-push.yml`

## ✅ AWS S3 Configuration (if using)

### Bucket Setup
- [ ] S3 bucket created
- [ ] Bucket name matches `AWS_S3_BUCKET_NAME` in .env
- [ ] Region matches `AWS_REGION` in .env
- [ ] CORS policy configured:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["https://papermark.yourdomain.com"],
    "ExposeHeaders": ["ETag"]
  }
]
```

### IAM User
- [ ] IAM user created for Papermark
- [ ] Programmatic access enabled
- [ ] Policy attached with S3 permissions
- [ ] Access Key ID and Secret generated
- [ ] Credentials added to `.env`

### Bucket Policy
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
        "arn:aws:s3:::your-bucket/*",
        "arn:aws:s3:::your-bucket"
      ]
    }
  ]
}
```

## ✅ Deployment Checklist

### Initial Deployment
- [ ] Run setup script: `./setup.sh`
- [ ] Review generated configuration
- [ ] Create Traefik network: `docker network create --driver=overlay traefik_public`
- [ ] Label nodes (if using placement constraints):
  ```bash
  docker node update --label-add papermark.postgres=true NODE_ID
  docker node update --label-add papermark.backup=true NODE_ID
  docker node update --label-add papermark.storage=true NODE_ID  # If using MinIO
  ```
- [ ] Deploy stack: `docker stack deploy -c docker-compose.papermark.yml papermark`
- [ ] If using MinIO: `docker stack deploy -c docker-compose.papermark.yml -c docker-compose.minio.yml papermark`
- [ ] Wait for services to start (2-5 minutes)

### Verification
- [ ] Check stack status: `docker stack ps papermark`
- [ ] Verify all services running: `docker stack services papermark`
- [ ] Check Papermark logs: `docker service logs papermark_papermark`
- [ ] Check PostgreSQL logs: `docker service logs papermark_postgres`
- [ ] Verify database migrations ran successfully
- [ ] Test health endpoint: `curl https://papermark.yourdomain.com/api/health`
- [ ] Access Papermark UI in browser
- [ ] Verify SSL certificate is valid (green lock icon)

### First Login
- [ ] Create first user account
- [ ] Verify email delivery
- [ ] Test OAuth login (if configured)
- [ ] Create test document
- [ ] Upload file to test storage
- [ ] Share test document and verify analytics

## ✅ Post-Deployment Checklist

### Security
- [ ] Change any default passwords
- [ ] Verify rate limiting is working
- [ ] Test that HTTPS redirect works (http → https)
- [ ] Review security headers in browser dev tools
- [ ] Configure firewall rules (if applicable)
- [ ] Set up fail2ban or similar (optional)

### Backups
- [ ] Verify backup service is running
- [ ] Check backup directory exists: `ls -la ./backups/`
- [ ] Test manual backup: `make backup`
- [ ] Test restore process: `make restore BACKUP=...`
- [ ] Set up off-site backup sync (recommended)
- [ ] Document backup/restore procedures

### Monitoring
- [ ] Set up Traefik dashboard access (optional)
- [ ] Configure log aggregation (optional)
- [ ] Set up health check monitoring
- [ ] Configure uptime monitoring (e.g., UptimeRobot)
- [ ] Set up disk space alerts
- [ ] Configure backup success/failure notifications

### Documentation
- [ ] Document your specific configuration
- [ ] Create runbook for common operations
- [ ] Document custom domain procedures (if using)
- [ ] Write incident response plan
- [ ] Create user guide for your team
- [ ] Document scaling procedures

### Performance
- [ ] Test performance under expected load
- [ ] Adjust replica count if needed: `make scale REPLICAS=X`
- [ ] Review and adjust resource limits in docker-compose
- [ ] Configure CDN (optional, recommended for production)
- [ ] Set up database query optimization

## ✅ Ongoing Maintenance Checklist

### Weekly
- [ ] Review logs for errors
- [ ] Check disk space usage
- [ ] Verify backups are running
- [ ] Review access logs for suspicious activity

### Monthly
- [ ] Update to latest Papermark version
- [ ] Test backup restore procedure
- [ ] Review and rotate credentials
- [ ] Analyze usage patterns
- [ ] Optimize database if needed
- [ ] Review and update documentation

### Quarterly
- [ ] Security audit
- [ ] Performance review
- [ ] Disaster recovery test
- [ ] Review and update runbooks
- [ ] Team training on procedures

## ✅ Troubleshooting Checklist

If something goes wrong, check:

### Service Won't Start
- [ ] Check logs: `docker service logs papermark_papermark`
- [ ] Verify .env configuration
- [ ] Check Docker Swarm status
- [ ] Verify network connectivity
- [ ] Check resource availability

### Database Issues
- [ ] Verify PostgreSQL is running
- [ ] Check DATABASE_URL format
- [ ] Test database connection
- [ ] Review migration logs
- [ ] Check disk space

### Storage Issues
- [ ] Verify S3 credentials
- [ ] Test bucket access
- [ ] Check bucket permissions
- [ ] Review CORS configuration
- [ ] Check network connectivity to S3

### Email Issues
- [ ] Verify Resend API key
- [ ] Check domain verification in Resend
- [ ] Review email logs in Papermark
- [ ] Test with Resend API directly
- [ ] Check email quotas/limits

### Authentication Issues
- [ ] Verify OAuth redirect URIs
- [ ] Check client IDs and secrets
- [ ] Review OAuth app settings
- [ ] Check NEXTAUTH_SECRET
- [ ] Verify NEXTAUTH_URL matches public URL

### SSL/Certificate Issues
- [ ] Check Traefik logs
- [ ] Verify DNS records
- [ ] Test ACME challenge
- [ ] Review certificate expiration
- [ ] Check Let's Encrypt rate limits

## 📝 Notes Section

Use this space for deployment-specific notes:

**Deployment Date:** _____________

**Deployed By:** _____________

**Custom Configuration:**
- 
- 
- 

**Known Issues:**
- 
- 
- 

**Special Considerations:**
- 
- 
- 

---

## ✨ Completion

When all items are checked:
- [ ] Deployment is complete and verified
- [ ] All stakeholders notified
- [ ] Documentation updated
- [ ] Backup procedures tested
- [ ] Monitoring in place
- [ ] Team trained
- [ ] Success! 🎉

---

*Keep this checklist updated as your deployment evolves*
