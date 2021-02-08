#!/bin/bash
# Make sure that you have already setup gcloud and kubectl and have logged into k8s
# verify that you can run the following command against your k8s cluster

action=$1
if [[ $action == 'delete' ]]; then
    echo "Removing mapping and ingress service for acme challenges..."
    # kubectl delete -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/mappingingress.yaml
    kubectl delete -f yaml/mappingingress.yaml
    echo "Removing the certificate issuer..."
    # kubectl delete -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/issuer.yaml
    kubectl delete -f yaml/issuer.yaml

    echo "Removing cert-manager..."
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

    echo "Removing Nginx-ingress controller..."
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml

    echo "Nginx-ingress controll and Cert-Manager are now removed."
else
    echo "Initialize your user as a cluster-admin..."
    kubectl create clusterrolebinding cluster-admin-binding \
      --clusterrole cluster-admin \
      --user $(gcloud config get-value account)

    echo "Installing nginx-ingress controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml && \
    kubectl -n ingress-nginx wait --for condition=available --timeout=90s deploy ingress-nginx-controller
    EXTERNALIP=$(kubectl get -n ingress-nginx service ingress-nginx-controller -o \
    "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")

    echo "The external IP address: "$EXTERNALIP
    echo ""
    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml && \
    kubectl -n cert-manager wait --for condition=available --timeout=90s deploy -lapp=webhook

    echo ""
    echo "Set up mapping and ingress service for acme challenges..."
    # kubectl apply -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/mappingingress.yaml
    kubectl apply -f yaml/mappingingress.yaml
    sleep 10
    echo "Set up the certificate issuer..."
    # kubectl apply -f https://raw.githubusercontent.com/litong01/k8scertificates/main/yaml/issuer.yaml
    kubectl apply -f yaml/issuer.yaml

    echo "You are now ready to request a certificate"
fi
