# 🎮 Minecraft Hosting Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Uma solução completa de hospedagem de servidores Minecraft com sistema de pagamento integrado. Este projeto combina Pterodactyl Panel para gerenciamento de servidores e MythicalDash para billing e área do cliente.

## ✨ Características

- 🚀 Instalação automatizada do Pterodactyl Panel e Wings
- 💰 Sistema de billing e pagamentos integrado
- 🎮 Suporte a múltiplas versões do Minecraft:
  - Paper, Spigot, Forge, Fabric, Vanilla
- 🔒 Isolamento via Docker
- 📊 Painel administrativo completo
- 👥 Área do cliente moderna e intuitiva
- 🔄 Criação automática de servidores
- 🎯 Ideal para revendedores de hospedagem

## 🚀 Início Rápido

```bash
git clone git@github.com:carvalhojorge7/minecraft-hosting-pterodactyl-mythicaldash.git
cd minecraft-hosting-pterodactyl-mythicaldash
chmod +x install_all.sh
./install_all.sh
```

## 📋 Pré-requisitos

- Ubuntu 20.04 ou 22.04
- Mínimo 1GB de RAM para o Panel
- Mínimo 1GB de RAM para o Wings
- Acesso root ao servidor
- Conexão com internet
- Servidor limpo (recomendado)

## 🚀 Instalação

### Opção 1: Instalação Combinada (Panel + Wings na mesma máquina)

⚠️ Recomendado apenas para testes ou ambientes pequenos

1. Clone o repositório:
```bash
git clone git@github.com:carvalhojorge7/minecraft-hosting-pterodactyl-mythicaldash.git
cd minecraft-hosting-pterodactyl-mythicaldash
```

2. Dê permissão de execução aos scripts:
```bash
chmod +x install_all.sh
```

3. Execute o script de instalação combinada:
```bash
./install_all.sh
```

4. Durante a instalação você precisará:
   - Criar um usuário administrativo
   - Criar uma location no painel
   - Criar um node e copiar o token
   - Fornecer o token para o script

### Opção 2: Instalação Separada

#### Instalando o Panel

1. Clone o repositório:
```bash
git clone git@github.com:carvalhojorge7/minecraft-hosting-pterodactyl-mythicaldash.git
cd pterodactyl-install
```

2. Dê permissão de execução aos scripts:
```bash
chmod +x install_panel.sh install_wings.sh
```

3. Execute o script do panel:
```bash
./install_panel.sh
```

#### Instalando o Wings (Daemon)

1. No painel web, crie um novo node e gere um token de configuração

2. Execute o script do wings:
```bash
./install_wings.sh
```

3. Durante a instalação, você precisará fornecer:
   - FQDN do seu painel (ex: panel.seudominio.com)
   - Token do node (gerado no painel)

## ⚙️ O que os scripts instalam?

### Panel
- PHP 8.1 e extensões necessárias
- MySQL Server
- Redis
- Nginx
- Composer
- Pterodactyl Panel
- Configurações de cron
- Sistema de filas (Queue Worker)

### Wings (Daemon)
- Docker Engine
- Pterodactyl Wings
- Configurações do sistema
- Firewall (UFW)
- Serviço systemd
- Diretórios necessários
- Imagens Docker do Minecraft:
  - Java 17 (Para versões mais recentes)
  - Java 16 (Para 1.17)
  - Java 11 (Para 1.16.5)
  - Java 8 (Para versões antigas)

## 🌐 Frontend do Cliente (MythicalDash)

O MythicalDash é um painel de controle open source que oferece:

### Recursos
- Interface moderna e responsiva
- Sistema de billing integrado
- Suporte a múltiplos métodos de pagamento
- Integração com Pterodactyl
- Gerenciamento de usuários
- Sistema de tickets
- Área do cliente personalizada

### Instalação do Frontend

1. Primeiro, crie uma API key no Pterodactyl:
   - Acesse o painel administrativo
   - Vá em "Application API"
   - Crie uma nova API key com permissões completas

2. Execute o script de instalação:
```bash
chmod +x install_frontend.sh
./install_frontend.sh
```

