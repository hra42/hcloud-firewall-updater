# hcloud-firewall-updater

A Bash script to automatically update Hetzner Cloud firewall rules with your current public IP address.

## Description

This script automates the process of updating a Hetzner Cloud firewall rule to allow SSH access from your current public IP address. It's particularly useful for users with dynamic IP addresses who need to maintain secure access to their Hetzner Cloud resources.

## Features

- Automatically detects your current public IPv4 and IPv6 addresses
- Updates the specified Hetzner Cloud firewall's SSH rules
- Only updates rules when IP addresses have changed
- Supports both IPv4 and IPv6
- Can be run manually or automatically (e.g., via cron job)

## Prerequisites

- Hetzner Cloud account
- `hcloud` CLI tool installed and configured with your Hetzner Cloud API token
- `jq` command-line JSON processor
- `curl` command-line tool for transferring data

## Installation

1. Clone this repository or download the script:
   ```
   git clone https://github.com/hra42/hcloud-firewall-updater.git
   ```
   or
   ```
   wget https://raw.githubusercontent.com/hra42/hcloud-firewall-updater/main/firewallupdater.sh
   ```

2. Make the script executable:
   ```
   chmod +x firewallupdater.sh
   ```

3. Create a context with the `hcloud` CLI tool:
   ```
   hcloud context create mycontext
   ```

## Usage

Run the script manually by providing the environment name (e.g., Prod):

```
./firewallupdater.sh YOUR_FILEWALL_NAME
```

To run the script automatically, you can set up a cron job. For example, to run it every hour:

1. Open your crontab file:
   ```
   crontab -e
   ```

2. Add the following line:
   ```
   0 * * * * /path/to/firewallupdater.sh Prod > /dev/null 2>&1
   ```

Replace `/path/to/firewallupdater.sh` with the actual path to the script.

## How It Works

1. The script retrieves your current public IPv4 and IPv6 addresses.
2. It then fetches the existing firewall rules for the specified firewall ID.
3. The script compares the current IP addresses with those in the existing rules.
4. If the IP addresses have changed, it updates the firewall rules to allow SSH access (port 22) from your current IP addresses.
5. If the IP addresses haven't changed, no update is performed.

## Configuration

- The firewall ID is hardcoded in the script. Update the `FIREWALL_ID` variable in the script with your specific firewall ID.

## Troubleshooting

- Ensure that the `hcloud` CLI is properly configured with your Hetzner Cloud API token.
- Check that you have the necessary permissions to modify firewalls in your Hetzner Cloud project.
- Verify that `jq` and `curl` are installed on your system.
- If you encounter any "command not found" errors, make sure all required tools are in your system's PATH.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Unlicense - see the [LICENSE](LICENSE.md) file for details.

## Disclaimer

This script is provided as-is, without any warranties. Always ensure you understand the script's actions before using it in your environment. Regularly review and update the script to maintain security and compatibility with your Hetzner Cloud setup.
