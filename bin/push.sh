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

read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT, .JOBS_DIR'))

${APP_ROOT}/bin/download_attachment.sh -t ${ticket} -e $CONF_FILE

JOB=${JOBS_DIR}/${ticket}-se-list.txt

while IFS= read -r id
  do
    identifier=${id%%[[:space:]]}
    ${APP_ROOT}/pubdlib.rb publish --identifier ${identifier} -e $CONF_FILE
    if [ $? ] ; then
      ${APP_ROOT}/pubdlib.rb link-handle --identifier ${identifier} -e $CONF_FILE
    fi
done <${JOB}
