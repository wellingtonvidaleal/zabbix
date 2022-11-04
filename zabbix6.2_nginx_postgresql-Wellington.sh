#!/bin/bash

## Preparação inicial opcional que gosto de realizar no Debian
sudo apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -f install && apt-get -y autoremove && apt-get -y autoclean
sudo apt-get -y install sudo vim htop net-tools
sudo timedatectl set-timezone America/Sao_Paulo

### Script de instalação do Zabbix 6.2 no Debian 11 com banco PostgreSQL e servidor web Nginx

## Instalação do repositório
sudo apt-get update
sudo apt-get -y install gnupg2
sudo wget https://repo.zabbix.com/zabbix/6.2/debian/pool/main/z/zabbix-release/zabbix-release_6.2-2%2Bdebian11_all.deb
sudo dpkg -i zabbix-release_6.2-2+debian11_all.deb
sudo apt update

## Instalação do SGBD PostgreSQL
sudo apt-get -y install postgresql-13

## Instalação do Nginx
sudo apt-get -y install nginx

## Instalação do servidor, do frontend e do agente Zabbix 
sudo apt-get -y install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

## Criação do banco de dados
sudo sed -i "s/ident/md5/g" /etc/postgresql/13/main/pg_hba.conf
sudo -u postgres psql -c "create user zabbix with encrypted password 'dPNawPmRuj8FM6r9D3f9kMxV3APbU9'" 2>/dev/null
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix 2>/dev/null

## Importação do esquema inicial e dos dados.
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix 

## Configuração do banco de dados para o servidor Zabbix 
sudo sed -i "s/# DBPassword=/DBPassword=dPNawPmRuj8FM6r9D3f9kMxV3APbU9/" /etc/zabbix/zabbix_server.conf

## Configuração do PHP para o frontend Zabbix 
sudo sed -i "s/#        listen          8080;/        listen          8080;/" /etc/zabbix/nginx.conf
sudo sed -i "s/#        server_name     example.com;/        server_name     zabbix.cp.utfpr.edu.br;/" /etc/zabbix/nginx.conf

## Inicialização do servidor Zabbix e dos processos do agente
sudo systemctl stop apache2
sudo systemctl disable apache2
sudo cp /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/default
systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm 