#!/bin/bash

set -e

unset APIKEY
unset REGISTERCALL

SCRIPT_REL_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(cd $SCRIPT_REL_DIR && pwd)

source $SCRIPT_DIR/api.conf

while [[ "$#" -gt 0 ]]; do
    case $1 in
      -r  | --regcall ) INPUT=1 REGISTERCALL=1 FROM=$2 TO=$3 REASON=$4
      ;;
      -gn | --get-numbers ) INPUT=1 && cat $SCRIPT_DIR/verifiedcalls/numbers.conf
      ;;
      -gr | --get-reasons ) INPUT=1 && cat $SCRIPT_DIR/verifiedcalls/callreasons.conf
      ;;
      -gp | --get-profiles ) INPUT=1 && GET_PROFILES=1
      ;;
      -h | --help | \? ) INPUT=1 \
      echo "Usage:"
      echo ""
      echo "--regcall <from-number> <to-number> \"<reason>\"    | -r  | Register a verified call"
      echo "--get-numbers                                     | -gn | Get available call-from numbers"
      echo "--get-reasons                                     | -gr | Get available call reasons"
      echo "--get-profiles                                    | -gp | Get available business call profiles"
      echo "--help                                            | -h  | Print this help message"
      exit 0
      ;;
    esac
    shift
  done

if [ -z $INPUT ]; then
    echo "Empty or invalid parameter. Pass -h for help."
    unset APIKEY
    exit 1
fi

verifiedcall_getprofiles() {
    curl -s -X GET \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         -H "Authorization: Bearer $APIKEY" \
         -g "https://api.telnyx.com/v2/verified_calls_display_profiles?page[number]=1&page[size]=20"
}

verifiedcall_register_call() {
    curl -s -X POST https://api.telnyx.com/v2/calls/register \
         -H "Content-Type: application/json" \
         -H "Accept: application/json" \
         -H "Authorization: Bearer $APIKEY" \
         -d "{\"from\": \"$FROM\", \"to\": \"$TO\", \"reason\": \"$REASON\"}"
}

if [[ "$GET_PROFILES" -eq 1 ]]; then
    if [ -z $APIKEY ]; then
        echo "No API key specified in config. Please create and/or update api.conf file."
        exit 1
    fi
    verifiedcall_getprofiles | jq
    unset APIKEY
    exit 0
fi

if [[ "$REGISTERCALL" -eq 1 ]]; then
    if [ -z $APIKEY ]; then
        echo "No API key specified in config. Please create and/or update api.conf file."
        exit 1
    fi
    if [ -z $REASON ]; then
        echo "You must specify an approved call reason. For help, pass -h."
        unset APIKEY
        exit 1        
    else
        verifiedcall_register_call | jq
        unset APIKEY
        exit 0
    fi
fi

unset APIKEY