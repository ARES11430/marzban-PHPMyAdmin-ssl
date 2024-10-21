#!/bin/bash

# Ask the user for input
read -p "Enter your domain (e.g., panel.example.com): " domain
read -p "Enter the full path to the PEM certificate file (e.g., /etc/certs/certificate.pem): " pem_file
read -p "Enter the full path to the Key certificate file (e.g., /etc/certs/private.key): " key_file
read -p "Enter the phpMyAdmin port (e.g., 8010): " pma_port
read -p "Enter the desired HTTPS port (e.g., 8443): " https_port

# Check if the nginx directory exists
nginx_dir="/etc/nginx/sites-available"
if [ ! -d "$nginx_dir" ]; then
    echo "Nginx is not installed or the configuration directory is missing."
    exit 1
fi

# Create the Nginx configuration file for phpMyAdmin
config_file="${nginx_dir}/phpmyadmin-${https_port}.conf"
echo "Creating Nginx configuration file at ${config_file}..."

cat <<EOF > $config_file
server {
    listen ${https_port} ssl;
    server_name ${domain};

    ssl_certificate ${pem_file};
    ssl_certificate_key ${key_file};
    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://localhost:${pma_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_log /var/log/nginx/phpmyadmin_error.log;
    access_log /var/log/nginx/phpmyadmin_access.log;
}
EOF

# Create a symbolic link to enable the site
enabled_dir="/etc/nginx/sites-enabled"
sudo ln -s $config_file $enabled_dir

# Test the Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Restart Nginx to apply the changes
if [ $? -eq 0 ]; then
    echo "Restarting Nginx..."
    sudo systemctl restart nginx
    echo "Nginx has been restarted successfully. You can access phpMyAdmin securely at https://${domain}:${https_port}/"
else
    echo "There is an issue with the Nginx configuration. Please check the output above."
fi
