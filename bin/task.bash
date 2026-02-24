#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}" >&2; # Print to stderr
  exit 1;
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -t | --ticket )
    shift;
      ticket=$1
    ;;
  -e | --env )
    shift;
      CONF_FILE=$1
    ;;
  -c | --config )
    shift;
      CONF_FILE=$1
    ;;
  *) # Handle unrecognized options and fail
    die ${LINENO} "user-error" "Unrecognized option: $1"
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

# 1. Check for required CONF_FILE
[ -n "$CONF_FILE" ] || die ${LINENO} "user-error" "No configuration file provided."

# 2. Read APP_ROOT. Check if jq or cat failed, or if the result is empty.
read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR'))

# Immediately save the exit status of the last command in the pipe (jq)
JQ_STATUS=$? 

# Check the status of the jq command. If it's not 0 (success), stop the script.
if [ $JQ_STATUS -ne 0 ]; then
  die ${LINENO} "config-error" "Failed to read configuration variables from $CONF_FILE. jq exited with code $JQ_STATUS."
fi

# 3. Call push.sh and **check its exit status immediately**
# The `if` statement checks the exit status of the command *before* the `then`.
if "${APP_ROOT}/bin/push.sh" -t "${ticket}" -e "$CONF_FILE"; then
    
  # 4. Call handles.sh if push.sh succeeded
  if "${APP_ROOT}/bin/handles.sh" -t "${ticket}" -e "$CONF_FILE"; then
    echo "handles.sh ran successfully."
  else
    # This block executes if handles.sh fails (returns a non-zero status)
    PUSH_STATUS=$?
    die ${LINENO} "push-error" "handles.sh failed with exit code $PUSH_STATUS"
  fi
  
else
  # This block executes if push.sh failed (returns a non-zero status)
  PUSH_STATUS=$?
  die ${LINENO} "push-error" "push.sh failed with exit code $PUSH_STATUS"
fi

exit 0
