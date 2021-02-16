#!/bin/bash
# Make sure that you have already setup gcloud and kubectl and have logged into k8s
# verify that you can run the following command against your k8s cluster

action=$1
if [[ $action == 'delete' ]]; then
    echo "Delete verification app and issuer..."
    kubectl delete -f yaml/issuer.yaml

    echo "Delete the ingress..."
    kubectl delete -f yaml/ingress.yaml

    echo "Removing cert-manager..."
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

    echo "Removing the nginx ingress controller"
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml

else
    echo "Set up binding role..."
    kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)

    echo "Deploy nginx ingress controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml

    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml && \
    kubectl -n cert-manager wait --for condition=available --timeout=90s deploy -lapp=webhook

    echo ""
    echo "Set up ingress..."
    kubectl apply -f yaml/ingress.yaml
    sleep 10
    echo "Set up the certificate issuer..."
    kubectl apply -f yaml/issuer.yaml

    echo "You are now ready to request a certificate"
fi
