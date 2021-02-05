#!/bin/bash
# Make sure that you have already setup gcloud and kubectl and have logged into k8s
# verify that you can run the following command against your k8s cluster

action=$1
if [[ $action == 'delete' ]]; then


else
    echo "Installing ambassador..."
    kubectl apply -f https://www.getambassador.io/yaml/aes-crds.yaml && \
    kubectl wait --for condition=established --timeout=90s crd -lproduct=aes && \
    kubectl apply -f https://www.getambassador.io/yaml/aes.yaml && \
    kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes
    EXTERNALIP=$(kubectl get -n ambassador service ambassador -o \
    "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}")

    echo "The external IP address: "$EXTERNALIP
    echo ""
    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

    echo ""
    echo "Set up mapping and ingress service for acme challenges"
    kubectl apply -f 
fi
## 3. Install cert-manager

```
    
```

## 4. Setup resolver mapping and ingress

Create mappingingress.yaml with the following content:

```
---
apiVersion: getambassador.io/v2
kind: Mapping
metadata:
  name: acme-challenge-mapping
spec:
  prefix: /.well-known/acme-challenge/
  rewrite: ""
  service: acme-challenge-service
---
apiVersion: v1
kind: Service
metadata:
  name: acme-challenge-service
spec:
  ports:
  - port: 80
    targetPort: 8089
  selector:
    acme.cert-manager.io/http01-solver: "true"

```
Now run the following command

```
    kubectl apply -f mappingingress.yaml
```

## 5. Create an issuer (or clusterissuer)

Create issuer.yaml file with the following content
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    preferredChain: "ISRG Root X1"
    privateKeySecretRef:
      name: letencrypt-secret
    solvers:
    - http01:
        ingress:
          class: nginx
      selector: {}
```
Run the following command to create the Cluster Issuer

```
    kubectl apply -f issuer.yaml
```

## 6. Create a certificate

Create certrequest.yaml file with the following content
```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bibletls
  namespace: default
spec:
  dnsNames:
    - bible.hopto.org
  secretName: bibletls-secret
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt
```
Run the following command to create the certificate issued by Letsencrypt

```
    kubectl apply -f certrequest.yaml
```