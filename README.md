# AWS Lambda: Slack Inviter

A Amazon Lambda (serverless) Slack Team invitation service.

## Quick start

In ...

1. An Amazon Web Services account
2. A Slack team account & token
3. The 'jq' command line tool
4. run `utils.sh -d <slack-team> -t <token> channels`
5. run `./deploy.sh`

First, clone this repository!

### Create an AWS Web Services account

?

### Create a Slack Token

1. In a web browser, go to [api.slack.com/docs/oauth-test-tokens](https://api.slack.com/docs/oauth-test-tokens).
2. Scroll to the bottom of the page.
3. Find the team and username for which you'd like to create a token, and click the Create token button.

### Install 'jq'

?

### Find the channel id

The provided `utils.sh` script has a `channels` command.

    utils.sh -d <slack-team> -t <token> channels
