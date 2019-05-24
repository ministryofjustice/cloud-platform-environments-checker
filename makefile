IMAGE := orphaned-namespace-checker
VERSION := 1.2

build:
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) ministryofjustice/$(IMAGE):$(VERSION)
	docker push ministryofjustice/$(IMAGE):$(VERSION)

# This expects to find a kube config file in ./kubecfg/config
run:
	docker run \
		-v $$(pwd)/kubecfg:/app/.kube \
		-e KUBECONFIG=/app/.kube/config \
		-e AWS_REGION=$${AWS_REGION} \
		-e AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID} \
		-e AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY} \
		-e PIPELINE_CLUSTER=$${PIPELINE_CLUSTER} \
		-e PIPELINE_STATE_BUCKET=$${PIPELINE_STATE_BUCKET} \
		orphaned-namespace-checker
