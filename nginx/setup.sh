#!/bin/bash
# Make sure that you have already setup gcloud and kubectl and have logged into k8s
# verify that you can run the following command against your k8s cluster

action=$1
if [[ $action == 'delete' ]]; then

    echo "Removing the certificate issuer..."
    # kubectl delete -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/issuer.yaml
    kubectl delete -f yaml/issuer.yaml

    echo "Removing cert-manager..."
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

else
    echo "Deploy verification app..."
    kubectl apply -f yaml/hello-world.yaml && \
    kubectl wait --for condition=available --timeout=90s deployment hello-world-deployment

    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml && \
    kubectl -n cert-manager wait --for condition=available --timeout=90s deploy -lapp=webhook

    echo ""
    echo "Set up ingress..."
    # kubectl apply -f yaml/ingress.yaml
    kubectl apply -f yaml/mappingingress.yaml
    sleep 10
    echo "Set up the certificate issuer..."
    # kubectl apply -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/issuer.yaml
    kubectl apply -f yaml/issuer.yaml

    echo "You are now ready to request a certificate"
fi
