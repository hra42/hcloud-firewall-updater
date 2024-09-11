#!/bin/bash

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide an environment argument (e.g., Prod)"
    exit 1
fi

ENVIRONMENT=$1
FIREWALL_ID=15388  # The firewall ID from your output

# Function to get current IP addresses
get_current_ips() {
    IPV4=$(curl -s https://ipv4.icanhazip.com)
    IPV6=$(curl -s https://ipv6.icanhazip.com)
    echo "Current IPv4: $IPV4"
    echo "Current IPv6: $IPV6"
}

# Function to get existing SSH rule IPs
get_existing_ssh_rule_ips() {
    EXISTING_RULES=$(hcloud firewall describe $FIREWALL_ID -o json)
    EXISTING_IPV4=$(echo "$EXISTING_RULES" | jq -r '.rules[] | select(.direction=="in" and .protocol=="tcp" and .port=="22" and (.source_ips | length == 1)) | .source_ips[0]' | sed -n 's/^\([0-9.]*\)\/32$/\1/p')
    EXISTING_IPV6=$(echo "$EXISTING_RULES" | jq -r '.rules[] | select(.direction=="in" and .protocol=="tcp" and .port=="22" and (.source_ips | length == 1)) | .source_ips[0]' | sed -n 's/^\([0-9a-fA-F:]*\)\/128$/\1/p')
    echo "Existing SSH rule IPv4: $EXISTING_IPV4"
    echo "Existing SSH rule IPv6: $EXISTING_IPV6"
}

# Function to check if IPs have changed
ips_have_changed() {
    if [ "$IPV4" != "$EXISTING_IPV4" ] || [ "$IPV6" != "$EXISTING_IPV6" ]; then
        return 0  # IPs have changed
    else
        return 1  # IPs have not changed
    fi
}

# Function to update SSH rules
update_ssh_rules() {
    # Get all existing rules
    EXISTING_RULES=$(hcloud firewall describe $FIREWALL_ID -o json | jq '.rules')

    # Remove existing SSH rules
    NEW_RULES=$(echo "$EXISTING_RULES" | jq '[.[] | select(.port != "22" or .protocol != "tcp" or .direction != "in")]')

    # Add new SSH rules
    NEW_RULES=$(echo "$NEW_RULES" | jq '. += [
        {
            "direction": "in",
            "protocol": "tcp",
            "port": "22",
            "source_ips": ["'"$IPV4"'/32"],
            "description": "Allow SSH from current IPv4"
        }
    ]')

    if [ ! -z "$IPV6" ]; then
        NEW_RULES=$(echo "$NEW_RULES" | jq '. += [
            {
                "direction": "in",
                "protocol": "tcp",
                "port": "22",
                "source_ips": ["'"$IPV6"'/128"],
                "description": "Allow SSH from current IPv6"
            }
        ]')
    fi

    # Create a temporary file for the rules
    RULES_FILE=$(mktemp)
    echo "$NEW_RULES" > "$RULES_FILE"

    # Apply the updated rules
    hcloud firewall replace-rules $FIREWALL_ID --rules-file "$RULES_FILE"

    # Remove the temporary file
    rm "$RULES_FILE"

    echo "Firewall SSH rules updated. Old SSH rules replaced with new rules for current IP(s)."
}

# Main execution
echo "Checking firewall for $ENVIRONMENT environment"
echo "Found firewall with ID: $FIREWALL_ID"

get_current_ips
get_existing_ssh_rule_ips

if ips_have_changed; then
    echo "IP address(es) have changed. Updating SSH rules..."
    update_ssh_rules
    echo "Firewall update process completed"
else
    echo "IP addresses have not changed. No update needed."
fi
