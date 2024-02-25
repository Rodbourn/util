#!/bin/bash

# Author: Rodbourn
# This script is a quick and dirty way to pull DNS records for a domain using dig
# and convert them into a zone file format for import into DNS management systems,
# like AWS Route 53. It supports excluding specific record types from the output.
# Usage: ./script_name <domain-name> [exclude-record-types]
# Example: ./script_name example.com NS SOA

# Ensure at least a domain name is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <domain-name> [exclude-record-types]"
    echo "Example: $0 example.com NS SOA"
    exit 1
fi

domain=$1
shift # Move past the first argument, which is the domain name

# Define an array of DNS record types
record_types=("A" "AAAA" "CNAME" "MX" "NS" "SOA" "PTR" "TXT" "SRV" "CAA" "DNSKEY" "DS" "NAPTR" "RRSIG" "TLSA" "SMIMEA")

# Exclude specified record types
for exclude in "$@"
do
    record_types=(${record_types[@]//*$exclude*/})
done

# Function to fetch and format DNS records
fetch_records() {
    local record_type=$1
    if [ "$record_type" = "MX" ]; then
        dig $domain MX +noall +answer | awk '{printf "%s %d IN MX %s %s\n", $1, $2, $5, $6}'
    elif [ "$record_type" = "TXT" ]; then
        dig $domain TXT +noall +answer | awk -v ORS='' '{print $1 " " $2 " IN TXT "; for (i=5; i<=NF; i++) printf "%s ", $i; print "\n"}' | sed 's/ \"/ \"/g; s/\" \"/\"/g; s/ $//'
    else
        dig $domain $record_type +noall +answer | awk -v type=$record_type '{printf "%s %d IN %s %s\n", $1, $2, type, $NF}'
    fi
}

echo "; Zone file for $domain"

# Loop through all record types and fetch records
for record_type in "${record_types[@]}"
do
    fetch_records $record_type
done
