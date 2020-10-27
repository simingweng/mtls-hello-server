# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Build docker image for the hello world server
.PHONY: build
build: fmt vet
	docker build . -f build/package/Dockerfile -t docker.pkg.github.com/simingweng/mtls-hello-server/mtls-hello-server

# Launch a local kind kubernetes cluster properly configured for ngnix ingress controller
create-cluster:
	kind create cluster --config test/kind/cluster.yaml

# Install the ngnix ingress controller
install-ingress-ngnix:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
	until [[ `kubectl -n ingress-nginx wait pod -l app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx --for=condition=Ready` ]]; do sleep 5; done

# Install cert-manager
install-cert-manager:
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.3/cert-manager.crds.yaml
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.0.3 \
      --create-namespace \
      --wait

# launch the load infra with dependencies installed
up: create-cluster install-ingress-ngnix install-cert-manager

# Deploy the hello server as well as its dependencies
deploy: build
	kind load docker-image docker.pkg.github.com/simingweng/mtls-hello-server/mtls-hello-server:latest
	kubectl apply -f deploy/manifests

# Delete the local kind cluster
down:
	kind delete cluster