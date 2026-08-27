# E-Commerce Platform Deployment Guide

This guide covers the complete lifecycle of deploying, managing, and destroying the E-Commerce Microservices architecture using Terraform, Kubernetes, Helm, and GitHub Actions.

## 📋 Table of Contents
1. [Prerequisites & Environment Setup](#1-prerequisites--environment-setup)
2. [Infrastructure Provisioning (Terraform)](#2-infrastructure-provisioning-terraform)
3. [Automated CI/CD Pipeline (GitHub Actions)](#3-automated-cicd-pipeline-github-actions)
4. [Preserving Your Public IP Address](#4-preserving-your-public-ip-address)
5. [Manual Application Deployment](#5-manual-application-deployment)
6. [Cost Saving: Scale to Zero](#6-cost-saving-scale-to-zero)
7. [Destroying the Infrastructure](#7-destroying-the-infrastructure)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites & Environment Setup

### The `.env` File
We use a local `.env` file to store sensitive application secrets and Oracle Cloud (OCI) credentials for Terraform's S3 remote backend. **This file is ignored by Git and should never be committed.**

Create a `.env` file in the root of `Terraform-code` with the following variables:
```bash
# Application Secrets (Used for manual kubernetes deployment)
JWT_SECRET="your_jwt_secret"
STRIPE_SECRET_KEY="your_stripe_secret"
ADMIN_EMAIL="admin@yourstore.com"
ADMIN_PASSWORD="secure_password"

# OCI S3 Backend Credentials (Used by Terraform)
AWS_ACCESS_KEY_ID="your_oci_customer_access_key"
AWS_SECRET_ACCESS_KEY="your_oci_customer_secret_key"

# Fix for OCI S3 Chunked Encoding Errors
AWS_REQUEST_CHECKSUM_CALCULATION="when_required"
AWS_RESPONSE_CHECKSUM_VALIDATION="when_required"
```

---

## 2. Infrastructure Provisioning (Terraform)

Your infrastructure (VCN, Kubernetes Cluster, Node Pools) is managed by Terraform. The state is stored remotely in an OCI Object Storage bucket. 

Because we need to load the AWS chunking fix and credentials from the `.env` file, **always wrap your Terraform commands** in a bash subshell (especially if using Fish shell):

**Initialize Terraform:**
```bash
bash -c 'set -a; source .env; set +a; terraform init'
```

**Plan & Apply:**
```bash
bash -c 'set -a; source .env; set +a; terraform plan'
bash -c 'set -a; source .env; set +a; terraform apply -auto-approve'
```
*(Note: Upon successful creation, Terraform automatically connects to GitHub and pushes your new `CLUSTER_OCID` as a Repository Secret!)*

---

## 3. Automated CI/CD Pipeline (GitHub Actions)

We use a fully automated GitHub Actions pipeline (`.github/workflows/deploy.yml`) to deploy the microservices.

### What the pipeline does:
1. Provisions the cluster using Terraform (Step 4).
2. Builds all microservice Docker images and pushes them to OCIR.
3. Dynamically creates Kubernetes Secrets from your GitHub Secrets.
4. Installs the NGINX Ingress Controller.
5. Deploys the applications via ArgoCD and Helm.

### How to trigger it:
1. Go to your repository on GitHub.
2. Click the **Actions** tab.
3. Click **Deploy Infrastructure and Applications** on the left.
4. Click the **Run workflow** button on the right.

---

## 4. Preserving Your Public IP Address

To avoid changing your DNS records and Let's Encrypt certificates every time you rebuild the cluster, you can use a Reserved Public IP.

1. Reserve a Public IP address in the **Oracle Cloud Console** (Networking -> IP Management -> Reserved Public IPs).
2. Go to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **Variables**.
3. Create a New Variable named `RESERVED_PUBLIC_IP` and paste your IP address.

The GitHub Actions pipeline will automatically detect this variable and bind your Load Balancer to that exact IP address every time it runs.

---

## 5. Manual Application Deployment

If you prefer to deploy manually without GitHub Actions, you can do so directly from your terminal.

**Step A: Export your Kubeconfig**
```bash
export CLUSTER_ID=$(terraform output -raw cluster_id)
oci ce cluster create-kubeconfig --cluster-id $CLUSTER_ID --file ~/.kube/config --region me-jeddah-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
```

**Step B: Create the Secrets from your `.env` file**
```bash
kubectl create namespace ecommerce-ns
kubectl create secret generic app-secrets --from-env-file=.env -n ecommerce-ns
```

**Step C: Deploy via Helm**
```bash
helm upgrade --install ecommerce ./helm/ecommerce-app -n ecommerce-ns --create-namespace
```

---

## 6. Cost Saving: Scale to Zero

If you want to stop paying for compute resources but don't want to destroy the entire cluster and lose your database, you can "suspend" the cluster.

1. **Delete the Load Balancer:** Load balancers cost money even when idle.
   ```bash
   kubectl delete namespace ingress-nginx
   ```
2. **Scale Nodes to Zero:** Open `terraform.tfvars`, set `node_count = 0`, and run:
   ```bash
   bash -c 'set -a; source .env; set +a; terraform apply'
   ```
*To resume, change `node_count` back to 2 and run `terraform apply`.*

---

## 7. Destroying the Infrastructure

To permanently destroy the cluster and all resources:

**CRITICAL FIRST STEP:** 
You must delete the Kubernetes namespaces containing Load Balancers and Block Volumes *before* running Terraform, otherwise Terraform will hang forever trying to delete the network subnets.

```bash
kubectl delete namespace ecommerce-ns
kubectl delete namespace ingress-nginx
```
Wait for these commands to finish (they take a few minutes as they delete the physical OCI resources).

**Run Terraform Destroy:**
```bash
bash -c 'set -a; source .env; set +a; terraform destroy -auto-approve'
```

---

## 8. Troubleshooting

### "AWS chunked encoding not supported" (HTTP 501)
If Terraform fails to upload the state file and generates an `errored.tfstate` file, it means you ran Terraform without loading the `.env` file chunking fix.
**Fix:** Push the errored state with the wrapper command:
```bash
bash -c 'set -a; source .env; set +a; terraform state push errored.tfstate'
```

### "dial tcp: lookup... i/o timeout"
If you get a DNS timeout while running Terraform, your internet connection dropped momentarily. 
**Fix:** Wait for the internet to stabilize, run the `terraform state push` command above, and resume your `apply` or `destroy`.

### Terraform is stuck "Still destroying..."
If Terraform is stuck for more than 40 minutes deleting a Subnet or VCN, a Kubernetes Load Balancer or Block Volume was left behind.
**Fix:** Go to the OCI Console in your browser. Manually terminate any remaining Load Balancers (Networking -> Load Balancers) and Block Volumes (Storage -> Block Volumes). Terraform will immediately unblock and finish the destruction.
