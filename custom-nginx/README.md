# Use ambassador and cert-manager
How to use ambassador and cert-manager to get real tls certificate from let's encrypt

Make sure that you have already setup gcloud and kubectl and have logged into k8s
verify that you can run the following command against your k8s cluster

## Use the script 

### 1. Download the setup.sh and run the script to set things up
### 2. Create a certificate
Use yaml/certificate.yaml as an example to create your own certificate
file, then run the following command:
```
    kubectl apply -f certificate.yaml
```


## Use the step by step approach

### 1. Verify connection to your k8s cluster

```
    kubectl get nodes
```

### 2. Install nginx-ingress controller

```
    kubectl apply -f https://www.getambassador.io/yaml/aes-crds.yaml && \
    kubectl wait --for condition=established --timeout=90s crd -lproduct=aes && \
    kubectl apply -f https://www.getambassador.io/yaml/aes.yaml && \
    kubectl -n ambassador wait --for condition=available --timeout=90s deploy -lproduct=aes
```
    At this point, you should be able to get an external IP address from ambassador
```
    kubectl get -n ambassador service ambassador -o \
    "go-template={{range .status.loadBalancer.ingress}}{{or .ip .hostname}}{{end}}"
```

### 3. Install cert-manager

```
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml 
```

### 4. Setup resolver mapping and ingress

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

### 5. Create an issuer (or clusterissuer)

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

### 6. Create a certificate

Create certificate.yaml file with the following content
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