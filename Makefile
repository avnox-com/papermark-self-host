.PHONY: help setup deploy update logs scale backup restore clean health

# Default target
.DEFAULT_GOAL := help

# Configuration
STACK_NAME := papermark
COMPOSE_FILE := docker-compose.papermark.yml
ENV_FILE := .env

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '${GREEN}Papermark Self-Hosted Management${NC}'
	@echo ''
	@echo 'Usage:'
	@echo '  make ${YELLOW}<target>${NC}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  ${YELLOW}%-15s${NC} %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Run initial setup script
	@echo "${GREEN}Running setup script...${NC}"
	@chmod +x setup.sh
	@./setup.sh

validate: ## Validate configuration
	@echo "${GREEN}Validating configuration...${NC}"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "${YELLOW}Error: .env file not found. Run 'make setup' first${NC}"; \
		exit 1; \
	fi
	@echo "${GREEN}✓ Configuration valid${NC}"

network: ## Create Traefik network if it doesn't exist
	@echo "${GREEN}Checking Traefik network...${NC}"
	@docker network inspect traefik_public >/dev/null 2>&1 || \
		docker network create --driver=overlay traefik_public
	@echo "${GREEN}✓ Network ready${NC}"

deploy: validate network ## Deploy the stack
	@echo "${GREEN}Deploying Papermark stack...${NC}"
	@docker stack deploy -c $(COMPOSE_FILE) $(STACK_NAME)
	@echo "${GREEN}✓ Stack deployed${NC}"
	@echo "Run 'make logs' to follow deployment"

update: ## Update Papermark to latest version
	@echo "${GREEN}Updating Papermark...${NC}"
	@docker service update --image $$(grep PAPERMARK_IMAGE $(ENV_FILE) | cut -d= -f2) $(STACK_NAME)_papermark
	@echo "${GREEN}✓ Update initiated${NC}"

logs: ## Follow logs from Papermark service
	@docker service logs -f $(STACK_NAME)_papermark

logs-db: ## Follow logs from PostgreSQL service
	@docker service logs -f $(STACK_NAME)_postgres

logs-all: ## Follow logs from all services
	@docker stack ps $(STACK_NAME)

status: ## Show stack status
	@echo "${GREEN}Stack Services:${NC}"
	@docker stack services $(STACK_NAME)
	@echo ""
	@echo "${GREEN}Running Tasks:${NC}"
	@docker stack ps $(STACK_NAME) --no-trunc

scale: ## Scale Papermark service (usage: make scale REPLICAS=4)
	@if [ -z "$(REPLICAS)" ]; then \
		echo "${YELLOW}Usage: make scale REPLICAS=4${NC}"; \
		exit 1; \
	fi
	@echo "${GREEN}Scaling Papermark to $(REPLICAS) replicas...${NC}"
	@docker service scale $(STACK_NAME)_papermark=$(REPLICAS)
	@echo "${GREEN}✓ Scaled to $(REPLICAS) replicas${NC}"

health: ## Check health of all services
	@echo "${GREEN}Checking service health...${NC}"
	@docker stack ps $(STACK_NAME) --filter "desired-state=running"
	@echo ""
	@echo "${GREEN}Papermark health endpoint:${NC}"
	@curl -f $$(grep PAPERMARK_PUBLIC_URL $(ENV_FILE) | cut -d= -f2)/api/health 2>/dev/null | jq || echo "Health check failed"

backup: ## Create manual database backup
	@echo "${GREEN}Creating database backup...${NC}"
	@mkdir -p ./backups
	@docker exec $$(docker ps -q -f name=$(STACK_NAME)_postgres) \
		pg_dump -U papermark papermark > ./backups/manual-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "${GREEN}✓ Backup created in ./backups/${NC}"

restore: ## Restore database from backup (usage: make restore BACKUP=./backups/backup.sql)
	@if [ -z "$(BACKUP)" ]; then \
		echo "${YELLOW}Usage: make restore BACKUP=./backups/backup.sql${NC}"; \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP)" ]; then \
		echo "${YELLOW}Error: Backup file not found: $(BACKUP)${NC}"; \
		exit 1; \
	fi
	@echo "${GREEN}Restoring database from $(BACKUP)...${NC}"
	@docker exec -i $$(docker ps -q -f name=$(STACK_NAME)_postgres) \
		psql -U papermark papermark < $(BACKUP)
	@echo "${GREEN}✓ Database restored${NC}"

restart: ## Restart Papermark service
	@echo "${GREEN}Restarting Papermark service...${NC}"
	@docker service update --force $(STACK_NAME)_papermark
	@echo "${GREEN}✓ Service restarted${NC}"

stop: ## Stop the stack
	@echo "${GREEN}Stopping Papermark stack...${NC}"
	@docker stack rm $(STACK_NAME)
	@echo "${GREEN}✓ Stack stopped${NC}"
	@echo "${YELLOW}Note: Volumes are preserved. Use 'make clean' to remove volumes${NC}"

clean: ## Remove stack and volumes (DESTRUCTIVE!)
	@echo "${YELLOW}WARNING: This will remove all data!${NC}"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "${GREEN}Removing stack...${NC}"; \
		docker stack rm $(STACK_NAME) || true; \
		sleep 10; \
		echo "${GREEN}Removing volumes...${NC}"; \
		docker volume rm $(STACK_NAME)_papermark_postgres_data || true; \
		docker volume rm $(STACK_NAME)_papermark_redis_data || true; \
		docker volume rm $(STACK_NAME)_papermark_uploads || true; \
		echo "${GREEN}✓ Cleanup complete${NC}"; \
	else \
		echo "Cancelled"; \
	fi

shell: ## Open shell in Papermark container
	@docker exec -it $$(docker ps -q -f name=$(STACK_NAME)_papermark | head -1) sh

db-shell: ## Open PostgreSQL shell
	@docker exec -it $$(docker ps -q -f name=$(STACK_NAME)_postgres) \
		psql -U papermark papermark

migrations: ## Run database migrations
	@echo "${GREEN}Running database migrations...${NC}"
	@docker exec -it $$(docker ps -q -f name=$(STACK_NAME)_papermark | head -1) \
		npx prisma db push
	@echo "${GREEN}✓ Migrations complete${NC}"

prune: ## Prune unused Docker resources
	@echo "${GREEN}Pruning unused Docker resources...${NC}"
	@docker system prune -f
	@docker volume prune -f
	@echo "${GREEN}✓ Prune complete${NC}"

.PHONY: test
test: ## Test configuration
	@echo "${GREEN}Testing configuration...${NC}"
	@docker-compose -f $(COMPOSE_FILE) config > /dev/null
	@echo "${GREEN}✓ Configuration is valid${NC}"
