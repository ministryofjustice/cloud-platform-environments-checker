# Environments Checker

Ruby code to compare the namespaces which exist in the cluster to those which are defined in the [env-repo].

Namespaces which exist in the cluster, but which are not defined in the repo should be deleted, along with all of their AWS resources.

This script outputs a report, detailing the namespaces which are not defined in the [env-repo], and any associated AWS resources which are defined in the terraform state.

See the `makefile` for an example of how to run this script.

## Concourse Pipeline

This script is executed regularly via Concourse, as defined [here][concourse-job], with the output piped into Slack.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[concourse-job]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/master/pipelines/live-1/main/check-environment.yaml

