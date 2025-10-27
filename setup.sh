#!/bin/bash

# ============================================================================
# Papermark Self-Hosted Setup Script
# ============================================================================
# This script helps you set up Papermark for the first time
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║         Papermark Self-Hosted Setup Script                    ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi
log_success "Docker is installed"

# Check Docker Swarm
if ! docker info | grep -q "Swarm: active"; then
    log_warning "Docker Swarm is not initialized"
    read -p "Would you like to initialize Docker Swarm now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker swarm init
        log_success "Docker Swarm initialized"
    else
        log_error "Docker Swarm is required. Exiting."
        exit 1
    fi
else
    log_success "Docker Swarm is active"
fi

# Check for Traefik network
if ! docker network ls | grep -q "traefik_public"; then
    log_warning "Traefik public network not found"
    read -p "Would you like to create it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker network create --driver=overlay traefik_public
        log_success "Traefik network created"
    else
        log_error "Traefik network is required. Exiting."
        exit 1
    fi
else
    log_success "Traefik network exists"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    log_info "Creating .env file from template..."
    if [ -f .env.example ]; then
        cp .env.example .env
        log_success ".env file created"
    else
        log_error ".env.example not found. Please create it first."
        exit 1
    fi
else
    log_info ".env file already exists"
fi

# Function to generate random string
generate_secret() {
    openssl rand -hex 32
}

# Interactive configuration
echo ""
log_info "Let's configure your Papermark instance..."
echo ""

# Domain configuration
read -p "Enter your domain (e.g., papermark.yourdomain.com): " DOMAIN
if [ -n "$DOMAIN" ]; then
    sed -i "s|PAPERMARK_DOMAIN=.*|PAPERMARK_DOMAIN=$DOMAIN|g" .env
    sed -i "s|PAPERMARK_PUBLIC_URL=.*|PAPERMARK_PUBLIC_URL=https://$DOMAIN|g" .env
    log_success "Domain configured: $DOMAIN"
fi

# Generate secrets
log_info "Generating secure secrets..."
NEXTAUTH_SECRET=$(generate_secret)
POSTGRES_PASSWORD=$(generate_secret)

sed -i "s|NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$NEXTAUTH_SECRET|g" .env
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|g" .env
log_success "Secrets generated"

# Storage configuration
echo ""
log_info "Storage Configuration"
echo "Choose your storage backend:"
echo "1) AWS S3"
echo "2) MinIO (Self-hosted)"
echo "3) Other S3-compatible"
echo "4) Skip (configure manually later)"
read -p "Enter choice [1-4]: " STORAGE_CHOICE

case $STORAGE_CHOICE in
    1)
        log_info "Configuring AWS S3..."
        read -p "AWS Access Key ID: " AWS_KEY
        read -p "AWS Secret Access Key: " AWS_SECRET
        read -p "S3 Bucket Name: " S3_BUCKET
        read -p "AWS Region [us-east-1]: " AWS_REGION
        AWS_REGION=${AWS_REGION:-us-east-1}
        
        sed -i "s|AWS_ACCESS_KEY_ID=.*|AWS_ACCESS_KEY_ID=$AWS_KEY|g" .env
        sed -i "s|AWS_SECRET_ACCESS_KEY=.*|AWS_SECRET_ACCESS_KEY=$AWS_SECRET|g" .env
        sed -i "s|AWS_S3_BUCKET_NAME=.*|AWS_S3_BUCKET_NAME=$S3_BUCKET|g" .env
        sed -i "s|AWS_REGION=.*|AWS_REGION=$AWS_REGION|g" .env
        log_success "AWS S3 configured"
        ;;
    2)
        log_info "MinIO will be deployed with the stack"
        log_warning "Remember to configure MinIO credentials in .env"
        ;;
    3)
        log_info "Please configure S3-compatible storage manually in .env"
        ;;
    4)
        log_warning "Storage configuration skipped"
        ;;
esac

# Email configuration
echo ""
read -p "Do you have a Resend API key? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Resend API Key: " RESEND_KEY
    read -p "From Email Address: " FROM_EMAIL
    sed -i "s|RESEND_API_KEY=.*|RESEND_API_KEY=$RESEND_KEY|g" .env
    sed -i "s|EMAIL_FROM=.*|EMAIL_FROM=$FROM_EMAIL|g" .env
    log_success "Email configured"
else
    log_warning "Email configuration skipped. Get your key from https://resend.com"
fi

# Authentication
echo ""
log_info "Authentication Configuration (Optional)"
read -p "Configure Google OAuth? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Google Client ID: " GOOGLE_ID
    read -p "Google Client Secret: " GOOGLE_SECRET
    sed -i "s|GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=$GOOGLE_ID|g" .env
    sed -i "s|GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=$GOOGLE_SECRET|g" .env
    log_success "Google OAuth configured"
fi

# Create backup directory
log_info "Creating backup directory..."
mkdir -p ./backups
chmod 700 ./backups
log_success "Backup directory created"

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     Configuration Complete!                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
log_info "Next steps:"
echo ""
echo "1. Review and edit .env file if needed:"
echo "   ${GREEN}nano .env${NC}"
echo ""
echo "2. Deploy the stack:"
echo "   ${GREEN}docker stack deploy -c docker-compose.papermark.yml papermark${NC}"
echo ""
echo "3. Check deployment status:"
echo "   ${GREEN}docker stack ps papermark${NC}"
echo ""
echo "4. View logs:"
echo "   ${GREEN}docker service logs -f papermark_papermark${NC}"
echo ""
echo "5. Access your instance at:"
echo "   ${GREEN}https://$DOMAIN${NC}"
echo ""
log_warning "Important: Make sure DNS is configured and Traefik is running!"
echo ""
log_info "For detailed instructions, see DEPLOYMENT.md"
echo ""
