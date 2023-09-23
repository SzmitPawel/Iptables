
# Firewall Configuration Script

This repository contains a firewall script designed to enhance the security of your system by configuring iptables rules. The script allows outgoing traffic by default but restricts incoming and transit traffic, while also providing whitelisted access for trusted sources.

## Getting Started

These instructions will guide you on how to configure and run the firewall script on your system.

### Prerequisites

Before you begin, make sure you have the following prerequisites installed:

- iptables: The script relies on iptables to configure firewall rules.
Make sure it is installed on your system.

### Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/SzmitPawel/Iptables.git

2. Copy the firewall script to the init.d directory:
    ```bash
    sudo cp firewall.sh /etc/init.d/

3. Grant permission for the firewall script:
    ```bash
    sudo chmod 730 /etc/init.d/firewall.sh

4. Create a symbolic link to enable the script to run at system startup:
    ```bash
    sudo update-rc.d firewall.sh defaults

5. To remove a symbolic link, use the following command:
    ```bash
    update-rc.d -f firewall.sh remove

## Usage

### Start & Stop IPTABLES

1. To stop the firewall, use the following command:
    ```bash
    sudo /etc/init.d/firewall.sh stop

2. To start the firewall, use the following command:
    ```bash
    sudo /etc/init.d/firewall.sh start

3. After performing these steps, close the terminal and restart your computer.
    The firewall rules should be automatically applied.
    ```bash
    sudo reboot

4. To check if the firewall is active and the configured rules are in effect, you can use the following command:
    ```bash
    sudo iptables -L

### Changing the Log File for IPTABLES
1. Edit the configuration file using a text editor (e.g., gedit):
    ```bash
    sudo gedit /etc/rsyslog.conf

2. Add the following line at the end of the file to specify the log file location (in this example, we'll use "/var/log/iptables.log"):
    ```bash
    kern.warning /var/log/iptables.log

You can replace "/var/log/iptables.log" with the desired path and filename for your iptables logs.

3. Save the changes and close the text editor.
4. Restart the rsyslog service to apply the configuration changes:
    ```bash
    sudo service rsyslog restart

Now, iptables will log its messages to the specified log file.


## License

[MIT](https://choosealicense.com/licenses/mit/)

