# Use nginx ingress controller and cert-manager
How to use nginx and cert-manager to get real tls certificate from let's encrypt

Make sure that you have already setup gcloud and kubectl and have logged into k8s
verify that you can run the following command against your k8s cluster

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

### 2. Create the cluster role binding

```
    kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin \
    --user $(gcloud config get-value account)
```

### 3. Deploy nginx ingress controller

```
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml
```

### 4. Installing cert-manager

```
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml && \
    kubectl -n cert-manager wait --for condition=available --timeout=90s deploy -lapp=webhook
```

### 5. Setup example app and ingress using the nginx ingress controller

```
    kubectl apply -f yaml/ingress.yaml
```

### 6. Set up the certificate issuer

```
    kubectl apply -f yaml/issuer.yaml
```

### 7. Setup the DNS entry using the nginx ingress controller IP

Get the nginx ingress controller external IP address and update your dns ip address
by using your DNS provider's tool (such as login to your dns provider updating the entry)

### 8. Create a certificate

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

## Use tls certificate created to secure the app

It is very important to make sure that the following annotations are set for the ingress.

```
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: external-balancer
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-forwarded-headers: "true"
```

If not using forwarded-headers annotation, the ingress will default to use the nginx
default self signed certificate which will not be useful.

## Deploy hashivault

### 1. Make sure that there is tls certificate available

Use the cert manager to request a real certificate, and make sure that the tls certificate
is saved in the same namespace named `myddns-secret`

### 2. Stand up hashivault secured.

```
    kubectl apply -f yaml/vault.yaml
```

### 3. Delete the hasivault

```
    kubectl delete -f yaml/vault.yaml
```