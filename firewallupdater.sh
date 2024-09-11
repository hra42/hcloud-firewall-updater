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

    # Prepare the new rules JSON
    local rules_json="[
        {
            \"description\": \"SSH IPv4\",
            \"direction\": \"in\",
            \"protocol\": \"tcp\",
            \"port\": \"22\",
            \"source_ips\": [
                \"$current_ipv4/32\"
            ]
        }"

    if [ -n "$current_ipv6" ]; then
        rules_json="$rules_json,
        {
            \"description\": \"SSH IPv6\",
            \"direction\": \"in\",
            \"protocol\": \"tcp\",
            \"port\": \"22\",
            \"source_ips\": [
                \"$current_ipv6/128\"
            ]
        }"
    fi

    rules_json="$rules_json]"

    # Update the rules, replacing all existing rules
    echo "$rules_json" | hcloud firewall set-rules "$firewall_id" --rules-file -

    echo "Firewall rules updated. Old rules removed, new rules with current IP(s) added."
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
