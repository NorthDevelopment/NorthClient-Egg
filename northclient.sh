#!/bin/bash

# Check if the script is being run as root or with sudo privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo privileges."
  exit 1
fi

echo "Welcome to NorthClient installation script!"
echo "Please select an option:"
echo "1. Install NorthClient without SSL encryption"
echo "2. Install NorthClient with SSL encryption and Nginx"

read -p "Enter your choice (1 or 2): " option

case $option in
  1)
    echo "Installing NorthClient without SSL encryption..."
    apt update && apt upgrade -y
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo apt install git -y
    cd /home/ubuntu
    git clone https://github.com/NorthDevelopment/NorthClient.git
    cd NorthClient
    npm i -g
    npm i node-fetch
    npm i multer
    ufw allow 9000
    ufw reload
    npm install pm2
    ;;
  2)
    echo "Installing NorthClient with SSL encryption and Nginx..."
    read -p "Enter the domain name (e.g., example.com or dash.example.com): " domain
    apt update && apt upgrade -y
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo apt install git -y
    apt install nginx -y
    sudo apt install -y certbot
    sudo apt install -y python3-certbot-nginx
    certbot certonly --nginx -d $domain
    cd /home/ubuntu
    git clone https://github.com/NorthDevelopment/NorthClient.git
    cd NorthClient
    npm i -g
    npm i node-fetch
    npm i multer
    npm install pm2 
    ufw allow 9000
    ufw reload

    # Create and configure the Nginx server block
    echo "Creating Nginx server block..."
    echo "server {
  listen 80;
  server_name $domain;
  return 301 https://\$server_name\$request_uri;
}

server {
  listen 443 ssl http2;
                      
  server_name $domain;
  ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
  ssl_session_cache shared:SSL:10m;
  ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers  HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
                      
  location / {
    proxy_pass http://localhost:9000/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \"Upgrade\";
    proxy_set_header Host \$host;
    proxy_buffering off;
    proxy_set_header X-Real-IP \$remote_addr;
  }
}" | sudo tee /etc/nginx/sites-enabled/northclient.conf

    # Restart Nginx
    echo "Restarting Nginx..."
    sudo systemctl restart nginx
    ;;
  *)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac

echo "Installation completed successfully!To start NorthClient, go to "/home/ubuntu/NorthClient" and run "pm2 start index.js"."
