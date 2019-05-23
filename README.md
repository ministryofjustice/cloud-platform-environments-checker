# Environments Checker

Ruby code to compare the namespaces which exist in the cluster to those which are defined in the [env-repo].

Namespaces which exist in the cluster, but which are not defined in the repo should be deleted, along with all of their AWS resources.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
