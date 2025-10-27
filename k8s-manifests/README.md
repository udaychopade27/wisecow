# 🐮 Wisecow App – Kubernetes Deployment with Self-Signed TLS

This guide explains how to deploy the Wisecow App on a Minikube Kubernetes cluster and enable HTTPS access using a self-signed TLS certificate.

## 🧱 Prerequisites

Make sure you have the following installed:
🐳 Docker
☸️ Minikube
⚙️ kubectl
🧾 OpenSSL

## 🚀 Step 1: Start Minikube and Enable Ingress
### Start minikube
minikube start --driver=docker

### Enable ingress controller
minikube addons enable ingress
Verify:
```bash
kubectl get pods -n kube-system | grep ingress
```
You should see something like ingress-nginx-controller running.

## 🧾 Step 2: Create Kubernetes Deployment and Service

Apply your existing manifests:
```bash
kubectl apply -f deploy.yml
kubectl apply -f service.yml
```

Verify:
```bash
kubectl get pods
kubectl get svc
```

## 🔐 Step 3: Generate a Self-Signed TLS Certificate

Create the certificate and private key:
```bash
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=wisecow.local/O=wisecow"
```

This command generates:
```text .
tls.crt → Certificate file
tls.key → Private key
```

## 🗝️ Step 4: Create a Kubernetes TLS Secret

Create the secret inside your cluster:
```bash
kubectl create secret tls wisecow-tls \
  --cert=tls.crt \
  --key=tls.key
```

Verify:
```bash
kubectl get secrets
```
You should see:

NAME           TYPE                DATA   AGE
wisecow-tls    kubernetes.io/tls   2      1m

## 🌐 Step 5: Configure Ingress for HTTPS Access

Use this ingress.yml:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wisecow-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
      - wisecow.local
    secretName: wisecow-tls
  rules:
  - host: wisecow.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wisecow-app-service
            port:
              number: 4499
```

Apply it:
```bash
kubectl apply -f ingress.yml
```

Check status:
```bash
kubectl get ingress
```

## 🏠 Step 6: Map Domain to Minikube IP

Get your Minikube IP:
```bash
minikube ip
```

Then edit /etc/hosts on your system and add:
```bash
<MINIKUBE_IP> wisecow.example.com
```

Example:

192.168.49.2 wisecow.local

## 🧠 Step 7: Verify HTTPS Access

Test using curl:
```bash
curl -k https://wisecow.local
```

⚠️ You’ll see a certificate warning unless you add the certificate to your system trust store (next step).

## 🔏 Step 8: Add Self-Signed Certificate to Trusted Store (Optional but Recommended)
### For Linux (Ubuntu/Debian)
#### Copy cert to trust directory
```bash
sudo cp tls.crt /usr/local/share/ca-certificates/wisecow.crt
```
#### Update trusted certs
```bash
sudo update-ca-certificates
```
###  For macOS
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain tls.crt
```
### For Windows (PowerShell as Administrator)
```bash
Import-Certificate -FilePath tls.crt -CertStoreLocation Cert:\LocalMachine\Root
```
## ✅ Step 9: Test Secure Access Again

Once the certificate is trusted, test again:
```bash
curl https://wisecow.local
```

You should now get a valid response without using -k.
Or open in browser → https://wisecow.example.com

## 🧩 Step 10: Troubleshooting
| Issue                                | Fix                                                        |
| ------------------------------------ | ---------------------------------------------------------- |
| `curl: (60) SSL certificate problem` | Use `curl -k` or add cert to trusted store                 |
| Ingress not reachable                | Check `minikube addons list` and ensure Ingress is enabled |
| Host not found                       | Verify `/etc/hosts` mapping                                |
| Page not loading                     | Check service and pod status with `kubectl get all`        |


## 📦 Cleanup (Optional)
```bash
kubectl delete -f ingress.yml
kubectl delete -f service.yml
kubectl delete -f deploy.yml
kubectl delete secret wisecow-tls
```

## 🧰 Summary of Commands
| Task                 | Command                                                                                                                |                         |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| Generate certificate | `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=wisecow.local/O=wisecow"` |                         |
| Create TLS secret    | `kubectl create secret tls wisecow-tls --cert=tls.crt --key=tls.key`                                                   |                         |
| Apply ingress        | `kubectl apply -f ingress.yml`                                                                                         |                         |
| Map host             | `echo "$(minikube ip) wisecow.local"                                                                                   | sudo tee -a /etc/hosts` |
| Access app           | `curl -k https://wisecow.local`                                                                                        |                         |


## 🏁 End Result
✅ Wisecow app deployed to Kubernetes (Minikube)
✅ HTTPS enabled via self-signed certificate
✅ Trusted local development environment