#!/bin/bash

# Exit on error
set -e

# Variables
EASYRSA_DIR="/etc/openvpn/easy-rsa"
OUTPUT_DIR="/etc/openvpn/clients"
PORT="1194"

# Ensure a client name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <client-name>"
    exit 1
fi

CLIENT_NAME="$1"

# Prompt the user for the VPN server IP or domain
read -p "Enter the VPN server IP or domain: " VPN_SERVER_IP

# Validate input
if [[ -z "$VPN_SERVER_IP" ]]; then
    echo "Error: You must enter a valid VPN server IP or domain."
    exit 1
fi

# Navigate to EasyRSA directory
cd "$EASYRSA_DIR"

# Generate client key pair
echo "Generating client key pair for $CLIENT_NAME..."
./easyrsa gen-req "$CLIENT_NAME" nopass
./easyrsa sign-req client "$CLIENT_NAME"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR/$CLIENT_NAME"

# Copy client certificate files
cp "pki/ca.crt" "pki/issued/$CLIENT_NAME.crt" "pki/private/$CLIENT_NAME.key" "/etc/openvpn/ta.key" "$OUTPUT_DIR/$CLIENT_NAME/"

# Generate .ovpn client configuration file
echo "Creating OpenVPN client configuration..."
cat > "$OUTPUT_DIR/$CLIENT_NAME/$CLIENT_NAME.ovpn" <<EOF
client
dev tun
proto udp
remote $VPN_SERVER_IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-CBC
auth SHA256
comp-lzo
verb 3

<ca>
$(cat "$OUTPUT_DIR/$CLIENT_NAME/ca.crt")
</ca>
<cert>
$(cat "$OUTPUT_DIR/$CLIENT_NAME/$CLIENT_NAME.crt")
</cert>
<key>
$(cat "$OUTPUT_DIR/$CLIENT_NAME/$CLIENT_NAME.key")
</key>
<tls-auth>
$(cat "$OUTPUT_DIR/$CLIENT_NAME/ta.key")
</tls-auth>
EOF

echo "✅ Client certificate and configuration file created at: $OUTPUT_DIR/$CLIENT_NAME/$CLIENT_NAME.ovpn"
