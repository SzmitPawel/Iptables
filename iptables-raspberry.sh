*filter

# Name: Linux Firewall Iptables For Raspberry Pi
# Author: Szmit Paweł
# Date Created: September 24, 2023
# Last Updated: September 24, 2023

####################################################################################################
# Script Purpose:
# The script aims to defaultly discard incoming and transit
# traffic, except for traffic originating from a whitelist
# of trusted sources.
# Outgoing traffic is typically allowed.
# There is awareness that the server may potentially be a
# source of attacks on other servers, suggesting the need
# to consider stricter rules for outgoing traffic if
# security concerns arise.
####################################################################################################

####################################################################################################
# Unification of terms
# To make it easier to understand, the terms of rules and
# comments are unified below
#
# ACCEPT : Authorization
# DROP   : Discard
# REJECT : Rejection
####################################################################################################

####################################################################################################
# Cheat sheet:
#
# -A, --append       Add one or more new rules to designated chain
# -D, --delete       Delete one or more rules from designated chain
# -P, --policy       Set the specified chain policy to the specified target
# -N, --new-chain    Create a new user-defined chain
# -X, --delete-chain Delete specified user-defined chain
# -F                 Table initialization
#
# -p, --protocol      protocol           Specify protocols (tcp, udp, icmp, all)
# -s, --source        IP address[/mask]  Source address. Describe IP address or host name
# -d, --destination   IP address[/mask]  Destination address. Describe IP address or host name
# -i, --in-interface  device             Specify the interface on which the packet comes in.
# -o, --out-interface device             Specify the interface on which the packet appears
# -j, --jump          target             Specify an action when a condition is met
# -t, --table         table              Specify table
# -m state --state    State              Specify condition of packet as condition
#                                        For state, NEW, ESTABLISHED, RELATED, INVALID can be specified
# !            Reverse condition (except for ~)
####################################################################################################

####################################################################################################
# Port Definitions:
####################################################################################################
#SSH=22
#FTP=20,21
#DNS=53
#SMTP=25,465,587
#POP3=110,995
#IMAP=143,993
#HTTP=80,443
#IDENT=113
#NTP=123
#MYSQL=3306
#NET_BIOS_UDP=137,138,139,445
#NET_BIOS_TCP=139,445
#ZEROCONF=5353
#DHCP=67,68

####################################################################################################
# Set Policies: Default to DROP for incoming traffic.
####################################################################################################
-P INPUT   DROP
-P OUTPUT  ACCEPT
-P FORWARD DROP

####################################################################################################
# Allow Packet Communication after Session Establishment:
####################################################################################################
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

####################################################################################################
# Other Rules and Security Measures:
####################################################################################################

####################################################################################################
# Attack countermeasure: Stealth Scan
# Make a chain with the name "STEALTH_SCAN"
####################################################################################################
-N STEALTH_SCAN
-A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
-A STEALTH_SCAN -j DROP

# Jump to "STEALTH_SCAN" chain for stealth scan-like packets
-A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN

-A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN

-A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
-A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN

####################################################################################################
# Attack countermeasure: Port scan by fragment packet, DOS attack
# namap -v -sF Measures such as
####################################################################################################
-A INPUT -f -j LOG --log-prefix "fragment_packet: "
-A INPUT -f -j DROP

####################################################################################################
# Attack countermeasure: Ping of Death
# Make chain with the name "PING_OF_DEATH"
# Discard if more than 1 ping per second lasts ten times
####################################################################################################
-N PING_OF_DEATH
-A PING_OF_DEATH -p icmp --icmp-type echo-request -m hashlimit --hashlimit 1/s --hashlimit-burst 10 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_PING_OF_DEATH -j RETURN

# Discard ICMP exceeding limit
-A PING_OF_DEATH -j LOG --log-prefix "ping_of_death_attack: "
-A PING_OF_DEATH -j DROP

# ICMP jumps to "PING_OF_DEATH" chain
-A INPUT -p icmp --icmp-type echo-request -j PING_OF_DEATH

####################################################################################################
# Attack measures: SYN Flood Attack
# In addition to this countermeasure, you should turn on Syn Cookie.
# Make a chain with the name "SYN_FLOOD"
####################################################################################################
-N SYN_FLOOD
-A SYN_FLOOD -p tcp --syn -m hashlimit --hashlimit 200/s --hashlimit-burst 3 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_SYN_FLOOD -j RETURN

# Commentary
# -m hashlimit                       Use hashlimit instead of limit to limit for each host
# --hashlimit 200/s                  Max 200 connections in a second
# --hashlimit-burst 3                Restriction is imposed if connection exceeding the above upper limit is three consecutive times
# --hashlimit-htable-expire 300000   Validity period of record in management table (unit: ms
# --hashlimit-mode srcip             Manage requests by source address
# --hashlimit-name t_SYN_FLOOD       Hash table name saved in / proc / net / ipt_hashlimit
# -j RETURN                          If it is within the limit, it returns to the parent chain

# Discard SYN packet exceeding limit
-A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
-A SYN_FLOOD -j DROP

# SYN packet jumps to "SYN_FLOOD" chain
-A INPUT -p tcp --syn -j SYN_FLOOD

