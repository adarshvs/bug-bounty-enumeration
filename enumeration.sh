#!/bin/bash

# Use amass to discover subdomains
amass -d example.com -o subdomains.txt

# Check if subdomains are live or dead
cat subdomains.txt | while read subdomain; do
  if httpx -status-code $subdomain | grep "200" > /dev/null; then
    echo "$subdomain is live"
    # Take screenshots with Eyewitness
    eyewitness -f subdomains_live.txt -d screenshots/$subdomain --threads 10
    # Do a port scan with masscan
    masscan -p1-65535 $subdomain | grep "open" > ports.txt
    # Do directory bruteforcing with dirbuster
    dirbuster -u $subdomain -w /path/to/wordlist.txt -o dirlist.txt
  else
    echo "$subdomain is dead"
  fi
done

# Search for leaks in Github with gitleaks
gitleaks -r https://github.com/example.git -o gitleaks.txt

# Extract JavaScript files and search for API keys with JSMiner
cat subdomains.txt | while read subdomain; do
  curl -s $subdomain | grep ".js" | while read js_file; do
    curl -s $subdomain/$js_file | jsminer -k api_keys.txt
  done
done

# Search subdomains in the web archive with gau
cat subdomains.txt | while read subdomain; do
  gau $subdomain | tee -a gau_output.txt
done

# Run nuclei with all of its templates for vulnerabilities
cat subdomains.txt | while read subdomain; do
  nuclei -t /path/to/templates/ -u $subdomain -o nuclei_output.txt
done

# Run jaeles with all signatures
cat subdomains.txt | while read subdomain; do
  jaeles scan -s /path/to/signatures/ -u $subdomain -o jaeles_output.txt
done

# Organize output into HTML reports
cat <<EOF > report.html
<html>
<body>

<h1>Subdomain Discovery</h1>
<pre>
$(cat subdomains.txt)
</pre>

<h1>Live Subdomains</h1>
<h2>Screenshots</h2>
<pre>
$(ls screenshots/)
</pre>
<h2>Open Ports</h2>
<pre>
$(cat ports.txt)
</pre>
<h2>Directory Bruteforce</h2>
<pre>
$(cat dirlist.txt)
</pre>

<h1>GitLeaks</h1>
<pre>
$(cat gitleaks.txt)
</pre>

<h1>JSMiner</h1>
<pre>
$(cat api_keys.txt)
</pre>

<h1>gau</h1>
<pre>
$(cat gau_output.txt)
</pre>

<h1>nuclei</h1>
<pre>
$(cat nuclei_output
