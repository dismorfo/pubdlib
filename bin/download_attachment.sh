#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

download_file () {
  local filename=$1
  local url=$2
  # Check if SE
  if [[ "${filename}" = "se-list.txt" ]] ; then
    curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${url} --output ${JOBS_DIR}/${ticket}-se-list.txt
  fi
  # Check if IE.
  if [[ "${filename}" = "ie-list.txt" ]] ; then
    curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${url} --output ${JOBS_DIR}/${ticket}-ie-list.txt
  fi

  # See if we can use this file
  if [[ "${filename}" = "digitization_work_order_report.tsv" ]] ; then
    curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${url} --output ${JOBS_DIR}/${ticket}-${filename}
  fi
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

[ "$ticket" ] || die ${LINENO} "user-error" "No ticket provided."

attachments=`curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${TICKET_ENDPOINT}/rest/api/2/issue/${ticket} | jq -r '.fields.attachment[] | @base64'`

if [ $? ] ; then
  for row in $attachments; do
    read filename url < <(echo $(echo ${row} | base64 --decode | jq -r '.filename, .content'))
    download_file ${filename} ${url}
  done
fi

exit 0
