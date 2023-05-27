#!/bin/bash

# Clone the PERN repository
clone_repo(){
  cd /
  sudo git clone https://github.com/omarmohsen/pern-stack-example 
  sudo chmod 777 -R pern-stack-example 
  cd pern-stack-example     
}

# Install dependencies
install_dependencies(){
  curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  sudo apt-get install -y nodejs
  npm install dotenv express pg pine sequelize swagger-ui-express
}

# Set the IP address, subnet mask and gateway
set_static_ip(){
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
retrieve_ip(){
  IP_ADDRESS=$(ip addr show wlp3s0 | grep "inet " | sed -E "s/.*inet ([0-9.]+).*/\1/")
  echo "IP_ADDRESS=$IP_ADDRESS" 
}

# Create a node user
create_node-user(){
  sudo useradd node
  sudo passwd node
}

# Install and configure PostgreSQL
install_PostgreSQL(){
  sudo apt install postgresql postgresql-contrib
  sudo systemctl start postgresql.service
  sudo -u postgres psql -c "CREATE DATABASE node"
  sudo -u postgres psql -c "CREATE USER node WITH PASSWORD 'node'"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE node TO node"
}


backend_build(){
  pwd
  echo "starting copy"
#Editing the webpack.config.js file to be easy for anyone to understand  
  echo <<EOT >> api/webpack.config.js
const path = require('path');
const webpack = require('webpack');

const environment = process.env.ENVIRONMENT;

console.log('environment:::::', environment);

let ENVIRONMENT_VARIABLES = {
  'process.env.HOST': JSON.stringify('localhost'),
  'process.env.USER': JSON.stringify('node'),
  'process.env.DB': JSON.stringify('node'),
  'process.env.DIALECT': JSON.stringify('postgres'),
  'process.env.PORT': JSON.stringify('5432'),
  'process.env.PG_CONNECTION_STR': JSON.stringify("postgres://node:node@localhost:5432/node")
};

if (environment === 'test') {
  ENVIRONMENT_VARIABLES = {
    'process.env.HOST': JSON.stringify('localhost'),
    'process.env.USER': JSON.stringify('node'),
    'process.env.DB': JSON.stringify('node'),
    'process.env.DIALECT': JSON.stringify('postgres'),
    'process.env.PORT': JSON.stringify('5432'),
    'process.env.PG_CONNECTION_STR': JSON.stringify("postgres://node:node@localhost:5432/node")
  };
} else if (environment === 'production') {
  ENVIRONMENT_VARIABLES = {
    'process.env.HOST': JSON.stringify('localhost'),
    'process.env.USER': JSON.stringify('bhargavbachina'),
    'process.env.DB': JSON.stringify('bhargavbachina'),
    'process.env.DIALECT': JSON.stringify('postgres'),
    'process.env.PORT': JSON.stringify('3080'),
    'process.env.PG_CONNECTION_STR': JSON.stringify("postgres://pgadmin@webappdemopostgre:Tester@123@webappdemopostgre.postgres.database.azure.com:5432/tasks")
  };
}

module.exports = {
  entry: './server.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'api.bundle.js',
    libraryTarget: 'commonjs'
  },
  target: 'node',
  plugins: [
    new webpack.DefinePlugin(ENVIRONMENT_VARIABLES),
  ],
  //externals: ['pg', 'pg-hstore']
  externals: [
    { pg: { commonjs: ['pg'] } },
    { 'pg-hstore': { commonjs: ['pg-hstore'] } }
  ],
};
EOT
 
  
  #sudo cp webpack.config.js /pern-stack-example/api/webpack.config.js
  #cd /
export PG_CONNECTION_STR=postgres://node:node@localhost:5432/node
 echo "Exit code" exit $?
 echo 'build backend *************************************************'
}

#UI Build
ui_build(){
  pwd
  cd ui && npm install && npm run build
  echo 'UI Build*************************************************'
}

#Build and start APP
start_app(){ 
  pwd
  #cd ui
  echo 'start the env *************************************************'
  npm install pg
  ENVIRONMENT=test npm run build
  echo 'finish the env *************************************************'
  cd ..
  pwd
  cp -r ui api
  cd api
  pwd
  echo 'make sure that u at api *************************************************'
  npm start
  echo 'start app *************************************************'
}



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
