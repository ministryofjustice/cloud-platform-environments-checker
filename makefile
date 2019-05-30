IMAGE := orphaned-namespace-checker
VERSION := 2.2

# This is the 'empty' main.tf file that we add, by default, to any namespaces users create
CANONICAL_MAIN_TF_URL = 'https://raw.githubusercontent.com/ministryofjustice/cloud-platform-environments/master/namespace-resources/resources-main-tf'

build:
	curl $(CANONICAL_MAIN_TF_URL) > main.tf
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) ministryofjustice/$(IMAGE):$(VERSION)
	docker push ministryofjustice/$(IMAGE):$(VERSION)

list-orphaned-namespaces:
	docker run \
	 -e PIPELINE_CLUSTER=$${PIPELINE_CLUSTER} \
	 -e TFSTATE_AWS_REGION=$${TFSTATE_AWS_REGION} \
	 -e TFSTATE_AWS_ACCESS_KEY_ID=$${TFSTATE_AWS_ACCESS_KEY_ID} \
	 -e TFSTATE_AWS_SECRET_ACCESS_KEY=$${TFSTATE_AWS_SECRET_ACCESS_KEY} \
	 -e BUCKET_PREFIX=$${BUCKET_PREFIX} \
	 -e PIPELINE_STATE_BUCKET=$${PIPELINE_STATE_BUCKET} \
	 -e KUBE_CONFIG=$${KUBE_CONFIG} \
	 -e KUBECONFIG_S3_BUCKET=$${KUBECONFIG_S3_BUCKET} \
	 -e KUBECONFIG_S3_KEY=$${KUBECONFIG_S3_KEY} \
	 -e KUBE_CTX=$${KUBE_CTX} \
	 -e KUBECONFIG_AWS_REGION=$${KUBECONFIG_AWS_REGION} \
	 -e KUBECONFIG_AWS_ACCESS_KEY_ID=$${KUBECONFIG_AWS_ACCESS_KEY_ID} \
	 -e KUBECONFIG_AWS_SECRET_ACCESS_KEY=$${KUBECONFIG_AWS_SECRET_ACCESS_KEY} \
		orphaned-namespace-checker sh -c 'mkdir output; /app/bin/orphaned_namespaces.rb; cat output/check.txt'

# USAGE: NAMESPACE=foo make delete-aws-resources
delete-aws-resources:
	docker run \
	 -e TERRAFORM_PATH=/app/bin \
	 -e TFSTATE_AWS_ACCESS_KEY_ID=$${TFSTATE_AWS_ACCESS_KEY_ID} \
	 -e TFSTATE_AWS_SECRET_ACCESS_KEY=$${TFSTATE_AWS_SECRET_ACCESS_KEY} \
	 -e TFSTATE_AWS_REGION=$${TFSTATE_AWS_REGION} \
	 -e PIPELINE_STATE_BUCKET=$${PIPELINE_STATE_BUCKET} \
	 -e PIPELINE_CLUSTER=$${PIPELINE_CLUSTER} \
	 -e KUBE_CONFIG=$${KUBE_CONFIG} \
	 -e KUBECONFIG_S3_BUCKET=$${KUBECONFIG_S3_BUCKET} \
	 -e KUBECONFIG_S3_KEY=$${KUBECONFIG_S3_KEY} \
	 -e KUBE_CTX=$${KUBE_CTX} \
	 -e KUBECONFIG_AWS_REGION=$${KUBECONFIG_AWS_REGION} \
	 -e KUBECONFIG_AWS_ACCESS_KEY_ID=$${KUBECONFIG_AWS_ACCESS_KEY_ID} \
	 -e KUBECONFIG_AWS_SECRET_ACCESS_KEY=$${KUBECONFIG_AWS_SECRET_ACCESS_KEY} \
		orphaned-namespace-checker sh -c "mkdir output; /app/bin/delete-aws-resources.rb $${NAMESPACE}"
