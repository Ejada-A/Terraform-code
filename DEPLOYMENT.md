# E-Commerce Microservices Application - Deployment Guide
## Complete End-to-End Guide for Oracle Cloud Infrastructure (OKE & OCIR)

This document provides a step-by-step guide and exact commands to build, push, provision infrastructure, and deploy the 5 microservices application to Oracle Container Engine for Kubernetes (OKE).

---

## 🛠️ 1. Prerequisites

Ensure the following CLI tools are installed and configured on your machine:
- **Docker**: Version 20+ installed and running.
- **OCI CLI**: Configured via `oci setup config`.
- **Terraform**: Version 1.5+ installed.
- **kubectl**: Version 1.28+ installed.
- **Helm**: Version 3+ installed.

---

## 🔐 2.


### GitHub Repository Secrets Required

Add the following secrets to your GitHub repository under **Settings → Secrets and variables → Actions**:

| Secret Name | Description |
| :--- | :--- |
| `OCI_USER_OCID` | Your OCI User OCID |
| `OCI_FINGERPRINT` | API key fingerprint |
| `OCI_TENANCY_OCID` | Your tenancy OCID |
| `OCI_KEY_CONTENT` | Full PEM private key content |
| `OCI_IDENTITY_DOMAIN` | Identity domain (e.g. `ejada-interim-program`) |
| `OCI_USER_EMAIL` | Your OCI user email |
| `ADMIN_EMAIL` | Admin account email for the app |
| `ADMIN_PASSWORD` | Admin account password for the app |
| `VAULT_OCIR_AUTH_TOKEN_OCID` | OCID of the OCIR Auth Token vault secret |
| `VAULT_STRIPE_SECRET_KEY_OCID` | OCID of the Stripe secret key vault secret |
| `VAULT_JWT_SECRET_OCID` | OCID of the JWT secret vault secret |
```


---

## 🔐 2. OCIR Registry Authentication

Authenticate your Docker daemon with Oracle Cloud Infrastructure Registry (OCIR) in the Saudi Arabia West (Jeddah) region:

```bash
# Option A: Automatic authentication using OCI CLI
oci container-registry access-token get --query 'data."access-token"' --raw-output | \
docker login jed.ocir.io -u BEARER_TOKEN --password-stdin

# Option B: Authentication using static OCI Auth Token
docker login jed.ocir.io -u "axkjllkftxfz/ejada-interim-program/aliahmedfakhryhamad@gmail.com"
```

---

## 📦 3. Build & Push Microservices Images to OCIR

Run the automated build script to build all 5 production multi-stage Docker images and push them to OCIR:

```bash
cd /home/ali_hamad/terraform/Project

