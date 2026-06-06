#!/bin/bash

# crontab -e to add the cron job that runs every 5 minutes
# */5 * * * * $HOME/ChangeIPv46.sh

# Variable info
# Use for IPv4 only on normal DNS:  current_ipv4=$(dig +short +noall +answer A EXAMPLE.COM | awk '{print $NF}')
# Use for IPv6 only on normal DNS:  current_ipv6=$(dig +short +noall +answer AAAA EXAMPLE.COM | awk '{print $NF}')
# Use for IPv4 only on CNAME DNS:   current_ipv4=$(dig +short CNAME EXAMPLE.COM | tail -1 | xargs dig +short A | tail -1)

# Variables
current_ipv4=$(dig +short A EXAMPLE.COM)
current_ipv6=$(dig +short AAAA EXAMPLE.COM)
CF_API_Token=Cloudflare Token that can update Policies
CF_Account_ID=Clodflare Account ID: Usually found after cloudflare.com/
CF_Policy_ID=ID of the Policy to be updated
Policy_Name=Name of Policy to be updated

# Log file
LOG_FILE="$HOME/ChangeIPv46.log"
MAX_LOG_LINES=12

# Function to log messages and maintain max lines
log_message() {
  local message="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $message" >> "$LOG_FILE"

  # Keep only the last MAX_LOG_LINES
  if [ -f "$LOG_FILE" ]; then
    tail -n $MAX_LOG_LINES "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
}

# File to store previous IPs
IP_CACHE_FILE="$HOME/.ipv46_cache"

# Read previous IPs from cache
if [ -f "$IP_CACHE_FILE" ]; then
  source "$IP_CACHE_FILE"
  previous_ipv4="${CACHED_IPV4}"
  previous_ipv6="${CACHED_IPV6}"
else
  previous_ipv4=""
  previous_ipv6=""
fi

# Check if IPs have changed
if [ "$current_ipv4" = "$previous_ipv4" ] && [ "$current_ipv6" = "$previous_ipv6" ]; then
  message="IPs have not changed. IPv4: $current_ipv4, IPv6: $current_ipv6"
  echo "$message"
  log_message "$message"
  exit 0
fi

# IPs have changed, update the policy
message="IP change detected. Previous IPv4: $previous_ipv4 -> Current IPv4: $current_ipv4, Previous IPv6: $previous_ipv6 -> Current IPv6: $current_ipv6"
echo "$message"
log_message "$message"

curl -X PUT "https://api.cloudflare.com/client/v4/accounts/${CF_Account_ID}/access/policies/${CF_Policy_ID}" \
     -H "Authorization: Bearer $CF_API_Token" \
     -H "Content-Type: application/json" \
     --data '{
       "decision": "bypass",
       "name": "'"${Policy_Name}"'",
       "include": [
         {
           "ip": {
             "ip": "'"${current_ipv4}"'"
           }
         },
         {
           "ip": {
             "ip": "'"${current_ipv6}"'"
           }
         }
       ],
       "exclude": [],
       "require": []
     }'

# Cache the current IPs for next run
cat > "$IP_CACHE_FILE" << EOF
CACHED_IPV4="$current_ipv4"
CACHED_IPV6="$current_ipv6"
EOF

message="Policy updated successfully with IPv4: $current_ipv4, IPv6: $current_ipv6"
echo "$message"
log_message "$message"
