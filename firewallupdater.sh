#!/bin/bash

# Function to get the current public IP address
get_public_ip() {
    curl -s https://api.ipify.org
}

# Function to get the firewall ID
get_firewall_id() {
    local firewall_name="$1"
    hcloud firewall list -o json | jq -r ".[] | select(.name == \"$firewall_name\") | .id"
}

# Function to update the firewall rule
update_firewall() {
    local firewall_id="$1"
    local current_ip="$2"

    # Get the existing rules
    local rules=$(hcloud firewall describe "$firewall_id" -o json | jq -r '.rules')

    # Find the SSH rule
    local ssh_rule=$(echo "$rules" | jq -r '.[] | select(.description == "SSH")')

    if [ -z "$ssh_rule" ]; then
        echo "No rule with description 'SSH' found. Adding a new rule."
        hcloud firewall add-rule "$firewall_id" \
            --description "SSH" \
            --direction in \
            --protocol tcp \
            --port 22 \
            --source-ips "$current_ip/32"
    else
        # Extract the existing rule details
        local direction=$(echo "$ssh_rule" | jq -r '.direction')
        local port=$(echo "$ssh_rule" | jq -r '.port')
        local protocol=$(echo "$ssh_rule" | jq -r '.protocol')
        local old_ips=$(echo "$ssh_rule" | jq -r '.source_ips | join(",")')

        # Check if the current IP is already the only IP in the rule
        if [ "$old_ips" = "$current_ip/32" ]; then
            echo "Current IP is already the only IP in the firewall rule. No update needed."
            return
        fi

        # Update the rule with only the new IP
        hcloud firewall set-rules "$firewall_id" \
            --rules-file <(echo "[
                {
                    \"description\": \"SSH\",
                    \"direction\": \"$direction\",
                    \"protocol\": \"$protocol\",
                    \"port\": \"$port\",
                    \"source_ips\": [
                        \"$current_ip/32\"
                    ]
                }
            ]")

        echo "Firewall rule updated. Old IP(s) removed, new IP added."
    fi
}

# Main script

# Check if a firewall name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <firewall_name>"
    exit 1
fi

FIREWALL_NAME="$1"

# Get the firewall ID
FIREWALL_ID=$(get_firewall_id "$FIREWALL_NAME")

if [ -z "$FIREWALL_ID" ]; then
    echo "No firewall found with the name: $FIREWALL_NAME"
    exit 1
fi

echo "Found firewall with ID: $FIREWALL_ID"

# Get the current public IP
CURRENT_IP=$(get_public_ip)

if [ -z "$CURRENT_IP" ]; then
    echo "Failed to get current IP address"
    exit 1
fi

echo "Current IP: $CURRENT_IP"

# Update the firewall
update_firewall "$FIREWALL_ID" "$CURRENT_IP"

echo "Firewall update process completed"
