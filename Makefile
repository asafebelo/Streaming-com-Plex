SHELL := /bin/bash
CLOUDFLARED_DIR := $(HOME)/.cloudflared

create-tunnel:
	@read -p "Escreva o nome do túnel: " TUNNEL; \
	read -p "Escreva o nome do subdomínio (ex: exemplo.asafebelo.com): " SUBDOMAIN; \
	read -p "Escreva o nome do serviço (ex: ubuntu): " HOST; \
	read -p "Escreva a porta que será exposta (ex: 8080): " PORT; \
	echo "Criando túnel $$TUNNEL..."; \
	cloudflared tunnel create $$TUNNEL; \
	echo "Apontando túnel $$TUNNEL para o subdomínio $$SUBDOMAIN..."; \
	cloudflared tunnel route dns $$TUNNEL $$SUBDOMAIN; \
	CRED_FILE=$$(ls $(CLOUDFLARED_DIR) | grep $$TUNNEL.*json | head -n 1 | xargs basename); \
	CONFIG_FILE=$(CLOUDFLARED_DIR)/$$TUNNEL-config.yml; \
	echo "Gerando $$CONFIG_FILE"; \
	cat > $$CONFIG_FILE <<'EOF'
tunnel: $$TUNNEL

credentials-file: /etc/cloudflared/$$CRED_FILE

ingress:
	- hostname: $$SUBDOMAIN
	service: http://$$HOST:$$PORT
	- service: http_status:404

EOF
	@echo "TUNNEL_NAME=$$TUNNEL" > .env; \
	echo "SUBDOMAIN=$$SUBDOMAIN" >> .env; \
	echo "HOST=$$HOST" >> .env; \
	echo "PORT=$$PORT" >> .env; \
	echo "CONFIG_FILE=$$TUNNEL-config.yml" >> .env; \
	echo "Configuração salva em .env e config específico criado"

up:
	@echo "Subindo docker-compose com túnel $$TUNNEL_NAME..."
	docker compose up -d

down:
	@echo "Derrubando container $$TUNNEL_NAME..."
	docker compose down

