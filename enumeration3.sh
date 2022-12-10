#!/bin/bash

# Prompt user for domain
echo "Enter a domain: "
read domain

# Use amass to discover subdomains
amass intel -d $domain

# Check if subdomains are alive or dead with httpx
httpx -silent -status-code -title -threads 100 -o $domain-alive-subdomains.txt $(cat $domain-subdomains.txt)

# Take screenshots of live subdomains with Eyewitness
eyewitness -f $domain-alive-subdomains.txt -d $domain-screenshots

# Do a port scan of "top ports" with masscan
masscan -p1-65535,U:1-65535 $domain-alive-subdomains.txt -oG $domain-portscan.txt

# Do a directory bruteforce with dirbuster and common wordlist
dirbuster -u $domain-alive-subdomains.txt -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o $domain-dirbuster.txt

# Search for leaks in Github with gitleaks
gitleaks --repo-path=$domain --report=$domain-gitleaks.txt

# Extract JavaScript files from all subdomains and search for leaked API keys with JSMiner
jsminer -d $domain-subdomains.txt -o $domain-jsminer.txt

# Search for subdomains in web archive with gau
gau $domain-subdomains.txt > $domain-gau.txt

# Run nuclei with all templates for vulnerabilities
nuclei -l $domain-subdomains.txt -t /usr/share/nuclei/templates/ -o $domain-nuclei.txt

# Run jaeles with all signatures
jaeles scan -s /usr/share/jaeles/signatures/ -u $domain-subdomains.txt -o $domain-jaeles.txt

# Organize output into HTML reports
html-report -d $domain -i $domain-alive-subdomains.txt,$domain-screenshots,$domain-portscan.txt,$domain-dirbuster.txt,$domain-gitleaks.txt,$domain-jsminer.txt,$domain-gau.txt,$domain-nuclei.txt,$domain-jaeles.txt -o $domain-report.html