# Usage: ./build_and_push.sh <REGION> <NAMESPACE> <TAG> <COMPARTMENT_NAME>
./build_and_push.sh jed.ocir.io axkjllkftxfz latest shared-group-a-cmp
```

This builds and pushes the following images:
- `jed.ocir.io/axkjllkftxfz/shared-group-a-cmp/auth-service:latest`
- `jed.ocir.io/axkjllkftxfz/shared-group-a-cmp/products-service:latest`
- `jed.ocir.io/axkjllkftxfz/shared-group-a-cmp/orders-service:latest`
- `jed.ocir.io/axkjllkftxfz/shared-group-a-cmp/payments-service:latest`
- `jed.ocir.io/axkjllkftxfz/shared-group-a-cmp/ecomm-ui:latest`

---

## 🏗️ 4. Provision OKE Infrastructure with Terraform

1. **Verify `terraform.tfvars` configuration**:
   Ensure `/home/ali_hamad/terraform/Project/Terraform-code/terraform.tfvars` contains your compartment OCID:
   ```hcl
   compartment_ocid = "ocid1.compartment.oc1..aaaaaaaa2t6hapsittfuvi5qyyn3ee4pjwfntqvidk3fcvihhjjn2znjwjza"
   region           = "me-jeddah-1"
   ```

2. **Initialize and apply Terraform**:
   ```bash
   cd /home/ali_hamad/terraform/Project/Terraform-code
   terraform init
   terraform plan
   terraform apply
   ```

---

## 🔑 5. Configure `kubectl` & Kubernetes Secrets

1. **Configure local `kubectl` context**:
   ```bash
   oci ce cluster create-kubeconfig \
     --cluster-id ocid1.cluster.oc1.me-jeddah-1.aaaaaaaaja3eietbhld3vsmiukdtckd756pfvfg47uicxq5rbcglmlz3ooaa \
     --file ~/.kube/config \
     --region me-jeddah-1 \
     --token-version 2.0.0 \
     --kube-endpoint PUBLIC_ENDPOINT
   ```

2. **Create the target Namespace**:
   ```bash
   kubectl apply -f ./Project/Terraform-code/kubernetes/00-namespace.yaml
   ```

3. **Create the OCIR Pull Secret (`ocir-secret`)**:
   ```bash
   kubectl create secret docker-registry ocir-secret \
     --docker-server=jed.ocir.io \
     --docker-username='axkjllkftxfz/ejada-interim-program/aliahmedfakhryhamad@gmail.com' \
     --docker-password='YOUR_OCI_AUTH_TOKEN' \
     --docker-email='aliahmedfakhryhamad@gmail.com' \
     -n ecommerce-ns
   ```

4. **Create Application Secrets Securely**:
   Create a local `.env` file containing your real secrets (this file is ignored by Git):
   ```bash
   kubectl create secret generic app-secrets \
     --from-env-file=.env \
     -n ecommerce-ns
   ```

---

## 🚀 6. Deploy Application Microservices

### **Option A: Deploy using Helm (Recommended)**
```bash
helm install ecommerce ./Project/Terraform-code/helm/ecommerce-app -n ecommerce-ns
```

### **Option B: Deploy using raw Kubernetes Manifests**
```bash
kubectl apply -f ./Project/Terraform-code/kubernetes/01-configmap.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/03-mongodb.yaml

# Wait for MongoDB pod to be Running
kubectl get pods -n ecommerce-ns -l app=mongodb -w

# Apply microservices, ingress, and HPA
kubectl apply -f ./Project/Terraform-code/kubernetes/04-auth-service.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/04-products-service.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/04-orders-service.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/04-payments-service.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/04-ecomm-ui.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/05-ingress.yaml
kubectl apply -f ./Project/Terraform-code/kubernetes/06-hpa.yaml
```

---

## 🔍 7. Verification & Accessing the Application

1. **Verify Pod Status**:
   ```bash
   kubectl get pods -n ecommerce-ns -o wide
   ```
   *Expected Output: All 11 pods showing `1/1 Running`.*

2. **Get LoadBalancer External IP**:
   ```bash
   kubectl get svc ecomm-ui-lb -n ecommerce-ns
   ```

3. **Access Storefront**:
   Open `http://<EXTERNAL_IP>` in your browser (e.g., `http://158.101.233.0`).

---

## 🛠️ 8. Troubleshooting & Useful Commands

### **Restart Microservices Deployments**
```bash
kubectl rollout restart deployment -n ecommerce-ns
```

### **Check Microservice Logs**
```bash
kubectl logs -n ecommerce-ns -l app=auth-service --tail=50
kubectl logs -n ecommerce-ns -l app=products-service --tail=50
kubectl logs -n ecommerce-ns -l app=orders-service --tail=50
kubectl logs -n ecommerce-ns -l app=payments-service --tail=50
kubectl logs -n ecommerce-ns -l app=ecomm-ui --tail=50
```

---

## 💥 9. Teardown / Destruction Guide

To destroy active resources on OCI when finished:

```bash
# 1. Uninstall Helm release or delete Kubernetes manifests
helm uninstall ecommerce -n ecommerce-ns
kubectl delete -f ./Project/Terraform-code/kubernetes/

# 2. Destroy OCI Infrastructure via Terraform
cd /home/ali_hamad/terraform/Project/Terraform-code
terraform destroy
```
