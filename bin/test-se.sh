#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

APP_DIR=

SERVER=

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -t | --ticket )
    shift; ticket=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

JOB=${APP_DIR}/jobs/${ticket}-se-list.txt

while IFS= read -r id
  do
    status=`curl -s -o /dev/null -I -w "%{http_code}" ${SERVER}/photos/${id}/1 --insecure`
    echo ${SERVER}/photos/${id}/1 - ${status}
done <${JOB}