3. Durante a instalação, você precisará fornecer:
   - URL do seu painel Pterodactyl
   - API key gerada no passo 1

### Configuração Pós-instalação

1. **DNS**:
   Configure seu domínio para apontar para o servidor:
   - Crie um registro A: `client.seudominio.com` → IP do servidor

2. **SSL/HTTPS**:
```bash
certbot --nginx -d client.seudominio.com
```

3. **Planos de Hospedagem**:
   - Acesse o painel admin
   - Configure os planos de Minecraft
   - Defina preços e recursos

4. **Pagamentos**:
   - Configure Stripe e/ou PayPal
   - Defina sua moeda
   - Configure taxas se necessário

### Recursos para Clientes

Seus clientes terão acesso a:
- Painel de controle intuitivo
- Gerenciamento de servidores
- Sistema de pagamentos
- Backups automáticos
- Console web
- Gerenciador de arquivos
- Sistema de suporte

## 🎮 Criando um Servidor Minecraft

Após a instalação, você terá acesso às seguintes versões do Minecraft:

### Versões Disponíveis
- **Paper MC**
  - 1.20.4
  - 1.19.4
  - 1.18.2
  - 1.16.5
  
- **Spigot**
  - Todas as versões via BuildTools
  
- **Forge**
  - 1.20.1
  - 1.19.4
  - 1.18.2
  - 1.16.5
  
- **Fabric**
  - Última versão com suporte a múltiplas versões do MC
  
- **Vanilla**
  - Todas as versões (gerenciadas pelo Pterodactyl)

### Versões do Java
- Java 8 (Para versões antigas)
- Java 11 (Para 1.16.5)
- Java 16 (Para 1.17)
- Java 17 (Para 1.18+)
- Java 18 (Para versões mais recentes)
- Java 19 (Para versões mais recentes)

### Criando um Servidor

1. Acesse o painel administrativo
2. Vá em "Nests" e verifique se o "Minecraft" está disponível
3. Em "Servers", clique em "Create New"
4. Selecione:
   - Nest: Minecraft
   - Egg: Escolha a versão desejada (Paper, Spigot, Forge, etc)
   - A versão do Java será selecionada automaticamente

### Recursos Pré-configurados
- Memória RAM recomendada por servidor: 2-4GB
- Porta padrão: 25565
- RCON habilitado
- Backup automático disponível
- Console web interativo
- Gerenciamento de arquivos via web
- Instalação automática de plugins/mods

⚠️ **Nota**: Para servidores Forge e grandes modpacks, recomenda-se alocar mais memória RAM.

## 🔒 Segurança

Durante a instalação, o script irá:
1. Gerar senhas seguras aleatórias para:
   - Root do MySQL
   - Usuário do banco de dados do Pterodactyl
2. Exibir estas senhas para você salvar
3. Solicitar a criação de um usuário administrativo

⚠️ **IMPORTANTE**: Guarde todas as senhas geradas em um local seguro!

## 📝 Notas importantes

1. Este script deve ser executado em um servidor limpo
2. Faça backup se estiver usando um servidor com dados importantes
3. Para ambiente de produção, você precisará:
   - Configurar SSL/HTTPS
   - Configurar firewall
   - Realizar hardening do servidor
   - Configurar backups

## 🛠️ Pós-instalação

Após a instalação:
1. Acesse o painel através do IP do seu servidor
2. Configure um certificado SSL (recomendado Let's Encrypt)
3. Configure seu domínio
4. Faça as configurações iniciais do painel

## 🐛 Problemas comuns

Se encontrar algum problema:
1. Verifique os logs em `/var/log/pterodactyl/`
2. Verifique os logs do Nginx em `/var/log/nginx/`
3. Certifique-se que todos os serviços estão rodando:
```bash
systemctl status nginx
systemctl status redis-server
systemctl status pteroq.service
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:
1. Abrir issues
2. Enviar pull requests
3. Sugerir melhorias
4. Reportar bugs

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## ⭐ Agradecimentos

- [Pterodactyl](https://pterodactyl.io/) - Pelo excelente painel de gerenciamento
- Comunidade open source
