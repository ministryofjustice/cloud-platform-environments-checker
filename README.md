# Environments Checker

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-environments-checker/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-environments-checker/releases)

Ruby code to 
1. List 'orphaned' namespaces

   Script to compare the namespaces which exist in the cluster to those which are defined in the [env-repo]. Namespaces which exist in the cluster, but which are  not defined in the repo should be deleted, along with all of their AWS resources.

1. List 'hosted services' 

   Script to list the namespaces and its ingresses of services that are hosted by Cloud Platform. 

Both the projects are executed regularly by a [concourse-job], to generate a report. To run manually, follow the steps in Installation and Usage.

## Installation

You need to have docker installed on your computer.

* Check out a copy of this repository
* Copy `example.env.live1` to `.env.live1`
* Replace the placeholders in the `.env.live1` files with valid AWS credentials, GITHUB_TOKEN (with `public_repo` scope, for orphaned-resources) and HOODAW_API_KEY(for listing hosted services)
* `make pull`

## Usage

### Listing 'orphaned' namespaces

To list namespaces which exist in the cluster, but which are not defined in the [env-repo]

    . .env.live1; make list-orphaned-namespaces

### Listing 'hosted services' of the cluster

To list namespaces and ingresses of services which exist in the cluster

    . .env.live1; make hosted-services

### Invoking the scripts locally

If you have set up your local ruby development environment, you can invoke the ruby scripts locally. See the makefile for examples of how to do this.

## Development

If you want to develop the code, you will also need to install ruby 2.6.2, and run `bundle install` to install gems.

After changing the code, create a new [release] using the github web interface.
This will trigger a github action to build the docker image with tag `ministryofjustice/orphaned-namespace-checker:<release-tag>`and push it to docker hub.

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

These scripts require many environment variables to be set. See `example.env.live-1` for a list.

You can copy these examples to, e.g. `.env.live1` (which will be `git ignore`d) and supply valid AWS credentials, GITHUB_TOKEN(for orphaned_namespaces) and HOODAW_API_KEY(for hosted_services), in order to run these scripts locally (either directly, or via the docker image).

### bin/orphaned_namespaces.rb

This script outputs a report, detailing the namespaces which are not defined in the [env-repo], and any associated AWS resources which are defined in the terraform state.

This script is executed regularly via Concourse, as defined [here][concourse-job], with the output piped into Slack.

### bin/hosted_services.rb

This script outputs a report with the list of namespaces, namespace annotations and corresponding ingresses which exists in the cluster.

This script is executed regularly via Concourse, as defined [here][concourse-job-orphaned-namespace], with the output piped into Slack.

### bin/post-data-to-hoodaw.sh
This script runs and pushes the output of `bin/hosted_services.rb` to the [HOODAW] page. This is executed regulary via Concourse, as defined [here][concourse-job-hosted-services]

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[HOODAW]: https://how-out-of-date-are-we.apps.live-1.cloud-platform.service.justice.gov.uk/hosted_services
[concourse-job]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/main/pipelines/manager/main/reporting.yaml
[concourse-job-orphaned-namespace]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/main/pipelines/manager/main/reporting.yaml#L69
[concourse-job-hosted-services]: https://github.com/ministryofjustice/cloud-platform-concourse/blob/main/pipelines/manager/main/reporting.yaml#L384
[release]: https://github.com/ministryofjustice/cloud-platform-environments-checker/releases
