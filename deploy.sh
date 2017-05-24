#!/bin/bash
#
# Validates and deploys an AWS CloudFormation Stack
#
#######################################

AWS_REGION="${AWS_REGION:-us-west-2}"

ORIG_DIR=`pwd`
SCRIPT_NAME="$0"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
ARGS=("$@")

# ------------------------------------------------------------------------
# script functions

log_error() {
  >&2 echo "ERROR: $1"
}

do_usage_mini() {
  cat >&2 <<EOF
Usage:
  $SCRIPT_NAME <options> [ create | update | delete | describe | geturls | validate | test <email> ]

Options:
  -d     The Slack team domain
  -t     The Slack authentication token
  -o     The full origin domain (e.g. http://www.myhost.com/)
  -v     Display verbose output

EOF
}

do_usage() {
  do_usage_mini
  cat >&2 <<EOF
Description:
  Deploys an AWS CloudFormation that creates a Slack registration service.

EOF
}

# ------------------------------------------------------------------------

_pre_process_template() {
  # if [ -f "$SCRIPT_DIR/cloudformation.json" ]; then
  #   log_error "WARN: Found existing cloudformation.json"
  #   rm "$SCRIPT_DIR/cloudformation.json"
  # fi
  #
  # sed -e "s/\${SLACK_TOKEN}/$SLACK_TOKEN/" "$SCRIPT_DIR/template.json" > "$SCRIPT_DIR/cloudformation.json"
  TEMPLATE="$SCRIPT_DIR/cloudformation.json"
}

_clean_template() {
  if [ -f "$SCRIPT_DIR/cloudformation.json" ]; then
    rm "$SCRIPT_DIR/cloudformation.json"
  fi
}

# ------------------------------------------------------------------------

do_validate() {

  _pre_process_template

  if [ -z "$AWS_REGION" ]; then
    do_usage_mini

    log_error "Please set the AWS region"
    exit 1
  else
    echo "Using AWS Region: $AWS_REGION"
  fi

  # TODO CAPTURE ERROR CODE & exit
  RET=`$AWS_CLI --region $AWS_REGION cloudformation validate-template --template-body file:////$TEMPLATE 2>&1`
  RES="$?"
  if [ ! $RES == 0 ]; then
    echo "$RET"
  fi
  return $RES
}

do_create() {

  if [ -z "$SLACK_DOMAIN" ]; then
    do_usage_mini

    log_error "Please set the Slack domain parameter."
    exit 1
  fi

  if [ -z "$SLACK_TOKEN" ]; then
    do_usage_mini

    log_error "Please set the Slack token parameter."
    exit 1
  fi

  if [ -z "$WEB_ORIGIN" ]; then
    do_usage_mini

    log_error "Please set the origin parameter for CORS."
    exit 1
  fi

  do_validate \
    && $AWS_CLI --region $AWS_REGION cloudformation create-stack --parameters \
      ParameterKey=SlackTeamSubDomain,ParameterValue=$SLACK_DOMAIN \
        ParameterKey=SlackAuthToken,ParameterValue=$SLACK_TOKEN \
        ParameterKey=Origin,ParameterValue=$WEB_ORIGIN \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name slackinviter --template-body file:////$TEMPLATE | jq \
    && echo "Deploy requested, waiting on completion..." \
    && $AWS_CLI --region $AWS_REGION cloudformation wait stack-create-complete --stack-name slackinviter
  RES="$?"
  if [ 0 == $RES ]; then
    do_geturls
  else
    do_describe | jq '.StackEvents[] | select(.ResourceStatus | contains("FAILED"))'
  fi
}

do_update() {

  echo "update"

  do_validate

  # do_validate \
  #   && $AWS_CLI cloudformation update-stack --stack-name slackinviter --template-body file:////$TEMPLATE \
  #   && echo "Deployed, waiting on completion..." \
  #   && $AWS_CLI cloudformation wait stack-update-complete --stack-name slackinviter
}

do_geturls() {
  $AWS_CLI --region $AWS_REGION cloudformation describe-stacks | jq '.Stacks[] | {id: .StackId, url: .Outputs[].OutputValue}'
}

do_describe() {
  $AWS_CLI --region $AWS_REGION cloudformation describe-stack-events --stack-name slackinviter
}

do_delete() {
  $AWS_CLI --region $AWS_REGION cloudformation delete-stack --stack-name slackinviter \
    && echo "Delete requested, waiting on completion..." \
    && $AWS_CLI --region $AWS_REGION cloudformation wait stack-delete-complete --stack-name slackinviter
}

do_test() {
  URL="$(do_geturls | jq -r '.url')"
  EMAIL="${PARAMS[0]}"

  if [ -z "$EMAIL" ]; then
    log_error "'test' needs an email address as a parameter"
    exit 1
  fi

  echo "Testing url: $URL with email: $EMAIL"
  curl -vvv -X POST $URL -H 'Content-type: application/json' -d "{ \"email\": \"$EMAIL\" }"
}

do_estimate() {

  do_validate \
    && $AWS_CLI --region $AWS_REGION cloudformation estimate-template-cost --parameters \
      ParameterKey=SlackTeamSubDomain,ParameterValue=$SLACK_DOMAIN \
      ParameterKey=SlackAuthToken,ParameterValue=$SLACK_TOKEN \
      --template-body file:////$TEMPLATE
}


# ------------------------------------------------------------------------
# read the options

while getopts ":d:t:o:v" opt; do
  case $opt in
    d)
      SLACK_DOMAIN="$OPTARG";
      ;;
    t)
      SLACK_TOKEN="$OPTARG";
      ;;
    o)
      WEB_ORIGIN="$OPTARG";
      ;;
    v)
      OUTPUT_VERBOSE="-vvv";
      ;;
    *)
      ;;
  esac
done

# Extract the overflowing arguments
PARAMS=("${ARGS[@]:$OPTIND}")
CMD_INDEX=`expr $OPTIND - 1`
CMD=${ARGS[ $CMD_INDEX ]}


# ------------------------------------------------------------------------
# check other utils are present

if [ ! `command -v aws` ]; then
  log_error "The AWS CLI command was not found"
  exit 1
fi

AWS_CLI=`command -v aws`

if [ ! `command -v jq` ]; then
  log_error "The 'jq' command was not found."
  exit 1
fi

# ------------------------------------------------------------------------
# process sub-command 

case "$CMD" in
  create)
    do_create
    ;;

  update)
    do_update
    ;;

  delete)
    do_delete
    ;;

  describe)
    do_describe
    ;;

  geturls)
    do_geturls
    ;;

  test)
    do_test
    ;;

  estimate)
    do_estimate
    ;;

  validate)
    do_validate
    ;;

  *)
    do_usage
    ;;
esac

exit 0
