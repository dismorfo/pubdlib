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

JOB=${APP_ROOT}/jobs/${ticket}-se-list.txt

while IFS= read -r id
  do
    identifier=${id%%[[:space:]]}
    ${APP_ROOT}/viewercli.rb publish -i ${identifier} -e $CONF_FILE
done <${JOB}
