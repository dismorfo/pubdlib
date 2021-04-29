die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

APP_DIR=/home/ortiz/tools/viewercli

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -t | --ticket )
    shift; ticket=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

JOB=${APP_DIR}/jobs/${ticket}-se-list.txt

while IFS= read -r id
  do
    ${APP_DIR}/viewercli.rb publish -i ${id} -e ${APP_DIR}/.env
done <${JOB}
