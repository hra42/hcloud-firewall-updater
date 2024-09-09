#!/bin/bash

# Function to get the current public IP addresses
get_public_ips() {
    local ipv4=$(curl -s https://api.ipify.org)
    local ipv6=$(curl -s -6 https://api6.ipify.org)
    echo "$ipv4 $ipv6"
}

# Function to get the firewall ID
get_firewall_id() {
    local firewall_name="$1"
    hcloud firewall list -o json | jq -r ".[] | select(.name == \"$firewall_name\") | .id"
}

# Function to update the firewall rule
update_firewall() {
    local firewall_id="$1"
    local current_ipv4="$2"
    local current_ipv6="$3"

    # Get the existing rules
    local rules=$(hcloud firewall describe "$firewall_id" -o json | jq -r '.rules')

    # Find the SSH rule
    local ssh_rule=$(echo "$rules" | jq -r '.[] | select(.description == "SSH")')

    if [ -z "$ssh_rule" ]; then
        echo "No rule with description 'SSH' found. Adding new rules."
        hcloud firewall add-rule "$firewall_id" \
            --description "SSH IPv4" \
            --direction in \
            --protocol tcp \
            --port 22 \
            --source-ips "$current_ipv4/32"

        if [ -n "$current_ipv6" ]; then
            hcloud firewall add-rule "$firewall_id" \
                --description "SSH IPv6" \
                --direction in \
                --protocol tcp \
                --port 22 \
                --source-ips "$current_ipv6/128"
        fi
    else
        # Extract the existing rule details
        local direction=$(echo "$ssh_rule" | jq -r '.direction')
        local port=$(echo "$ssh_rule" | jq -r '.port')
        local protocol=$(echo "$ssh_rule" | jq -r '.protocol')

        # Prepare the rules JSON
        local rules_json="[
            {
                \"description\": \"SSH IPv4\",
                \"direction\": \"$direction\",
                \"protocol\": \"$protocol\",
                \"port\": \"$port\",
                \"source_ips\": [
                    \"$current_ipv4/32\"
                ]
            }"

        if [ -n "$current_ipv6" ]; then
            rules_json="$rules_json,
            {
                \"description\": \"SSH IPv6\",
                \"direction\": \"$direction\",
                \"protocol\": \"$protocol\",
                \"port\": \"$port\",
                \"source_ips\": [
                    \"$current_ipv6/128\"
                ]
            }"
        fi

        rules_json="$rules_json]"

        # Update the rules
        echo "$rules_json" | hcloud firewall set-rules "$firewall_id" --rules-file -

        echo "Firewall rules updated. Old IP(s) removed, new IP(s) added."
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

# Get the current public IP addresses
IPS=$(get_public_ips)
CURRENT_IPV4=$(echo $IPS | cut -d' ' -f1)
CURRENT_IPV6=$(echo $IPS | cut -d' ' -f2)

if [ -z "$CURRENT_IPV4" ]; then
    echo "Failed to get current IPv4 address"
    exit 1
fi

echo "Current IPv4: $CURRENT_IPV4"
if [ -n "$CURRENT_IPV6" ]; then
    echo "Current IPv6: $CURRENT_IPV6"
else
    echo "No IPv6 address detected"
fi

# Update the firewall
update_firewall "$FIREWALL_ID" "$CURRENT_IPV4" "$CURRENT_IPV6"

echo "Firewall update process completed"
