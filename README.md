# AWS Lambda: Slack Inviter

An Amazon Lambda (serverless) Slack Team invitation service.

## Quick start

First, clone this repository!

Then:

1. Get an [Amazon Web Services account](http://console.aws.amazon.com/)
2. Get a Slack team account & [an authentication token](https://api.slack.com/docs/oauth-test-tokens)
3. The ['jq' command line tool](https://stedolan.github.io/jq/)
4. The ['aws-cli' command line tool](https://aws.amazon.com/cli/)
5. run `utils.sh -d <slack-team> -t <slack-test-token> channels`
6. run `./deploy.sh  -d <slack-team> -t <slack-test-token> create`


## Not so fast!

### Create an AWS Web Services account

You must have an AWS account.

### Install 'aws-cli' & 'jq'

The `aws-cli` and `jq` tools are used by the `deploy.sh` script.

Install the ['aws-cli' command line tool](https://aws.amazon.com/cli/).
Install 'jq' for the [appropriate operating system](https://stedolan.github.io/jq/download/).

### Create a Slack Token

1. In a web browser, go to [api.slack.com/docs/oauth-test-tokens](https://api.slack.com/docs/oauth-test-tokens).
2. Scroll to the bottom of the page.
3. Find the team and username for which you'd like to create a token, and click the 'Create token' button.

### Find the channel ids

The provided `utils.sh` script has a `channels` command.

    ./utils.sh -d <slack-team-subdomain> -t <slack-test-token> channels

You will see some output, like:

    ######################################################################## 100.0%
    {
      "name": "general",
      "id": "C0AA00AAA"
    }
    {
      "name": "random",
      "id": "C0AA00AAA"
    }

You can test that the Slack token and the channel ids are working correctly, by running the `utils` script, and inviting a user by their email address to your team. The channel ids can be passed as well, if you have a paid team and wish to customise the list of channels beyond the default set in Slack.

For free teams:

    ./utils.sh -d <slack-team-subdomain> -t <slack-test-token> invite <you@yourdomain.com>

For paid teams:

    ./utils.sh -d <slack-team-subdomain> -t <slack-test-token> invite <you@yourdomain.com> C0AA00AAA,C0AA00AAA

### Deploy the application to AWS Lambda

    ./deploy.sh -d <slack-team-subdomain> -t <slack-test-token> -o http://www.myhost.com/ create

or, if you prefer to set the Slack values as environment variables:

    export SLACK_DOMAIN=<slack-team-subdomain>
    export SLACK_TOKEN=<slack-test-token>
    ./deploy.sh create

When `create` has completed, the output will give an AWS ARN for the CloudFormation Stack and the URL for the API Gateway HTTP. It will look something like this (NB these are not 'real' values):

    {
      "id": "arn:aws:cloudformation:us-west-2:111111111111:stack/slackinviter/1a1a1a1a-1a1a-1a1a-1a1a-1a1a1a1a1a1a",
      "url": "https://1a1a1a1a1a.execute-api.us-west-2.amazonaws.com/prod/invite"
    }

The `url` value is used in the next section.

### Deploy the web UI

If you have cloned this repository in GitHub, you can publish the `docs` directory as a GitHub docs site.

You must edit the [index.html](./docs/index.html) file.
You must set the `LAMDBA_URL` parameter.
You may set the `SLACK_CHANNEL_IDS` if you want to customise the channels the user will be added to when they register.


    <script type="text/javascript">
    // ------------------------------------------------
    // THESE VALUES MUST BE CUSTOMISED
    var AWS_LAMDBA_URL = "http://..."
    var SLACK_CHANNEL_IDS = ""
    //
    // ------------------------------------------------
    </script>

