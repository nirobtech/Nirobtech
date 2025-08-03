#!/bin/bash

# =============================
# MUH Nirob Advanced Forensics
# =============================

VT_API_KEY="1fc8a22a7dfde724bd874407a3e49e2d298b7a410a8767e9473cd8123d876d58"
OUTPUT_DIR="$HOME/Nirobtech/forensic_reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$OUTPUT_DIR/forensics_report_$TIMESTAMP.txt"

mkdir -p "$OUTPUT_DIR"

echo "Starting forensic scan at $TIMESTAMP" | tee -a "$REPORT_FILE"

echo -e "\n== SYSTEM INFO ==" | tee -a "$REPORT_FILE"
uname -a | tee -a "$REPORT_FILE"
uptime | tee -a "$REPORT_FILE"
df -h | tee -a "$REPORT_FILE"

echo -e "\n== USER INFO ==" | tee -a "$REPORT_FILE"
whoami | tee -a "$REPORT_FILE"
last -n 10 | tee -a "$REPORT_FILE"

echo -e "\n== RUNNING PROCESSES ==" | tee -a "$REPORT_FILE"
ps aux --sort=-%mem | head -n 20 | tee -a "$REPORT_FILE"

echo -e "\n== CRON JOBS ==" | tee -a "$REPORT_FILE"
for user in $(cut -f1 -d: /etc/passwd); do
  crontab -u "$user" -l 2>/dev/null | tee -a "$REPORT_FILE"
done

echo -e "\n== NETWORK CONNECTIONS ==" | tee -a "$REPORT_FILE"
ss -tulnp | tee -a "$REPORT_FILE"

echo -e "\n== GEOIP FOR EXTERNAL IPs ==" | tee -a "$REPORT_FILE"
ips=$(ss -tn | awk '{print $5}' | cut -d: -f1 | grep -Ev '^(127\.|::|0\.0\.0\.0)' | sort -u)
for ip in $ips; do
  geoiplookup $ip | tee -a "$REPORT_FILE"
done

echo -e "\n== VIRUSTOTAL TOP PROCESSES SCAN ==" | tee -a "$REPORT_FILE"
hashes=$(ps aux --no-heading | awk '{print $11}' | xargs -I{} sha256sum $(which {}) 2>/dev/null | awk '{print $1}' | sort -u | head -n 5)
for hash in $hashes; do
  echo "Checking hash: $hash" | tee -a "$REPORT_FILE"
  curl -s --request GET \
    --url "https://www.virustotal.com/api/v3/files/$hash" \
    --header "x-apikey: $VT_API_KEY" | jq '.' >> "$REPORT_FILE"
done

echo -e "\n== AUTH.LOG ERROR SUMMARY ==" | tee -a "$REPORT_FILE"
sudo grep -Ei 'fail|error|denied' /var/log/auth.log | tail -n 30 | tee -a "$REPORT_FILE"

echo -e "\n== HIDDEN FILES IN /HOME ==" | tee -a "$REPORT_FILE"
find /home -name ".*" -type f 2>/dev/null | tee -a "$REPORT_FILE"

echo -e "\nForensic scan completed at $(date)" | tee -a "$REPORT_FILE"

echo "Report saved to $REPORT_FILE"