####################################################################################################
# Attack measures: HTTP DoS/DDoS Attack
# Make chain with the name "HTTP_DOS"
####################################################################################################
-N HTTP_DOS
-A HTTP_DOS -p tcp -m multiport --dports 80,443 -m hashlimit --hashlimit 1/s --hashlimit-burst 100 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_HTTP_DOS -j RETURN

# Commentary
# -m hashlimit                       Use hashlimit instead of limit to limit for each host
# --hashlimit 1/s                    Maximum one connection per second
# --hashlimit-burst 100              It will be restricted if the above upper limit is exceeded 100 times in a row.
# --hashlimit-htable-expire 300000   Validity period of record in management table (unit: ms
# --hashlimit-mode srcip             Manage requests by source address
# --hashlimit-name t_HTTP_DOS        Hash table name saved in / proc / net / ipt_hashlimit
# -j RETURN                          If it is within the limit, it returns to the parent chain

# Discard connection exceeding limit
-A HTTP_DOS -j LOG --log-prefix "http_dos_attack: "
-A HTTP_DOS -j DROP

# Packets to HTTP jump to "HTTP_DOS" chain
-A INPUT -p tcp -m multiport --dports 80,443 -j HTTP_DOS

####################################################################################################
# Attack measures: IDENT port probe
# Use ident to allow an attacker to prepare for future attacks,
# Perform a port survey to see if the system is vulnerable
# There is likely to be.
# DROP REJECT as the response of the mail server etc. falls
####################################################################################################
-A INPUT -p tcp --dport 113 -j REJECT --reject-with tcp-reset

####################################################################################################
# Attack measures: SSH Brute Force
# In the case of a server using password authentication, SSH prepares for a password full attack.
# Try to make a connection try only five times per minute.
# In order to prevent the SSH client side from repeating reconnection, make REJECT instead of DROP.
# If the SSH server is password-on authentication, uncomment out the following
####################################################################################################
# -A INPUT -p tcp --syn --dports 22 -m recent --name ssh_attack --set
# -A INPUT -p tcp --syn --dports 22 -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j LOG --log-prefix "ssh_brute_force: "
# -A INPUT -p tcp --syn --dports 22 -m recent --name ssh_attack --rcheck --seconds 60 --hitcount 5 -j REJECT --reject-with tcp-reset

####################################################################################################
# Attack measures: FTP Brute Force
# FTP prepares for password full attacks for password authentication.
# Try to make a connection try only five times per minute.
# In order to prevent the FTP client side from repeating reconnection, make REJECT instead of DROP
# When starting FTP server, un-comment out the following
####################################################################################################
# -A INPUT -p tcp --syn -m multiport --dports 20,21 -m recent --name ftp_attack --set
# -A INPUT -p tcp --syn -m multiport --dports 20,21 -m recent --name ftp_attack --rcheck --seconds 60 --hitcount 5 -j LOG --log-prefix "ftp_brute_force: "
# -A INPUT -p tcp --syn -m multiport --dports 20,21 -m recent --name ftp_attack --rcheck --seconds 60 --hitcount 5 -j REJECT --reject-with tcp-reset

####################################################################################################
# Discard packets addressed to all hosts (broadcast address, multicast address)
####################################################################################################
-A INPUT -d 192.168.1.255   -j LOG --log-prefix "drop_broadcast: "
-A INPUT -d 192.168.1.255   -j DROP
-A INPUT -d 255.255.255.255 -j LOG --log-prefix "drop_broadcast: "
-A INPUT -d 255.255.255.255 -j DROP
-A INPUT -d 224.0.0.1       -j LOG --log-prefix "drop_broadcast: "
-A INPUT -d 224.0.0.1       -j DROP

####################################################################################################
# Allow input from all hosts (ANY -> SELF)
####################################################################################################

# ICMP: Setting to respond to pings
-A INPUT -p icmp -j ACCEPT

# HTTP, HTTPS
# -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# SSH: To restrict the host, write a trusted host to TRUST_HOSTS and comment out the following
-A INPUT -p tcp --dport 22 -j ACCEPT

# FTP
# -A INPUT -p tcp -m multiport --dports 20,21 -j ACCEPT

# DNS
# -A INPUT -p tcp --sport 53 -j ACCEPT
# -A INPUT -p udp --sport 53 -j ACCEPT

# SMTP
# -A INPUT -p tcp -m multiport --sports 25,465,587 -j ACCEPT

# POP3
# -A INPUT -p tcp -m multiport --sports 110,995 -j ACCEPT

# IMAP
# -A INPUT -p tcp -m multiport --sports 143,993 -j ACCEPT

# SAMBA NET_BIOS
# -A INPUT -p tcp -m multiport --dports 139,445 -j ACCEPT
# -A INPUT -p udp -m multiport --dports 137,138,139,445 -j ACCEPT

# ZEROCONF
-A INPUT -p udp --sport 5353 -j ACCEPT

# DHCP
# -A INPUT -p udp -m multiport --sports 67,68 -j ACCEPT

####################################################################################################
# Other than that
# Those which also did not apply to the above rule logging and discarding
####################################################################################################
-A INPUT  -j LOG --log-prefix "drop: "
-A INPUT  -j DROP

COMMIT
