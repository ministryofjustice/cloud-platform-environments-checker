# Environments Checker

Ruby code to compare the namespaces which exist in the cluster to those which are defined in the [env-repo].

Namespaces which exist in the cluster, but which are not defined in the repo should be deleted, along with all of their AWS resources.

This project is executed regularly by a [concourse-job], to generate a report. To run manually, follow the steps in Installation and Usage.

## Installation

You need to have docker installed on your computer.

* Check out a copy of this repository
* Copy `example.env.live1` to `.env.live1`
* Copy `example.env.live0` to `.env.live0`
* Replace the placeholders in the `.env.*` files with valid AWS credentials and GITHUB_TOKEN (with `public_repo` scope)
* `make pull`

## Usage

### Listing 'orphaned' namespaces

To list namespaces which exist in the cluster, but which are not defined in the [env-repo]

    . .env.live1; make list-orphaned-namespaces

### Invoking the scripts locally

If you have set up your local ruby development environment, you can invoke the ruby scripts locally. See the makefile for examples of how to do this.

## Development

If you want to develop the code, you will also need to install ruby 2.6.2, and run `bundle install` to install gems.

After changing the code, bump the version tag in the `makefile`, and then run `make build` to create the Docker image, and `make push` to tag it and push to docker hub.

You will then need to update the image tag in the [concourse-job], and make any other required changes there.

### Tests

Run `make test` to execute the tests.

## Background

The following is some detail on how the scripts work, and the resources they require.

### S3 bucket locations

These scripts need to fetch some resources from S3:

 * A valid Kubernetes config file, for the targeted cluster
 * The terraform state files for cluster namespaces

These are stored in different AWS accounts and regions, depending on the cluster. Hence, multiple sets of AWS credentials must be supplied (as environment variables).

### Environment variables

These scripts require many environment variables to be set. See `example.env.live-0` and `example.env.live-1` for a list.

You can copy these examples to, e.g. `.env.live1` and `.env.live0` (which will be `git ignore`d) and supply valid AWS credentials and GITHUB_TOKEN, in order to run these scripts locally (either directly, or via the docker image).

### bin/orphaned_namespaces.rb

This script outputs a report, detailing the namespaces which are not defined in the [env-repo], and any associated AWS resources which are defined in the terraform state.

This script is executed regularly via Concourse, as defined [here][concourse-job], with the output piped into Slack.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[concourse-job]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/1185313ddae4d46e2f499e1cbf84c7e2e722c082/pipelines/manager/main/reporting.yaml#L69

