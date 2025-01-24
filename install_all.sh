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

# Verificar memória
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_MEM -lt 2048 ]; then
    print_error "Seu servidor precisa ter no mínimo 2GB de RAM!"
    print_error "Memória atual: ${TOTAL_MEM}MB"
    exit 1
fi

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

print_warning "Este script irá instalar:"
echo "1. Pterodactyl Panel"
echo "2. Pterodactyl Wings"
echo "3. MythicalDash (Frontend)"
echo "4. Templates Minecraft"
echo
read -p "Deseja continuar? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Instalar Panel
print_info "Iniciando instalação do Panel..."
chmod +x install_panel.sh
./install_panel.sh

if [ $? -ne 0 ]; then
    print_error "Falha na instalação do Panel!"
    exit 1
fi

print_info "Panel instalado com sucesso!"
print_warning "Agora você precisa:"
echo "1. Acessar o painel via navegador"
echo "2. Fazer login com as credenciais criadas"
echo "3. Ir em 'Admin -> Locations' e criar uma location"
echo "4. Ir em 'Admin -> Nodes' e criar um novo node"
echo "5. Copiar o token de configuração gerado"
echo "6. Criar uma API key em 'Application API'"
echo

read -p "Digite o token do node gerado no painel: " NODE_TOKEN
read -p "Digite a API key gerada no painel: " API_KEY

if [ -z "$NODE_TOKEN" ] || [ -z "$API_KEY" ]; then
    print_error "Token e API key não podem ser vazios!"
    exit 1
fi

# Instalar Wings
print_info "Iniciando instalação do Wings..."
chmod +x install_wings.sh
PANEL_FQDN=$(curl -s ifconfig.me)
export NODE_TOKEN PANEL_FQDN

./install_wings.sh

if [ $? -ne 0 ]; then
    print_error "Falha na instalação do Wings!"
    exit 1
fi

# Configurar templates Minecraft
print_info "Configurando templates Minecraft..."
chmod +x setup_minecraft.sh
./setup_minecraft.sh

if [ $? -ne 0 ]; then
    print_error "Falha na configuração dos templates Minecraft!"
    exit 1
fi

# Instalar Frontend
print_info "Instalando Frontend (MythicalDash)..."
chmod +x install_frontend.sh
export PANEL_URL="http://$PANEL_FQDN"
export API_KEY

./install_frontend.sh

if [ $? -ne 0 ]; then
    print_error "Falha na instalação do Frontend!"
    exit 1
fi

print_info "Instalação completa!"
print_info "Acessos:"
echo "- Painel Pterodactyl: http://$PANEL_FQDN"
echo "- Área do Cliente: http://client.$PANEL_FQDN"

print_warning "Próximos passos:"
echo "1. Configure HTTPS/SSL para os domínios"
echo "2. Configure os planos de hospedagem no MythicalDash"
echo "3. Configure os métodos de pagamento"
echo "4. Faça um backup de todas as senhas e tokens"
echo "5. Configure backups regulares"

print_info "Para verificar o status dos serviços:"
echo "Panel Queue: systemctl status pteroq"
echo "Wings: systemctl status wings"
echo "Frontend: systemctl status mythicaldash-worker"
