#!/usr/bin/env bash

die () {
  # Print error message to standard error (>&2)
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}" >&2;
  exit 1;
}

ticket=""

CONF_FILE=""

experimental="false"

EXTRA_COLLECTIONS=""

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -t | --ticket )
    shift;
    ticket=$1
    ;;
  -e | --env )
    shift;
    CONF_FILE=$1
    ;;
  --experimental )
    shift;
      experimental=$1
    ;;
  -c | --config )
    shift;
    CONF_FILE=$1
    ;;
  --extra-collections)
    shift;
    EXTRA_COLLECTIONS="$1"
    ;;

  *) # Handle unrecognized options
    die ${LINENO} "user-error" "Unrecognized option: $1"
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

# Check if CONF_FILE is provided and the ticket is set
[ -n "$CONF_FILE" ] || die ${LINENO} "user-error" "No configuration file provided."

[ -n "$ticket" ] || die ${LINENO} "user-error" "No ticket provided."

# Use command substitution and check for success
read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR'))

JQ_STATUS=$?

if [[ $JQ_STATUS -ne 0 || -z "$APP_ROOT" || -z "$JOBS_DIR" ]]; then
    die ${LINENO} "config-error" "Failed to read APP_ROOT or JOBS_DIR from $CONF_FILE."
fi

# 1. Run the download script
if ! "${APP_ROOT}/bin/download_attachment.sh" -t "${ticket}" -e "$CONF_FILE"; then
  DOWNLOAD_STATUS=$?
  die ${LINENO} "download-error" "download_attachment.sh failed with exit code $DOWNLOAD_STATUS."
fi

EXTRA_COLLECTIONS_ARG=""
if [ -n "$EXTRA_COLLECTIONS" ]; then
  EXTRA_COLLECTIONS_ARG="--extra-collections $EXTRA_COLLECTIONS"
fi

JOB="${JOBS_DIR}/${ticket}-se-list.txt"

# 2. Check for file existence before running the loop
if [ -f "$JOB" ]; then
    echo "Processing job list file: $JOB"
    # Use read -r with a while loop to read all lines.
    while IFS= read -r id || [[ -n "$id" ]]; do
      # Clean up the ID once to avoid repeating the logic
      clean_id="${id%%[[:space:]]}"      
      if ! "${APP_ROOT}/pubdlib.rb" publish --identifier "$clean_id" -e "$CONF_FILE" --ticket "$ticket" --experimental "$experimental" $EXTRA_COLLECTIONS_ARG; then
          PUB_STATUS=$?
          die "${LINENO}" "publish-error" "pubdlib.rb failed for ID: $clean_id (Exit code $PUB_STATUS)."
      fi
    done < "$JOB"
    
else
    die "${LINENO}" "file-error" "Required job file not found: $JOB"
fi

echo "Script completed successfully."

exit 0
