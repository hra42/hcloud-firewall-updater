# hcloud-firewall-updater

A Bash script to automatically update Hetzner Cloud firewall rules with your current public IP address.

## Description

This script automates the process of updating a Hetzner Cloud firewall rule to allow SSH access from your current public IP address. It's particularly useful for users with dynamic IP addresses who need to maintain secure access to their Hetzner Cloud resources.

## Features

- Automatically detects your current public IP address
- Updates the specified Hetzner Cloud firewall's SSH rule
- Removes old IP addresses from the rule
- Can be run manually or automatically on shell startup

## Prerequisites

- Hetzner Cloud account
- `hcloud` CLI tool installed and configured with your Hetzner Cloud API token
- `jq` command-line JSON processor
- `curl` command-line tool for transferring data

## Installation

1. Clone this repository or download the script:
git clone https://github.com/hra42/hcloud-firewall-updater.git

or
wget https://raw.githubusercontent.com/hra42/hcloud-firewall-updater/main/update_hcloud_firewall.sh


2. Make the script executable:
chmod +x update_hcloud_firewall.sh


## Usage

Run the script manually by providing the name of your Hetzner Cloud firewall:

./update_hcloud_firewall.sh your-firewall-name


To run the script automatically when opening a new shell, add the following line to your `.bashrc`, `.zshrc`, or `.profile`:

/path/to/update_hcloud_firewall.sh your-firewall-name > /dev/null 2>&1


Replace `/path/to/update_hcloud_firewall.sh` with the actual path to the script, and `your-firewall-name` with the name of your Hetzner Cloud firewall.

## How It Works

1. The script retrieves your current public IP address.
2. It then finds the specified firewall in your Hetzner Cloud project.
3. If an SSH rule exists, it updates the rule to only allow access from your current IP.
4. If no SSH rule exists, it creates a new rule for SSH access from your current IP.

## Troubleshooting

- Ensure that the `hcloud` CLI is properly configured with your Hetzner Cloud API token.
- Check that you have the necessary permissions to modify firewalls in your Hetzner Cloud project.
- Verify that `jq` and `curl` are installed on your system.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE.md) file for details.

## Disclaimer

This script is provided as-is, without any warranties. Always ensure you understand the script's actions before using it in your environment.
