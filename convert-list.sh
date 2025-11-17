#!/bin/bash
set -e

# Input files
BLOCKLIST="blocklist.txt"
WHITELIST="whitelist.txt"

# Output files
OUTPUT_BLACKLIST="technitium_blacklist.txt"
OUTPUT_WHITELIST="technitium_whitelist.txt"

# Check if input files exist
if [[ ! -f "$BLOCKLIST" ]]; then
  echo "Error: $BLOCKLIST not found"
  exit 1
fi

if [[ ! -f "$WHITELIST" ]]; then
  echo "Warning: $WHITELIST not found, creating empty whitelist"
  touch "$WHITELIST"
fi

# Generate whitelist - extract domains only
echo "Processing whitelist..."
grep -Eo '([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}' "$WHITELIST" 2>/dev/null \
  | sed 's/^[|]*//; s/[\^$*].*//; s/^@@||//; s/||//g' \
  | sort -u > "$OUTPUT_WHITELIST" || touch "$OUTPUT_WHITELIST"

# Generate blacklist - extract domains, remove whitelist entries
echo "Processing blacklist..."
grep -Eo '([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}' "$BLOCKLIST" 2>/dev/null \
  | sed 's/^[|]*//; s/[\^$*].*//; s/^@@||//; s/||//g' \
  | sort -u \
  | grep -vFxf "$OUTPUT_WHITELIST" > "$OUTPUT_BLACKLIST" || touch "$OUTPUT_BLACKLIST"

# Output statistics
BLACKLIST_COUNT=$(wc -l < "$OUTPUT_BLACKLIST")
WHITELIST_COUNT=$(wc -l < "$OUTPUT_WHITELIST")

echo "✓ Technitium DNS blocklist generated: $OUTPUT_BLACKLIST ($BLACKLIST_COUNT domains)"
echo "✓ Technitium DNS whitelist generated: $OUTPUT_WHITELIST ($WHITELIST_COUNT domains)"
