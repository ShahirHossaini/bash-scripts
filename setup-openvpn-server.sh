#!/bin/bash

set -e

# Update system packages
apt update && apt upgrade -y

# Install OpenVPN and Easy-RSA
apt install -y openvpn easy-rsa

# Make the Easy-RSA directory
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Export Easy-RSA variables
export EASYRSA_REQ_COUNTRY="US"
export EASYRSA_REQ_PROVINCE="California"
export EASYRSA_REQ_CITY="San Francisco"
export EASYRSA_REQ_ORG="MyOrg"
export EASYRSA_REQ_EMAIL="admin@example.com"
export EASYRSA_REQ_OU="MyUnit"

# Clean up any previous keys
./easyrsa clean-all

# Build the CA
./easyrsa build-ca nopass

# Generate the server certificate and key
./easyrsa build-server-full server nopass

# Generate the Diffie-Hellman parameters
./easyrsa gen-dh

# Generate the client certificate and key
./easyrsa build-client-full client nopass

# Generate the CRL (Certificate Revocation List)
./easyrsa gen-crl

# Copy the necessary files to the OpenVPN directory
cp pki/ca.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/dh.pem /etc/openvpn/
cp pki/crl.pem /etc/openvpn/

# Set up the OpenVPN server configuration
cat > /etc/openvpn/server.conf <<EOL
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA256
crl-verify crl.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOL

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Make IP forwarding persistent
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Set up UFW rules
ufw allow 1194/udp
ufw allow OpenSSH
ufw disable
ufw enable

# Start and enable the OpenVPN service
systemctl start openvpn@server
systemctl enable openvpn@server

# Generate a client configuration file
cat > ~/client.ovpn <<EOL
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
ca [inline]
cert [inline]
key [inline]

<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<cert>
$(cat ~/openvpn-ca/pki/issued/client.crt)
</cert>
<key>
$(cat ~/openvpn-ca/pki/private/client.key)
</key>
EOL

echo "OpenVPN server installation and configuration completed."
echo "Client configuration file is saved at ~/client.ovpn. Replace YOUR_SERVER_IP with your server's public IP."
