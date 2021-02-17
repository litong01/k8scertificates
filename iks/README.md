# Use cert-manager to get real letsencrypt certificate on IBM Kubernetes
These scripts and procedures allows a user to utilize cert-manager to
get real tls certificate from let's encrypt

Make sure that you have an IBM Kubernetes cluster ready and also make sure
that the subnet the cluster uses has public gateway set up so that the cluster
can have internet access from within. This should be done from
VPC Infrastructure -> Subnets

## Use the script 

### 1. Download the setup.sh and run the script to set things up
### 2. Create a certificate
Use yaml/certificate.yaml as an example to create your own certificate
file, then run the following command:
```
    kubectl apply -f yaml/certificate.yaml
```


## Use the step by step approach

### 1. Verify connection to your k8s cluster

```
    kubectl get nodes
```

### 2. Install the verification app and service

```
    kubectl apply -f yaml/hello-world.yaml && \
    kubectl wait --for condition=available --timeout=90s deployment hello-world-deployment
```

### 3. Install cert-manager

```
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml && \
    kubectl -n cert-manager wait --for condition=available --timeout=90s deploy -lapp=webhook
```

### 4. Install the ingress which exposes the cluster to the internet

```
    kubectl apply -f yaml/ingress.yaml
```

### 5. Install the certificate issuer

```
    kubectl apply -f yaml/issuer.yaml
```

### 6. Setup the DNS entry using the ingress external IP

Get the ingress external IP address or use the cluster generated hostname to lookup
the IP address, then update your dns ip address by using your DNS provider's tool
(such as login to your dns provider updating the entry)

### 7. Create a certificate

Create certificate.yaml file with the following content

```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myddnstls
  namespace: default
  annotations:
    http01.acme.certmanager.k8s.io/ingress-to-edit: "external-balancer"
spec:
  dnsNames:
    - tongli.myddns.me
  secretName: myddns-secret
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt
```
Run the following command to create the certificate issued by Letsencrypt

```
    kubectl apply -f certrequest.yaml
```

### How to get secret from k8s

Use the following command to save the secret (certificate) to files

```
    kubectl get secrets myddns-secret --template="{{index .data \"tls.crt\" | base64decode}}" > tls.crt
    kubectl get secrets myddns-secret --template="{{index .data \"tls.key\" | base64decode}}" > tls.key

```