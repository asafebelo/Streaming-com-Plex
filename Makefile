SHELL := /bin/bash
CLOUDFLARED_DIR := $(HOME)/.cloudflared

create-tunnel:
	@read -p "Escreva o nome do túnel: " TUNNEL; \
	read -p "Escreva o nome do subdomínio (ex: exemplo.asafebelo.com): " SUBDOMAIN; \
	read -p "Escreva o nome do serviço (ex: ubuntu ou 127.0.0.1): " HOST; \
	read -p "Escreva a porta que será exposta (ex: 8080): " PORT; \
	CONFIG_FILE=$$TUNNEL-config.yml; \
	if cloudflared tunnel list | grep -q "$$TUNNEL"; then \
		echo "Túnel $$TUNNEL já existe. Pulando criação..."; \
	else \
		echo "Criando túnel $$TUNNEL..."; \
		cloudflared tunnel create $$TUNNEL; \
	fi; \
	UUID=$$(cloudflared tunnel list | awk -v t="$$TUNNEL" '$$2==t {print $$1}'); \
	echo "Gerando arquivo de configuração $$CONFIG_FILE (UUID=$$UUID)..."; \
	mkdir -p $(CLOUDFLARED_DIR); \
	printf "tunnel: %s\ncredentials-file: /etc/cloudflared/%s.json\n\ningress:\n  - hostname: %s\n    service: http://%s:%s\n  - service: http_status:404\n" \
	"$$TUNNEL" "$$UUID" "$$SUBDOMAIN" "$$HOST" "$$PORT" \
	> $(CLOUDFLARED_DIR)/$$CONFIG_FILE; \
	echo "TUNNEL_NAME=$$TUNNEL" > .env; \
	echo "CONFIG_FILE=$$CONFIG_FILE" >> .env; \
	echo "PORT=$$PORT" >> .env; \
	echo "Forçando recriação da rota DNS..."; \
	cloudflared tunnel --config $(CLOUDFLARED_DIR)/$$CONFIG_FILE route dns $$TUNNEL $$SUBDOMAIN || true; \
	echo "Configuração concluída!"

update-tunnel:
	@read -p "Escreva o nome do túnel: " TUNNEL; \
	read -p "Escreva o nome do subdomínio (ex: exemplo.asafebelo.com): " SUBDOMAIN; \
	read -p "Escreva o nome do serviço (ex: ubuntu ou 127.0.0.1): " HOST; \
	read -p "Escreva a porta que será exposta (ex: 8080): " PORT; \
	CONFIG_FILE=$$TUNNEL-config.yml; \
	UUID=$$(cloudflared tunnel list | awk -v t="$$TUNNEL" '$$2==t {print $$1}'); \
	echo "Gerando arquivo de configuração $$CONFIG_FILE (UUID=$$UUID)..."; \
	mkdir -p $(CLOUDFLARED_DIR); \
	printf "tunnel: %s\ncredentials-file: /etc/cloudflared/%s.json\n\ningress:\n  - hostname: %s\n    service: http://%s:%s\n  - service: http_status:404\n" \
	"$$TUNNEL" "$$UUID" "$$SUBDOMAIN" "$$HOST" "$$PORT" \
	> $(CLOUDFLARED_DIR)/$$CONFIG_FILE; \
	echo "TUNNEL_NAME=$$TUNNEL" > .env; \
	echo "CONFIG_FILE=$$CONFIG_FILE" >> .env; \
	echo "PORT=$$PORT" >> .env; \
	echo "Recriando rota DNS no Cloudflare..."; \
	cloudflared tunnel --config $(CLOUDFLARED_DIR)/$$CONFIG_FILE route dns $$TUNNEL $$SUBDOMAIN || true; \
	echo "Atualização concluída!"


up:
	@echo "Subindo docker-compose com túnel $$TUNNEL_NAME..."
	docker compose up -d; \
	echo "Verificando logs do Cloudflared..."; \
	docker logs -f $$(docker compose ps -q cloudflared)

pull:
	@echo "Atualizando $$TUNNEL_NAME..."
	docker compose pull $$TUNNEL_NAME; \

down:
	@echo "Derrubando container $$TUNNEL_NAME..."
	docker compose down

