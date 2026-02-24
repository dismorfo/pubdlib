#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -n | --noid )
    shift;
      noid=$1
    ;;
  -e| --env )
    shift;
      CONF_FILE=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

[ $CONF_FILE ] || die ${LINENO} "user-error" "No configuration file."

read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR'))

JOB=${JOBS_DIR}/DLTSAUDIO-71.noids.txt

identifier=${noid%%[[:space:]]}

# ${APP_ROOT}/pubdlib.rb register-handle --noid ${identifier} -e $CONF_FILE

while IFS= read -r id
  do
    identifier=${id%%[[:space:]]}
    ${APP_ROOT}/pubdlib.rb register-handle --noid ${identifier} -e $CONF_FILE
done <${JOB}

exit 0
