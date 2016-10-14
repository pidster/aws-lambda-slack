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
  $SCRIPT_NAME <options> [ create | update | delete | validate ]

Options:
  -d, --domain     The Slack team domain
  -t, --token      The Slack authentication token
  -v, --verbose    Display verbose output

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
  if [ -f "$SCRIPT_DIR/cloudformation.json" ]; then
    log_error "WARN: Found existing cloudformation.json"
    rm "$SCRIPT_DIR/cloudformation.json"
  fi

  sed -e "s/\${SLACK_TOKEN}/$SLACK_TOKEN/" "$SCRIPT_DIR/template.json" > "$SCRIPT_DIR/cloudformation.json"
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

  if [ -z "$SLACK_DOMAIN" ]; then
    do_usage

    log_error "Please set the Slack domain parameter."
    exit 1
  fi

  if [ -z "$SLACK_TOKEN" ]; then
    do_usage

    log_error "Please set the Slack token parameter."
    exit 1
  fi

  if [ -z "$AWS_REGION" ]; then
    do_usage

    log_error "Please set the AWS region"
    exit 1
  fi

  # TODO CAPTURE ERROR CODE & exit
  $AWS_CLI --region $AWS_REGION cloudformation validate-template --template-body file:////$TEMPLATE
}

do_create() {

  do_validate \
    && $AWS_CLI --region $AWS_REGION cloudformation create-stack --parameters \
      ParameterKey=SlackTeamSubDomain,ParameterValue=$SLACK_DOMAIN \
      ParameterKey=SlackAuthToken,ParameterValue=$SLACK_TOKEN \
      --capabilities CAPABILITY_IAM \
      --stack-name slackinviter --template-body file:////$TEMPLATE \
    && echo "Deploy requested, waiting on completion..." \
    && $AWS_CLI --region $AWS_REGION cloudformation wait stack-create-complete --stack-name slackinviter
}

do_update() {

  echo "update"

  do_validate

  # do_validate \
  #   && $AWS_CLI cloudformation update-stack --stack-name slackinviter --template-body file:////$TEMPLATE \
  #   && echo "Deployed, waiting on completion..." \
  #   && $AWS_CLI cloudformation wait stack-update-complete --stack-name slackinviter
}

do_describe() {
  $AWS_CLI --region $AWS_REGION cloudformation describe-stack-events --stack-name slackinviter
}

do_delete() {
  $AWS_CLI --region $AWS_REGION cloudformation delete-stack --stack-name slackinviter \
    && echo "Delete requested, waiting on completion..." \
    && $AWS_CLI --region $AWS_REGION cloudformation wait stack-delete-complete --stack-name slackinviter
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

while getopts ":d:t:v" opt; do
  case $opt in
    d)
      SLACK_DOMAIN="$OPTARG";
      ;;
    t)
      SLACK_TOKEN="$OPTARG";
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
# 

if [ ! `command -v aws` ]; then
  errout "The AWS CLI command was not found"
  exit 1
fi

AWS_CLI=`which aws`

if [ ! `command -v jq` ]; then
  log_error "The 'jq' command was not found."
  exit 1
fi

# ------------------------------------------------------------------------
# 

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
