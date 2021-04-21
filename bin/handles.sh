#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
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
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

[ $CONF_FILE ] || die ${LINENO} "user-error" "No configuration file provided."

# Load configuration file.
. $CONF_FILE

# No identifier test for ticket.
JOB=${APP_ROOT}/jobs/${ticket}-se-list.txt

[ ! -f "$JOB" ] && die ${LINENO} "user-error" "Job se/ie not found."

while IFS= read -r id
  do
    identifier=${id%%[[:space:]]}
    ${APP_ROOT}/viewercli.rb -i $identifier link-handle -e $CONF_FILE
done <${JOB}

exit 0
