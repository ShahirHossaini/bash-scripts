#!/bin/bash

# Exit on error
set -e

# Variables
VPN_DIR="/etc/openvpn"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
SERVER_CONF="$VPN_DIR/server.conf"

# Update system
echo "Updating system..."
apt update && apt upgrade -y

# Install OpenVPN and EasyRSA
echo "Installing OpenVPN and EasyRSA..."
apt install -y openvpn easy-rsa

# Setup EasyRSA
echo "Setting up EasyRSA..."
make-cadir "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

# Initialize PKI and build CA
echo "Initializing PKI..."
./easyrsa init-pki
echo -ne "\n" | ./easyrsa build-ca nopass

# Generate Server Key Pair
echo "Generating server key pair..."
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate Diffie-Hellman Parameters
echo "Generating Diffie-Hellman parameters..."
./easyrsa gen-dh

# Copy generated files to OpenVPN directory
echo "Copying keys and certificates..."
cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem "$VPN_DIR"

# Generate TLS-Auth Key
echo "Generating TLS-Auth key..."
openvpn --genkey --secret "$VPN_DIR/ta.key"

# Create OpenVPN server configuration
echo "Configuring OpenVPN server..."
cat > "$SERVER_CONF" <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
comp-lzo
persist-key
persist-tun
status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOF

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configure firewall
echo "Configuring firewall..."
ufw allow 1194/udp
ufw allow OpenSSH
ufw disable
ufw enable

# Restart OpenVPN service
echo "Starting OpenVPN service..."
systemctl restart openvpn@server
systemctl enable openvpn@server

echo "OpenVPN setup complete!"
