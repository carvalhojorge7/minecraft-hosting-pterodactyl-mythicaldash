#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # Sem cor

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

print_password() {
    echo -e "${YELLOW}${BOLD}[SENHA IMPORTANTE]${NC}${BOLD} $1${NC}"
}

# Verificar sistema operacional
if ! [[ -f /etc/lsb-release && $(cat /etc/lsb-release) == *"Ubuntu"* ]]; then
    print_error "Este script foi feito para Ubuntu 20.04/22.04!"
    exit 1
fi

# Atualizar sistema
print_info "Atualizando sistema..."
apt update && apt upgrade -y

# Instalar dependências
print_info "Instalando dependências..."
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg

# Adicionar repositório PHP
print_info "Configurando PHP 8.2..."
add-apt-repository ppa:ondrej/php -y
apt update

# Instalar PHP e extensões
apt install -y php8.2 php8.2-cli php8.2-common php8.2-gd php8.2-mysql php8.2-mbstring \
    php8.2-bcmath php8.2-xml php8.2-fpm php8.2-curl php8.2-zip

# Remover e reinstalar o MySQL se ele já estiver instalado
if dpkg -l | grep -q mysql-server; then
    print_warning "MySQL já instalado. Removendo para reinstalação..."
    systemctl stop mysql
    apt purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
    rm -rf /etc/mysql /var/lib/mysql
    apt autoremove -y
    apt autoclean
fi

# Instalar MySQL
print_info "Instalando MySQL..."
apt install -y mysql-server

# Gerar senha aleatória para root do MySQL
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
print_password "Senha root do MySQL gerada: $MYSQL_ROOT_PASSWORD"
echo "Por favor, guarde esta senha em um local seguro!"

# Configurar MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
mysql -e "FLUSH PRIVILEGES;"

# Criar banco de dados e usuário para o Pterodactyl
DB_NAME="pterodactyl"
DB_USER="pterodactyl"
DB_PASSWORD=$(openssl rand -base64 32)
print_password "Senha do banco de dados do Pterodactyl: $DB_PASSWORD"

mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER 'pterodactyl'@'%' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'pterodactyl'@'%';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Instalar Redis
print_info "Instalando Redis..."
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Instalar Nginx
print_info "Instalando Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# Baixar Pterodactyl
print_info "Baixando e instalando Pterodactyl..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Corrigir permissões para os diretórios de armazenamento e vendor
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl

# Criar diretório vendor se não existir
if [ ! -d "/var/www/pterodactyl/vendor" ]; then
    mkdir -p /var/www/pterodactyl/vendor
    chown -R www-data:www-data /var/www/pterodactyl/vendor
fi

# Configurar ambiente
print_info "Configurando ambiente..."
cp .env.example .env

# Atualizar as credenciais no arquivo .env
sed -i "s|DB_PASSWORD=|DB_PASSWORD=$DB_PASSWORD|g" .env
sed -i "s|DB_USERNAME=pterodactyl|DB_USERNAME=$DB_USER|g" .env
sed -i "s|DB_DATABASE=panel|DB_DATABASE=$DB_NAME|g" .env

# Gerar chave de aplicação
print_info "Gerando chave de aplicação..."
php artisan key:generate --force

# Executar Composer como usuário não-root
print_info "Instalando dependências do Composer..."
su -s /bin/bash www-data -c "composer install --no-dev --optimize-autoloader"

# Reverter as alterações feitas nas migrações
php artisan migrate:reset

# Configurar banco de dados
php artisan migrate --seed --force

# Atualizar APP_URL no arquivo .env
sed -i "s|APP_URL=http://localhost|APP_URL=http://$(curl -s ifconfig.me)|g" .env

# Criar primeiro usuário
print_info "Criando primeiro usuário..."
php artisan p:user:make

# Configurar permissões
chown -R www-data:www-data /var/www/pterodactyl/*

# Configurar Nginx
cat > /etc/nginx/sites-available/pterodactyl.conf << 'EOL'
server {
    listen 80;
    server_name _;
    
    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Ativar site no Nginx
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Configurar cron
crontab -l | { cat; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"; } | crontab -

# Configurar workers
cat > /etc/systemd/system/pteroq.service << 'EOL'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL

systemctl enable --now pteroq.service

# Finalização
print_info "Instalação concluída!"
print_info "Painel acessível em: http://$(curl -s ifconfig.me)"
print_password "MySQL Root Password: $MYSQL_ROOT_PASSWORD"
print_password "Database Password: $DB_PASSWORD"
