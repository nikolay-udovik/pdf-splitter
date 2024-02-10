#!/bin/bash

# Enhanced PDF Splitting Script with Logging, Working Directory Option, and Zip Capabilities

# Dependencies: pdfinfo, pdftk, du, awk, seq, zip

# Default configuration
input_pdf=""
max_size_kb=10240 # Default to 10 MB in KB
output_prefix="part"
counter=1
current_size_kb=0
working_dir="."
start_page=1

# Function to display usage information
usage() {
    echo -e "\nUsage: $0 --input-pdf PATH --max-size SIZE_IN_MB --part-prefix PREFIX --working-dir DIR"
    echo -e "Example: $0 --input-pdf input.pdf --max-size 10 --part-prefix part --working-dir /path/to/dir\n"
    exit 1
}

# Function for logging with timestamp
log() {
    echo -e "[`date '+%Y-%m-%d %H:%M:%S'`] $1"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input-pdf) input_pdf="$2"; shift 2 ;;
        --max-size) max_size_kb="$2"; shift 2 ;; 
        --part-prefix) output_prefix="$2"; shift 2 ;;
        --working-dir) working_dir="$2"; shift 2 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
done

# Validate required input
if [[ -z "$input_pdf" ]]; then
    log "Error: Input PDF not specified."
    usage
fi

log "===== Starting PDF Splitting Process ====="

# Change to the specified working directory
cd "$working_dir" || { log "Error: Failed to change to working directory $working_dir."; exit 1; }

# Retrieve total number of pages from the PDF
total_pages=$(pdfinfo "$input_pdf" | grep Pages | awk '{print $2}')

# Validate successful page count retrieval
if [[ -z "$total_pages" ]]; then
    log "Error: Failed to retrieve total number of pages from the PDF."
    exit 1
fi

log "Processing PDF: $input_pdf in $working_dir"
log "Total pages: $total_pages"
log "Max size for each part: $((max_size_kb / 1024)) MB"

# Process each page
for ((page=1; page<=total_pages; page++)); do
    pdftk "$input_pdf" cat $page output "tmp_${page}.pdf" 2>/dev/null
    if [ $? -ne 0 ]; then
        log "Warning: Failed to process page $page. Skipping."
        continue
    fi

    tmp_size_kb=$(du -k "tmp_${page}.pdf" | cut -f1)
    if [[ $((current_size_kb + tmp_size_kb)) -le $max_size_kb ]]; then
        current_size_kb=$((current_size_kb + tmp_size_kb))
    else
        if [ $counter -gt 1 ] || [ $page -gt 1 ]; then
            pdftk $(seq -f "tmp_%g.pdf" $((start_page)) $((page - 1))) cat output "${output_prefix}_${counter}.pdf"
            log "Created ${output_prefix}_${counter}.pdf with pages $start_page to $((page - 1))"
        fi
        counter=$((counter + 1))
        start_page=$page
        current_size_kb=$tmp_size_kb
    fi

    if [[ $page -eq $total_pages ]]; then
        pdftk $(seq -f "tmp_%g.pdf" $start_page $page) cat output "${output_prefix}_${counter}.pdf"
        log "Created ${output_prefix}_${counter}.pdf with pages $start_page to $page"
    fi
done

# Cleanup temporary files
rm tmp_*.pdf
log "Temporary files removed."

log "Splitting completed. Created $counter parts."

# Additional variables and logic for zipping the output files
archive_name="${output_prefix}_files.zip"  # Name of the zip archive

log "Zipping split parts into ${archive_name}..."

# Create a zip archive of all PDF parts
zip "$archive_name" "${output_prefix}"_*.pdf

log "Archive created: ${archive_name}"

# Uncomment the following line to
