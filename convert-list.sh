#!/bin/bash
set -e

# Input files
BLOCKLIST="blocklist.txt"
WHITELIST="whitelist.txt"

# Output files
OUTPUT_BLACKLIST="technitium_blacklist.txt"
OUTPUT_WHITELIST="technitium_whitelist.txt"

# Generate whitelist in memory and write to file
grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$WHITELIST" 2>/dev/null | sort -u > "$OUTPUT_WHITELIST"

# Generate blacklist in memory, remove whitelist, write to file
grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$BLOCKLIST" 2>/dev/null | sort -u \
  | grep -vFf "$OUTPUT_WHITELIST" > "$OUTPUT_BLACKLIST"

echo "Technitium DNS blocklist generated: $OUTPUT_BLACKLIST"
echo "Technitium DNS whitelist generated: $OUTPUT_WHITELIST"
