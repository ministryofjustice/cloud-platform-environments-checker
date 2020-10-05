pull:
	docker pull $(IMAGE):$(VERSION)

test:
	bundle exec rspec

# USAGE:
# Set your environment variables (see example.env.live-0 & example.env.live-1), then:
#
#     make list-orphaned-namespaces
#
list-orphaned-namespaces:
	docker run \
	 -e KUBERNETES_CLUSTER=$${KUBERNETES_CLUSTER} \
	 -e TFSTATE_AWS_REGION=$${TFSTATE_AWS_REGION} \
	 -e TFSTATE_AWS_ACCESS_KEY_ID=$${TFSTATE_AWS_ACCESS_KEY_ID} \
	 -e TFSTATE_AWS_SECRET_ACCESS_KEY=$${TFSTATE_AWS_SECRET_ACCESS_KEY} \
	 -e TFSTATE_BUCKET_PREFIX=$${TFSTATE_BUCKET_PREFIX} \
	 -e TFSTATE_BUCKET=$${TFSTATE_BUCKET} \
	 -e KUBERNETES_STATE_BUCKET=$${KUBERNETES_STATE_BUCKET} \
	 -e KUBE_CONFIG=$${KUBE_CONFIG} \
	 -e KUBECONFIG_S3_BUCKET=$${KUBECONFIG_S3_BUCKET} \
	 -e KUBECONFIG_S3_KEY=$${KUBECONFIG_S3_KEY} \
	 -e KUBE_CTX=$${KUBE_CTX} \
	 -e KUBECONFIG_AWS_REGION=$${KUBECONFIG_AWS_REGION} \
	 -e KUBECONFIG_AWS_ACCESS_KEY_ID=$${KUBECONFIG_AWS_ACCESS_KEY_ID} \
	 -e KUBECONFIG_AWS_SECRET_ACCESS_KEY=$${KUBECONFIG_AWS_SECRET_ACCESS_KEY} \
	 -e PIPELINE_TERRAFORM_STATE_LOCK_TABLE=cloud-platform-environments-terraform-lock \
	 -e GITHUB_TOKEN=$${GITHUB_TOKEN} \
	 $(IMAGE):$(VERSION) sh -c 'mkdir output; /app/bin/orphaned_namespaces.rb; cat output/check.txt'

hosted-services:
	docker run \
	 -e KUBERNETES_CLUSTER=$${KUBERNETES_CLUSTER} \
	 -e KUBECONFIG=$${KUBE_CONFIG} \
	 -e KUBECONFIG_S3_BUCKET=$${KUBECONFIG_S3_BUCKET} \
	 -e KUBECONFIG_S3_KEY=$${KUBECONFIG_S3_KEY} \
	 -e KUBE_CTX=$${KUBE_CTX} \
	 -e KUBECONFIG_AWS_REGION=$${KUBECONFIG_AWS_REGION} \
	 -e KUBECONFIG_AWS_ACCESS_KEY_ID=$${KUBECONFIG_AWS_ACCESS_KEY_ID} \
	 -e KUBECONFIG_AWS_SECRET_ACCESS_KEY=$${KUBECONFIG_AWS_SECRET_ACCESS_KEY} \
	 -e HOODAW_API_KEY=$${HOODAW_API_KEY} \
 	 -e HOODAW_HOST=$${HOODAW_HOST}\
	 $(IMAGE):$(VERSION) sh -c 'mkdir output; /app/bin/hosted_services.rb > output/check.txt; cat output/check.txt'

shell: .built-image
		docker run --rm -it $(IMAGE) sh
