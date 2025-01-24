#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para imprimir mensagens
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como root
if [ "$(id -u)" != "0" ]; then
    print_error "Este script precisa ser executado como root!"
    exit 1
fi

# Verificar sistema operacional
if ! [[ -f /etc/lsb-release && $(cat /etc/lsb-release) == *"Ubuntu"* ]]; then
    print_error "Este script foi feito para Ubuntu 20.04/22.04!"
    exit 1
fi

# Solicitar informações do painel
read -p "Digite o FQDN do seu painel (ex: panel.seudominio.com): " PANEL_FQDN
read -p "Digite seu token de node (gerado no painel): " NODE_TOKEN

# Atualizar sistema
print_info "Atualizando sistema..."
apt update && apt upgrade -y

# Instalar dependências
print_info "Instalando dependências..."
apt install -y curl tar unzip git

# Instalar Docker
print_info "Instalando Docker..."
curl -sSL https://get.docker.com/ | CHANNEL=stable bash

# Iniciar e habilitar Docker
systemctl enable --now docker

# Verificar instalação do Docker
if ! docker --version > /dev/null 2>&1; then
    print_error "Falha na instalação do Docker!"
    exit 1
fi

# Pré-baixar imagens Docker do Minecraft
print_info "Baixando imagens Docker do Minecraft..."
docker pull ghcr.io/pterodactyl/yolks:java_17  # Para versões mais recentes
docker pull ghcr.io/pterodactyl/yolks:java_16  # Para 1.17
docker pull ghcr.io/pterodactyl/yolks:java_11  # Para 1.16.5
docker pull ghcr.io/pterodactyl/yolks:java_8   # Para versões antigas

# Criar diretório para o Wings
print_info "Configurando diretório do Wings..."
mkdir -p /etc/pterodactyl
cd /etc/pterodactyl

# Baixar Wings
print_info "Baixando Wings..."
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings

# Criar arquivo de configuração do Wings
print_info "Criando arquivo de configuração..."
cat > /etc/pterodactyl/config.yml << EOL
debug: false
uuid: $(cat /proc/sys/kernel/random/uuid)
token_id: ${NODE_TOKEN%%_*}
token: ${NODE_TOKEN#*_}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: "https://${PANEL_FQDN}"
EOL

# Criar diretórios necessários
mkdir -p /var/lib/pterodactyl/{volumes,archives}
mkdir -p /var/log/pterodactyl

# Configurar systemd service
print_info "Configurando serviço do sistema..."
cat > /etc/systemd/system/wings.service << EOL
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL

# Recarregar systemd
systemctl daemon-reload

# Iniciar Wings
systemctl enable --now wings

# Verificar status do Wings
if ! systemctl is-active --quiet wings; then
    print_error "Falha ao iniciar o Wings!"
    print_info "Verifique os logs com: journalctl -u wings"
    exit 1
fi

# Configurar firewall
print_info "Configurando firewall..."
apt install -y ufw

ufw allow 22
ufw allow 8080
ufw allow 2022
ufw allow 80
ufw allow 443

# Perguntar se quer ativar o firewall
read -p "Deseja ativar o firewall agora? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw --force enable
fi

print_info "Instalação do Wings concluída!"
print_info "Portas abertas:"
echo "- 22 (SSH)"
echo "- 8080 (Wings)"
echo "- 2022 (SFTP)"
echo "- 80 (HTTP)"
echo "- 443 (HTTPS)"

# Configurar templates do Minecraft
print_info "Configurando templates do Minecraft..."
chmod +x setup_minecraft.sh
./setup_minecraft.sh

print_warning "Próximos passos:"
echo "1. Verifique se o node aparece como 'conectado' no seu painel"
echo "2. Configure seus alocações de portas no painel"
echo "3. Teste a criação de um servidor"

print_info "Para ver os logs do Wings:"
echo "journalctl -u wings
