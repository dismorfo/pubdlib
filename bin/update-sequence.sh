#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

i=0

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -l | --limit )
    shift;
      limit=$1
    ;;
  -e | --env )
    shift;
      CONF_FILE=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

[ $CONF_FILE ] || die ${LINENO} "user-error" "No configuration file provided."

read APP_ROOT < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT'))

until [ "$i" -gt "$limit" ]
  do
   echo $i
   # ${APP_ROOT}/pubdlib.rb update-sequence -e $CONF_FILE
   ((i=$i+1))
   sleep 1
done