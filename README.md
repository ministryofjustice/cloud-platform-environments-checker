# Environments Checker

Ruby code to compare the namespaces which exist in the cluster to those which are defined in the [env-repo].

Namespaces which exist in the cluster, but which are not defined in the repo should be deleted, along with all of their AWS resources.

## S3 bucket locations

These scripts need to fetch some resources from S3:

 * A valid Kubernetes config file, for the targeted cluster
 * The terraform state files for cluster namespaces

These are stored in different AWS accounts and regions, depending on the cluster. Hence, multiple sets of AWS credentials must be supplied (as environment variables).

## Environment variables

These scripts require many environment variables to be set. See `example.env.live-0` and `example.env.live-1` for a list.

You can copy these examples to, e.g. `.env.live1` and `.env.live0` (which will be `git ignore`d) and supply valid AWS credentials, in order to run these scripts locally (either directly, or via the docker image).

## bin/orphaned_namespaces.rb

This script outputs a report, detailing the namespaces which are not defined in the [env-repo], and any associated AWS resources which are defined in the terraform state.

See the `makefile` for an example of how to run this script.

This script is executed regularly via Concourse, as defined [here][concourse-job], with the output piped into Slack.

## bin/delete-aws-resources.rb

This script expects the same environment variables as the `orphaned_namespaces` script, plus a namespace name. Given that, and only if the corresponding namespace is not defined in the [env-repo], the script will do a `terraform init` against that namespace, using our default, empty `main.tf` file.

If invoked in 'reporting' mode (the default), it will then do a `terraform plan` which should list all the AWS resources that would be deleted if `terraform apply` is executed.

To invoke the script in 'destroy' mode, **WHICH WILL DESTROY ALL AWS RESOURCES AND THEN THE NAMESPACE ITSELF, WITH NO CONFIRMATION**, add the word 'destroy' as a second parameter, after the namespace name.

Currently, this script is not being executed by the concourse pipeline, so must be run manually, if desired.

See the `makefile` for an example of how to run this script.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[concourse-job]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/master/pipelines/live-1/main/check-environment.yaml

