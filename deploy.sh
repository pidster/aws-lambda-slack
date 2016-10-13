#!/bin/bash
#
# Validates and deploys an AWS CloudFormation Stack
#
#######################################

AWS_REGION="${AWS_REGION:-us-east-1}"

ORIG_DIR=`pwd`
SCRIPT_NAME="$0"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
CMD="$1"

if [ ! `command -v aws` ]; then
  errout "The AWS CLI command was not found"
  exit 1
fi

AWS_CLI=`which aws`


# ------------------------------------------------------------------------
# script functions

log_error() {
  >&2 echo $1
}

do_usage_mini() {
  cat >&2 <<EOF
Usage:
  $SCRIPT_NAME [ create | update | delete | validate ]

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

  # TODO CAPTURE ERROR CODE & exit
  $AWS_CLI --region $AWS_REGION cloudformation validate-template --template-body file:////$TEMPLATE
}

do_create() {

  _pre_process_template

  echo "create"

  do_validate

  # do_validate \
  #   && $AWS_CLI cloudformation create-stack --stack-name apigateway --template-body file:////$TEMPLATE \
  #   && echo "Deployed, waiting on completion..." \
  #   && $AWS_CLI cloudformation wait stack-create-complete --stack-name apigateway
}

do_update() {

  _pre_process_template

  echo "update"

  do_validate

  # do_validate \
  #   && $AWS_CLI cloudformation update-stack --stack-name apigateway --template-body file:////$TEMPLATE \
  #   && echo "Deployed, waiting on completion..." \
  #   && $AWS_CLI cloudformation wait stack-update-complete --stack-name apigateway
}

do_delete() {

  _pre_process_template

  echo "delete"

  do_validate
  #
  # do_validate \
  #   && $AWS_CLI cloudformation delete-stack --stack-name apigateway
}

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

  validate)
    do_validate
    ;;

  *)
    do_usage
    ;;
esac

exit 0
