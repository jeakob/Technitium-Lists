#!/bin/bash
set -e

# Paths
BLOCKLIST="blocklist.txt"
WHITELIST="whitelist.txt"
TEMP_BLACKLIST="temp_blacklist.txt"
TEMP_WHITELIST="temp_whitelist.txt"
OUTPUT_BLACKLIST="technitium_blacklist.txt"
OUTPUT_WHITELIST="technitium_whitelist.txt"

# Clean and deduplicate the blocklist
grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$BLOCKLIST" \
  | sort -u > "$TEMP_BLACKLIST"

# Clean and deduplicate the whitelist
grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' "$WHITELIST" \
  | sort -u > "$TEMP_WHITELIST"

# Remove whitelist domains from blacklist
grep -vFf "$TEMP_WHITELIST" "$TEMP_BLACKLIST" > "$OUTPUT_BLACKLIST"

# Copy whitelist to final output
cp "$TEMP_WHITELIST" "$OUTPUT_WHITELIST"

echo "Technitium DNS blocklist generated: $OUTPUT_BLACKLIST"
echo "Technitium DNS whitelist generated: $OUTPUT_WHITELIST"
