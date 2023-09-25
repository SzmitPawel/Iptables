
# Firewall Configuration Script

This repository contains a firewall script designed to enhance the security of your system by configuring iptables rules. The script allows outgoing traffic by default but restricts incoming and transit traffic, while also providing whitelisted access for trusted sources.

## Getting Started

These instructions will guide you on how to configure and run the firewall script on your system.

### Prerequisites

Before you begin, make sure you have the following prerequisites installed:

- iptables: The script relies on iptables to configure firewall rules.
Make sure it is installed on your system.

## Firewall Rules for Ubuntu

### Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/SzmitPawel/iptables-setup.git

2. Change owner 
    ```bash
    sudo chown root:root iptables-ubuntu.sh

3. Grant permission for the firewall script:
    ```bash
    sudo chmod 751 /etc/init.d/iptables-ubuntu.sh

4. Copy the firewall script to the init.d directory:
    ```bash
    sudo cp iptables-ubuntu.sh /etc/init.d/

5. Create a symbolic link to enable the script to run at system startup:
    ```bash
    sudo update-rc.d iptables-ubuntu.sh defaults

6. To remove a symbolic link, use the following command:
    ```bash
    update-rc.d -f iptables-ubuntu.sh remove

7. After performing these steps, close the terminal and restart your computer.
    The firewall rules should be automatically applied.
    ```bash
    sudo reboot

### Usage

1. To stop the firewall, use the following command:
    ```bash
    sudo /etc/init.d/iptables-ubuntu.sh stop

2. To start the firewall, use the following command:
    ```bash
    sudo /etc/init.d/iptables-ubuntu.sh start

5. To check if the firewall is active and the configured rules are in effect, you can use the following command:
    ```bash
    sudo iptables -L -v -n

## Changing the Log File

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


## Firewall Rules for Raspbbery Pi

### Installation

1. Install, sudo apt-get install iptables-persistent, use the following command:
    ```bash
    sudo apt-get install iptables-persistent

2. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/SzmitPawel/iptables-setup.git

3. Change owner, use the following command: 
    ```bash
    sudo chown pi:pi iptables-raspbbery.sh

4. Grant permission for the firewall script, use the following command:
    ```bash
    sudo chmod 751 /etc/init.d/iptables-ubuntu.sh

5. Copy the firewall script to the init directory, use the following command:
    ```bash
    sudo cp iptables-raspbbery.sh /etc/iptables-ubuntu.sh

5. Load the rules, use the following command:
    ```bash
    sudo iptables-restore < /etc/iptables-ubuntu.sh

6. Check that they loaded correctly, use the following command:
    ```bash
     sudo iptables -L -v -n

7. All OK ? Save the rules, use the following command:
    ```bash
    sudo sh -c 'iptables-save > /etc/iptables-ubuntu.sh'

8. Force rules to load on reboot, use the following command:
    ```bash
    sudo nano /etc/network/if-pre-up.d/iptables
    ```
    ```
    Add these lines:

    #!/bin/sh
    /sbin/iptables-restore < /etc/iptables-ubuntu.sh
    ```

9. Make that file executable, use the following command:
    ```bash
    sudo chmod +x /etc/network/if-pre-up.d/iptables
## License

[MIT](https://choosealicense.com/licenses/mit/)

