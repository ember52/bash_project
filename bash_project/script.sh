#!/bin/bash

# Clone the PERN repository
clone_repo() {
  cd /
  git clone https://github.com/omarmohsen/pern-stack-example
  chmod 777 -R pern-stack-example
  cd pern-stack-example
}

# Install dependencies
install_dependencies() {
  curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
  npm install dotenv express pg pine sequelize swagger-ui-express
}

# Set the IP address, subnet mask and gateway
set_static_ip() {
  IP_ADDR=192.168.1.8
  SUBNET_MASK=255.255.255.0
  GATEWAY=192.168.1.1

  # Create the netplan configuration file
  sudo tee /etc/netplan/01-network-manager-all.yaml << EOF
  network:
    version: 2
    renderer: NetworkManager
    ethernets:
      wlp3s0:
        dhcp4: no
        addresses:
        - $IP_ADDR/24
        routes:
        - to: default
          via: $GATEWAY
  EOF

  # Apply the netplan configuration
  sudo netplan generate
  sudo netplan apply
  sudo systemctl restart NetworkManager
}

# Retrieve the IP address using RE and store it in a variable
retrieve_ip() {
  IP_ADDRESS=$(ip addr show wlp3s0 | grep "inet " | sed -E "s/.*inet ([0-9.]+).*/\1/")
  echo "IP_ADDRESS=$IP_ADDRESS"
}

# Create a node user
create_node-user() {
  sudo useradd node
  sudo passwd node
}

# Install and configure PostgreSQL
install_PostgreSQL() {
  sudo apt install postgresql postgresql-contrib
  sudo systemctl start postgresql.service
  sudo -u postgres psql -c "CREATE DATABASE node"
  sudo -u postgres psql -c "CREATE USER node WITH PASSWORD 'node'"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE node TO node"
}

# Build the backend
backend_build() {
  cd api
  npm install
  npm run build
  echo "Backend built successfully"
}

# Build the frontend
ui_build() {
  cd ui
  npm install
  npm run build
  echo "Frontend built successfully"
}

# Start the app
start_app() {
  cd api
  npm start
  echo "App started successfully"
}

# Run the script
clone_repo
install_dependencies
set_static_ip
sleep 3
retrieve_ip
create_node-user
install_PostgreSQL
backend_build
ui_build
start_app
