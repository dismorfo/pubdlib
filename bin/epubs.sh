#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

download_file () {
  local filename=$1
  local outputfile=$2
  local url=$3
  # Match ePub files. 
  if [[ "$filename" == *".epub"* ]]; then
    curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${url} --output ${outputfile}
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

read APP_ROOT JOBS_DIR TICKET_ENDPOINT TICKET_USER TICKET_PASS JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR, .TICKET_ENDPOINT, .TICKET_USER, .TICKET_PASS, .JOBS_DIR'))

attachments=`curl --silent -u ${TICKET_USER}:${TICKET_PASS} ${TICKET_ENDPOINT}/rest/api/2/issue/${ticket} | jq -r '.fields.attachment[] | @base64'`

if [ $? ] ; then
  for row in $attachments; do
    read filename url < <(echo $(echo ${row} | base64 --decode | jq -r '.filename, .content'))
    if [ ! -d ${JOBS_DIR}/${ticket} ]; then
      mkdir -p ${JOBS_DIR}/${ticket}
    fi
    download_file ${filename} ${JOBS_DIR}/${ticket}/${filename} ${url}
    if [ $? ] ; then
      echo "Downloaded ${filename} to ${JOBS_DIR}/${ticket}/${filename}"
    else
      echo "Failed to download ${filename} to ${JOBS_DIR}/${ticket}/${filename}"
    fi
  done
fi
