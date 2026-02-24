#!/usr/bin/env bash

die () {
  echo "file: ${0} | line: ${1} | status: ${2} | message: ${3}";
  exit 1;
}

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -e| --env )
    shift;
      CONF_FILE=$1
    ;;
esac; shift; done

if [[ "$1" == '--' ]]; then shift; fi

[ $CONF_FILE ] || die ${LINENO} "user-error" "No configuration file."

read APP_ROOT JOBS_DIR < <(echo $(cat ${CONF_FILE} | jq -r '.APP_ROOT'))

items=(
  6djh9wm1
  2ngf1w3w
  xwdbrvrm
  t4b8gv7h
  pc866trd
  jq2bvqwh
  dz08kqdm
  95x69pv0
  5dv41pbv
  1ns1rntc
  wwpzgngb
  s4mw6n0g
  ngf1vj65
  cz8w9h5k
  866t1gn8
  hqbzkhqz
  4f4qrg40
  0p2ngfmn
  gqnk99fs
  vx0k6f8q
  r7sqvbg8
  mgqnkb0c
  bzkh18xf
  76hdr8d6
  3ffbg7wv
  zpc867jx
  v15dv4q9
  q83bk47d
  kh1893pt
  fqz6135m
  9zw3r2n4
  66t1g241
  2fqz61mk
)

for item in "${items[@]}"; do
  ${APP_ROOT}/pubdlib.rb register-handle --noid ${item} -e $CONF_FILE
done

exit 0
