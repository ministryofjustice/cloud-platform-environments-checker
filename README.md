# Environments Checker

Ruby code to compare the namespaces which exist in the cluster to those which are defined in the [env-repo].

Namespaces which exist in the cluster, but which are not defined in the repo should be deleted, along with all of their AWS resources.

## bin/orphaned_namespaces.rb

This script outputs a report, detailing the namespaces which are not defined in the [env-repo], and any associated AWS resources which are defined in the terraform state.

See the `makefile` for an example of how to run this script.

This script is executed regularly via Concourse, as defined [here][concourse-job], with the output piped into Slack.

## bin/delete-aws-resources.rb

This script expects the same environment variables as the `orphaned_namespaces` script, plus a namespace name. Given that, and only if the corresponding namespace is not defined in the [env-repo], the script will do a `terraform init` against that namespace, using our default, empty `main.tf` file. It will then do a `terraform plan` which should list all the AWS resources that will be deleted if `terraform apply` is executed.

Currently, this script is not being executed by the concourse pipeline, so must be run manually, if desired.

See the `makefile` for an example of how to run this script.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[concourse-job]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/master/pipelines/live-1/main/check-environment.yaml

