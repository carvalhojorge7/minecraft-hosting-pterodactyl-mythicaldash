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

# Solicitar informações do Pterodactyl
read -p "Digite a URL do seu painel Pterodactyl (ex: https://panel.seudominio.com): " PANEL_URL
read -p "Digite sua API key do Pterodactyl (Client API key): " API_KEY

# Instalar dependências
print_info "Instalando dependências..."
apt update
apt install -y nginx php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} composer unzip git redis-server

# Clonar MythicalDash
print_info "Baixando MythicalDash..."
cd /var/www
git clone https://github.com/MythicalLTD/MythicalDash.git
cd MythicalDash

# Instalar dependências do composer
print_info "Instalando dependências do PHP..."
composer install --no-dev --optimize-autoloader

# Configurar ambiente
print_info "Configurando ambiente..."
cp .env.example .env
php artisan key:generate --force

# Configurar banco de dados
DB_PASSWORD=$(openssl rand -base64 32)
print_warning "Senha do banco de dados gerada: $DB_PASSWORD"

mysql -e "CREATE DATABASE mythicaldash;"
mysql -e "CREATE USER 'mythicaldash'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON mythicaldash.* TO 'mythicaldash'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Configurar .env
sed -i "s|APP_URL=http://localhost|APP_URL=$PANEL_URL|g" .env
sed -i "s|DB_PASSWORD=|DB_PASSWORD=$DB_PASSWORD|g" .env
sed -i "s|PTERODACTYL_URL=|PTERODACTYL_URL=$PANEL_URL|g" .env
sed -i "s|PTERODACTYL_API_KEY=|PTERODACTYL_API_KEY=$API_KEY|g" .env

# Migrar banco de dados
print_info "Configurando banco de dados..."
php artisan migrate --seed --force

# Configurar permissões
chown -R www-data:www-data /var/www/MythicalDash
chmod -R 755 /var/www/MythicalDash
chmod -R 755 storage bootstrap/cache

# Configurar Nginx
print_info "Configurando Nginx..."
cat > /etc/nginx/sites-available/mythicaldash.conf << 'EOL'
server {
    listen 80;
    listen [::]:80;
    server_name client.seudominio.com;
    root /var/www/MythicalDash/public;

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOL

# Ativar site
ln -s /etc/nginx/sites-available/mythicaldash.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Configurar supervisor para filas
print_info "Configurando supervisor..."
apt install -y supervisor

cat > /etc/supervisor/conf.d/mythicaldash.conf << EOL
[program:mythicaldash-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/MythicalDash/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/MythicalDash/storage/logs/worker.log
EOL

supervisorctl reread
supervisorctl update
supervisorctl start all

# Configurar cron
print_info "Configurando cron..."
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/MythicalDash/artisan schedule:run >> /dev/null 2>&1") | crontab -

print_info "Instalação do MythicalDash concluída!"
print_info "Painel de cliente acessível em: http://client.seudominio.com"

print_warning "Próximos passos:"
echo "1. Configure seu domínio DNS para apontar para este servidor"
echo "2. Configure SSL/HTTPS usando Certbot"
echo "3. Acesse o painel e configure os planos de hospedagem"
echo "4. Configure os métodos de pagamento (Stripe/PayPal)"

print_warning "Credenciais importantes:"
echo "Database Password: $DB_PASSWORD"
echo "Guarde estas informações em um local seguro!"
