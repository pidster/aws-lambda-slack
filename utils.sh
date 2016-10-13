#!/bin/sh
# 
# A utility script for 
# 
#####################################################################

SCRIPT_NAME="$0"
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
ARGS=("$@")

# ------------------------------------------------------------------------
# script functions

do_usage_mini() {
  cat >&2 <<EOF
Usage:
  $SCRIPT_NAME <options>  [ channels | channel-info <channel-id> | invite <email> <channel-ids> | team-info ]

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
  A utility script that can be used with a Slack domain and authentication
  token to access Slack API features.

  If you prefer, you can provide the Slack team domain and token as shell
  environment variables: SLACK_DOMAIN and SLACK_TOKEN.


Commands:
  channels
    List all Slack channel names and ids for this team.

  channel-info <channel-id>
    List all Slack channel names and ids for this team.

  invite <email> <channel-ids>
    Invite a user to one or more channels for this Slack team.

  team-info
    Get information about this Slack team.

EOF
}

log_error() {
  >&2 echo $1
}

_slack_rpc() {
  local SLACK_URL="https://${SLACK_DOMAIN}.slack.com/api/$1"
  local PAYLOAD="$2"
  local JQ_PARAM="$3"

  curl ${OUTPUT_VERBOSE:--#} -X POST "$SLACK_URL" --data "$PAYLOAD" --compressed | jq "$JQ_PARAM"
}

do_list_channels() {
  local PAYLOAD="token=${SLACK_TOKEN}&exclude_archived=1"
  _slack_rpc "channels.list" "$PAYLOAD" '.channels[] | {name: .name, id: .id}'
}

do_channel_info() {

  # TODO check number of params

  local CHANNEL="${PARAMS[0]}"

  if [ -z "$CHANNEL" ]; then
    do_usage_mini
    log_error "ERROR: The Slack channel id must be supplied as a parameter."
    exit 2
  fi

  local PAYLOAD="token=${SLACK_TOKEN}&channel=$CHANNEL"
  _slack_rpc "channels.info" "$PAYLOAD"
}

do_team_info() {
  local PAYLOAD="token=${SLACK_TOKEN}"
  _slack_rpc "team.info" "$PAYLOAD"
}

do_invite_email() {

  # TODO check number of params

  local EMAIL="${PARAMS[0]}"
  local CHANNELS="${PARAMS[1]}"

  if [ -z "$EMAIL" ]; then
    do_usage_mini
    log_error "ERROR: An email address must be supplied as the first parameter."
    exit 2
  fi

  local PAYLOAD="token=${SLACK_TOKEN}&email=$EMAIL&channels=$CHANNELS"
  _slack_rpc "users.admin.invite" "$PAYLOAD"
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

if [ ! `command -v jq` ]; then
  log_error "ERROR: The 'jq' command was not found."
  exit 1
fi

if [ -z "$SLACK_DOMAIN" ]; then
  do_usage

  log_error "ERROR: Please set the Slack domain parameter."
  exit 1
fi

if [ -z "$SLACK_TOKEN" ]; then
  do_usage

  log_error "ERROR: Please set the Slack token parameter."
  exit 1
fi

if [ ! `command -v curl` ]; then
  log_error "ERROR: The 'curl' command was not found."
  exit 1
fi

# ------------------------------------------------------------------------
# 

case "$CMD" in
  channels)
    do_list_channels
    ;;
  channel-info)
    do_channel_info
    ;;
  invite)
    do_invite_email
    ;;
  team-info)
    do_team_info
    ;;
  *)
    do_usage
    ;;
esac

exit 0
