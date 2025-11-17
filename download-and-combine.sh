#!/bin/bash
set -e

# Input file with URLs
URLS_FILE="blocklist_urls.txt"

# Output files
OUTPUT_FILE="combined_blocklist.txt"
TEMP_DIR="temp_lists"
STATS_FILE="stats.txt"

# Check if URLs file exists
if [[ ! -f "$URLS_FILE" ]]; then
  echo "Error: $URLS_FILE not found"
  echo "Please create a file named '$URLS_FILE' with one URL per line"
  exit 1
fi

# Function to convert any format to plain domains
convert_to_domains() {
  local input_file="$1"
  
  # Remove comments, convert formats, extract domains
  grep -v '^[!#]' "$input_file" 2>/dev/null | \
    sed -E '
      # Remove AdGuard syntax
      s/^\|\|//g
      s/\^.*$//g
      s/^@@//g
      s/\$.*$//g
      
      # Remove hosts file IPs
      s/^(0\.0\.0\.0|127\.0\.0\.1|255\.255\.255\.255|::1|::)\s+//g
      
      # Remove leading/trailing whitespace
      s/^\s+|\s+$//g
      
      # Remove special characters
      s/[\*\|\^]//g
      
      # Remove lines with just IPs
      /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/d
      /^[0-9a-fA-F:]+$/d
    ' | \
    # Only keep valid domain names
    grep -E '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$' 2>/dev/null || true
}

# Create temp directory
mkdir -p "$TEMP_DIR"

echo "Starting blocklist download and conversion..."
echo "=============================================="
echo "Reading URLs from: $URLS_FILE"
echo ""

# Read URLs from file (skip empty lines and comments)
mapfile -t BLOCKLIST_URLS < <(grep -v '^#' "$URLS_FILE" | grep -v '^[[:space:]]*$')

total_lists=${#BLOCKLIST_URLS[@]}
echo "Found $total_lists URLs to process"
echo ""

# Initialize stats
successful_downloads=0
failed_downloads=0
current=0

# Download and process each list
for url in "${BLOCKLIST_URLS[@]}"; do
  current=$((current + 1))
  filename=$(echo "$url" | md5sum | cut -d' ' -f1)
  temp_file="$TEMP_DIR/$filename"
  
  echo "[$current/$total_lists] Downloading: $url"
  
  if curl -sL --max-time 60 --retry 2 "$url" -o "$temp_file" 2>/dev/null; then
    if [ -s "$temp_file" ]; then
      line_count=$(wc -l < "$temp_file" | tr -d ' ')
      echo "  ✓ Downloaded successfully ($line_count lines)"
      # Convert to domains and append to combined file
      convert_to_domains "$temp_file" >> "$TEMP_DIR/all_domains.txt"
      successful_downloads=$((successful_downloads + 1))
    else
      echo "  ✗ Downloaded but file is empty"
      failed_downloads=$((failed_downloads + 1))
    fi
  else
    echo "  ✗ Download failed"
    failed_downloads=$((failed_downloads + 1))
  fi
done

echo ""
echo "=============================================="
echo "Processing and deduplicating domains..."

# Sort, deduplicate, and remove invalid entries
if [ -f "$TEMP_DIR/all_domains.txt" ]; then
  sort -u "$TEMP_DIR/all_domains.txt" | \
    grep -v '^localhost$' | \
    grep -v '^localhost.localdomain$' | \
    grep -v '^local$' | \
    grep -v '^broadcasthost$' | \
    grep -E '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$' \
    > "$OUTPUT_FILE"
  
  # Count unique domains
  domain_count=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
  
  # Generate header
  cat > "${OUTPUT_FILE}.tmp" << EOF
# Combined Technitium DNS Blocklist
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
# Total domains: $domain_count
# Sources: $successful_downloads/$total_lists lists
# Source file: $URLS_FILE
#
EOF
  
  # Append domains to header
  cat "$OUTPUT_FILE" >> "${OUTPUT_FILE}.tmp"
  mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
  
  echo "✓ Combined blocklist created: $OUTPUT_FILE"
  echo "✓ Total unique domains: $domain_count"
else
  echo "✗ Error: No domains were extracted"
  exit 1
fi

# Generate statistics file
cat > "$STATS_FILE" << EOF
Blocklist Generation Statistics
================================
Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Source: $URLS_FILE

Download Statistics:
- Total lists: $total_lists
- Successful: $successful_downloads
- Failed: $failed_downloads
- Success rate: $(awk "BEGIN {printf \"%.1f\", ($successful_downloads/$total_lists)*100}")%

Output:
- Unique domains: $domain_count
- Output file: $OUTPUT_FILE

Failed URLs:
EOF

# Add failed URLs to stats if any
if [ $failed_downloads -gt 0 ]; then
  current=0
  for url in "${BLOCKLIST_URLS[@]}"; do
    current=$((current + 1))
    filename=$(echo "$url" | md5sum | cut -d' ' -f1)
    temp_file="$TEMP_DIR/$filename"
    if [ ! -s "$temp_file" ]; then
      echo "- $url" >> "$STATS_FILE"
    fi
  done
else
  echo "None" >> "$STATS_FILE"
fi

echo ""
cat "$STATS_FILE"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Process completed successfully!"
