#!/usr/bin/env bash

die () {
  # Print error message to standard error (>&2)
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}" >&2;
  exit 1;
}

# --- Argument Parsing & Setup ---
ticket=""
CONF_FILE=""

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -t | --ticket )
    shift;
    ticket=$1
    ;;
  -e | --env )
    shift;
    CONF_FILE=$1
    ;;
  *) # Handle unrecognized options
    die ${LINENO} "user-error" "Unrecognized option: $1"
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

# Check for required arguments
[ -n "$CONF_FILE" ] || die ${LINENO} "user-error" "No configuration file provided."
[ -n "$ticket" ] || die ${LINENO} "user-error" "No ticket provided."

# --- Configuration Reading ---
read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR'))

JQ_STATUS=$?

if [[ $JQ_STATUS -ne 0 || -z "$APP_ROOT" || -z "$JOBS_DIR" ]]; then
    die ${LINENO} "config-error" "Failed to read APP_ROOT or JOBS_DIR from $CONF_FILE."
fi

# --- Core Logic ---

# 1. Run the download script and check its exit status immediately.
if ! "${APP_ROOT}/bin/download_attachment.sh" -t "${ticket}" -e "$CONF_FILE"; then
    DOWNLOAD_STATUS=$?
    die ${LINENO} "download-error" "download_attachment.sh failed with exit code $DOWNLOAD_STATUS."
fi

JOB="${JOBS_DIR}/${ticket}-se-list.txt"

# 2. Check for file existence before attempting to read it 💡
if [ -f "$JOB" ]; then
    echo "Processing job list file: $JOB"
    
    # Use read -r with a while loop to read all lines.
    while IFS= read -r identifier || [[ -n "$identifier" ]]; do
      
      # Run the publisher script and check its exit status immediately.
      if ! "${APP_ROOT}/pubdlib.rb" link-handle --identifier "${identifier%%[[:space:]]}" -e "$CONF_FILE"; then
          PUB_STATUS=$?
          die ${LINENO} "link-handle-error" "pubdlib.rb failed for identifier: ${identifier%%[[:space:]]} (Exit code $PUB_STATUS)."
      fi
    done < "$JOB"
    
else
    # Stop the script if the required file doesn't exist
    die ${LINENO} "file-error" "Required job file not found: $JOB"
fi

exit 0
