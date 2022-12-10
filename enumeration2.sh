#!/bin/bash

# prompt the user for a domain to scan
read -p "Enter the domain to scan: " domain

# use amass to discover subdomains
echo "Discovering subdomains with amass..."
subdomains=$(amass enum -d $domain)

# check which subdomains are alive with httpx
echo "Checking which subdomains are alive with httpx..."
alive_subdomains=()
for subdomain in $subdomains; do
  if httpx -status-code -title -silent $subdomain; then
    alive_subdomains+=($subdomain)
  fi
done

# take screenshots of the alive subdomains with eyewitness
echo "Taking screenshots with eyewitness..."
eyewitness --web -f $alive_subdomains --threads 10 --prepend-https

# do a port scan with masscan for the "top ports"
echo "Doing a port scan with masscan for the top ports..."
masscan -p1-65535 --top-ports 100 $domain > ports.txt

# do a directory bruteforce with dirbuster using the common wordlist
echo "Doing a directory bruteforce with dirbuster using the common wordlist..."
dirbuster -u $alive_subdomains -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt

# search for leaks for this domain in Github with gitleaks
echo "Searching for leaks in Github with gitleaks..."
gitleaks --repo-url https://github.com/$domain

# extract javascript files from all subdomains and search for leaked API keys with JSMiner
echo "Extracting javascript files and searching for leaked API keys with JSMiner..."
for subdomain in $subdomains; do
  # extract javascript files
  wget -r -A js $subdomain
  # search for API keys in the javascript files
  jsminer --api-keys
done

# search for subdomains in the web archive with gau
echo "Searching for subdomains in the web archive with gau..."
gau $domain

# run nuclei with all of its templates for vulnerabilities
echo "Running nuclei with all of its templates for vulnerabilities..."
nuclei -t /usr/share/nuclei/templates/all.yaml -l $alive_subdomains

# run jaeles with all signatures
echo "Running jaeles with all signatures..."
jaeles scan -s /usr/share/jaeles/signatures/all.yaml -u $alive_subdomains

# organize all the output into HTML reports
echo "Organizing all the output into HTML reports..."
# create a new directory for the reports
mkdir $domain-reports
# move all the output files into the directory
mv *.txt *.json *.html $domain-reports
