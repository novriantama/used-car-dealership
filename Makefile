# Used Car Dealership Storefront Makefile

.PHONY: help build up down restart logs logs-backend logs-frontend db-shell clean status

# Colors for terminal output
COLOR_RESET  = \033[0m
COLOR_GREEN  = \033[32m
COLOR_YELLOW = \033[33m
COLOR_BLUE   = \033[34m
COLOR_CYAN   = \033[36m

# Extract variables from .env for local helper scripts if needed
DB_USER = $(shell grep DB_USER .env | cut -d '=' -f2 | tr -d '"\'' | tr -d '\r')
DB_NAME = $(shell grep DB_NAME .env | cut -d '=' -f2 | tr -d '"\'' | tr -d '\r')

help:
	@echo "$(COLOR_BLUE)Tunas Jaya Motor - Used Car Storefront Management Commands:$(COLOR_RESET)"
	@echo ""
	@echo "  $(COLOR_GREEN)make build$(COLOR_RESET)         - Build all Docker images"
	@echo "  $(COLOR_GREEN)make up$(COLOR_RESET)            - Start all services locally in background"
	@echo "  $(COLOR_GREEN)make down$(COLOR_RESET)          - Stop and remove all service containers"
	@echo "  $(COLOR_GREEN)make restart$(COLOR_RESET)       - Restart all services"
	@echo "  $(COLOR_GREEN)make logs$(COLOR_RESET)          - View logs for all services"
	@echo "  $(COLOR_GREEN)make logs-backend$(COLOR_RESET)  - View logs for backend API service"
	@echo "  $(COLOR_GREEN)make logs-frontend$(COLOR_RESET) - View logs for Flutter Nginx frontend"
	@echo "  $(COLOR_GREEN)make db-shell$(COLOR_RESET)      - Access the PostgreSQL database shell"
	@echo "  $(COLOR_GREEN)make status$(COLOR_RESET)        - View status of all running containers"
	@echo "  $(COLOR_GREEN)make clean$(COLOR_RESET)         - Stop services and delete database volumes (factory reset)"
	@echo ""

build:
	@echo "$(COLOR_CYAN)Building Docker images...$(COLOR_RESET)"
	docker compose build

up:
	@echo "$(COLOR_CYAN)Starting services in background...$(COLOR_RESET)"
	docker compose up -d
	@echo "$(COLOR_GREEN)Services started! Access the storefront at http://localhost:8000$(COLOR_RESET)"

down:
	@echo "$(COLOR_YELLOW)Stopping services...$(COLOR_RESET)"
	docker compose down

restart:
	@echo "$(COLOR_CYAN)Restarting services...$(COLOR_RESET)"
	docker compose down
	docker compose up -d
	@echo "$(COLOR_GREEN)Services restarted! Access the storefront at http://localhost:8000$(COLOR_RESET)"

logs:
	docker compose logs -f

logs-backend:
	docker compose logs -f backend

logs-frontend:
	docker compose logs -f frontend

db-shell:
	@echo "$(COLOR_CYAN)Connecting to PostgreSQL database '$(DB_NAME)' as '$(DB_USER)'...$(COLOR_RESET)"
	docker compose exec db psql -U $(DB_USER) -d $(DB_NAME)

status:
	docker compose ps

clean:
	@echo "$(COLOR_YELLOW)Cleaning up containers and database volumes (Factory Reset)...$(COLOR_RESET)"
	docker compose down -v
	@echo "$(COLOR_GREEN)Clean up complete. Database volumes have been reset.$(COLOR_RESET)"
