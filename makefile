IMAGE := ministryofjustice/orphaned-namespace-checker
VERSION := 2.8

build:
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) ministryofjustice/$(IMAGE):$(VERSION)
	docker push $(IMAGE):$(VERSION)

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
	 $(IMAGE):$(VERSION) sh -c 'mkdir output; /app/bin/orphaned_namespaces.rb; cat output/check.txt'

# USAGE:
# Set your environment variables (see example.env.live-0 & example.env.live-1), then:
#
# This will just do a 'terraform plan' to show you what would be destroyed
#
#     NAMESPACE=foo make delete-namespace
#
# To ACTUALLY DELETE AWS RESOURCES with no confirmation step, do this:
#
#     NAMESPACE=foo DESTROY=destroy make delete-namespace
#
delete-namespace:
	docker run \
	 -e TERRAFORM_PATH=/app/bin \
	 -e TFSTATE_AWS_ACCESS_KEY_ID=$${TFSTATE_AWS_ACCESS_KEY_ID} \
	 -e TFSTATE_AWS_SECRET_ACCESS_KEY=$${TFSTATE_AWS_SECRET_ACCESS_KEY} \
	 -e TFSTATE_AWS_REGION=$${TFSTATE_AWS_REGION} \
	 -e TFSTATE_BUCKET=$${TFSTATE_BUCKET} \
	 -e KUBERNETES_CLUSTER=$${KUBERNETES_CLUSTER} \
	 -e KUBE_CONFIG=$${KUBE_CONFIG} \
	 -e KUBECONFIG_S3_BUCKET=$${KUBECONFIG_S3_BUCKET} \
	 -e KUBECONFIG_S3_KEY=$${KUBECONFIG_S3_KEY} \
	 -e KUBE_CTX=$${KUBE_CTX} \
	 -e KUBECONFIG_AWS_REGION=$${KUBECONFIG_AWS_REGION} \
	 -e KUBECONFIG_AWS_ACCESS_KEY_ID=$${KUBECONFIG_AWS_ACCESS_KEY_ID} \
	 -e KUBECONFIG_AWS_SECRET_ACCESS_KEY=$${KUBECONFIG_AWS_SECRET_ACCESS_KEY} \
	 $(IMAGE):$(VERSION) sh -c "mkdir output; /app/bin/delete-namespace.rb $${NAMESPACE} $${DESTROY}"

##
## Usage examples for local development:
##
namespaces:
	rm -rf output /tmp/kubeconfig
	mkdir output
	. .env.live0; ./bin/orphaned_namespaces.rb
	cat output/check.txt

plan:
	. .env.live0; \
	export TERRAFORM_PATH=$$(dirname $$(which terraform)); \
	./bin/delete-namespace.rb money-to-prisoners-prod

destroy:
	. .env.live0; \
	export TERRAFORM_PATH=$$(dirname $$(which terraform)); \
	./bin/delete-namespace.rb money-to-prisoners-prod destroy

shell:
	docker run --rm -it $(IMAGE) sh
