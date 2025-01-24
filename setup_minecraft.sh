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

# Criar diretório temporário
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Baixar eggs do Minecraft
print_info "Baixando templates do Minecraft..."
git clone https://github.com/parkervcp/eggs.git
cd eggs/minecraft

# Baixar imagens Docker
print_info "Baixando imagens Docker do Minecraft..."

# Java - Diferentes versões
docker pull ghcr.io/pterodactyl/yolks:java_8
docker pull ghcr.io/pterodactyl/yolks:java_11
docker pull ghcr.io/pterodactyl/yolks:java_16
docker pull ghcr.io/pterodactyl/yolks:java_17
docker pull ghcr.io/pterodactyl/yolks:java_18
docker pull ghcr.io/pterodactyl/yolks:java_19

# Paper - Versões populares
print_info "Baixando Paper MC..."
mkdir -p /mnt/server/paper
cd /mnt/server/paper
curl -o paper-1.20.4.jar https://api.papermc.io/v2/projects/paper/versions/1.20.4/builds/438/downloads/paper-1.20.4-438.jar
curl -o paper-1.19.4.jar https://api.papermc.io/v2/projects/paper/versions/1.19.4/builds/550/downloads/paper-1.19.4-550.jar
curl -o paper-1.18.2.jar https://api.papermc.io/v2/projects/paper/versions/1.18.2/builds/388/downloads/paper-1.18.2-388.jar
curl -o paper-1.16.5.jar https://api.papermc.io/v2/projects/paper/versions/1.16.5/builds/794/downloads/paper-1.16.5-794.jar

# Spigot - Versões populares
print_info "Baixando BuildTools para Spigot..."
mkdir -p /mnt/server/spigot
cd /mnt/server/spigot
curl -o BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

# Forge - Versões populares
print_info "Baixando Forge..."
mkdir -p /mnt/server/forge
cd /mnt/server/forge
# 1.20.1
curl -o forge-1.20.1-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.2.0/forge-1.20.1-47.2.0-installer.jar
# 1.19.4
curl -o forge-1.19.4-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.19.4-45.2.0/forge-1.19.4-45.2.0-installer.jar
# 1.18.2
curl -o forge-1.18.2-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.18.2-40.2.0/forge-1.18.2-40.2.0-installer.jar
# 1.16.5
curl -o forge-1.16.5-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.16.5-36.2.39/forge-1.16.5-36.2.39-installer.jar

# Vanilla - Versões populares
print_info "Baixando Vanilla Minecraft..."
mkdir -p /mnt/server/vanilla
cd /mnt/server/vanilla
# Os links do vanilla são gerados dinamicamente pelo Pterodactyl

# Fabric - Versões populares
print_info "Baixando Fabric..."
mkdir -p /mnt/server/fabric
cd /mnt/server/fabric
curl -o fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar

# Configurar permissões
chown -R pterodactyl:pterodactyl /mnt/server

print_info "Instalação dos templates Minecraft concluída!"
print_info "Versões disponíveis:"
echo "- Paper: 1.20.4, 1.19.4, 1.18.2, 1.16.5"
echo "- Spigot: Via BuildTools"
echo "- Forge: 1.20.1, 1.19.4, 1.18.2, 1.16.5"
echo "- Fabric: Última versão"
echo "- Vanilla: Gerenciado pelo Pterodactyl"

print_warning "Próximos passos:"
echo "1. No painel, vá em 'Nests'"
echo "2. Importe os eggs do diretório: $TEMP_DIR/eggs/minecraft"
echo "3. Configure as variáveis de ambiente conforme necessário"

# Limpar diretório temporário
rm -rf $TEMP_DIR
