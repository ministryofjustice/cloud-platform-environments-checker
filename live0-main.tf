# This is the empty main.tf file we will use when deleting
# resources from an orphaned namespace on the live-0 cluster.
# The 'region' for the 'aws' provider is 'eu-west-1' for live0
# resources

terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"
}
