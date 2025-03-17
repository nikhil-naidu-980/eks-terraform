cat << 'EOF' > README.md
# EKS with Nginx Deployment

This repository contains the Terraform configuration to set up an Amazon Elastic Kubernetes Service (EKS) cluster on AWS and deploy a simple Nginx application with a LoadBalancer service.

## Prerequisites

Before using this repository, ensure that you have the following:

- **AWS account** with appropriate permissions.
- **Terraform** installed. Download it from [Terraform's website](https://www.terraform.io/downloads.html).
- **AWS CLI** installed and configured. Follow [AWS CLI installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- **kubectl** installed. Install it from [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/).

## Project Overview

The repository includes:

1. **`main.tf`**: A Terraform script to:
   - Set up an EKS cluster.
   - Configure VPC, subnets, and networking.
   - Create IAM roles and security groups.
   - Provision an EKS node group.

2. **`nginx.yaml`**: A Kubernetes manifest to:
   - Deploy an Nginx application as a Deployment.
   - Expose it via a LoadBalancer service.

## Setup and Usage

Follow the steps below to deploy the infrastructure and application.

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone <your-repo-url>
cd <your-repo-directory>
```

### 2. Configure AWS Provider

The main.tf file uses the AWS provider, set to us-west-2. Ensure your AWS CLI is configured with credentials:

```bash
aws configure
```

### 3. Initialize Terraform

Run this command to initialize the Terraform configuration:

```bash
terraform init
```

### 4. Apply the Terraform Configuration

Deploy the EKS cluster and node group:

```bash
terraform apply
```

### 5. Deploy the Nginx Application

Update your kubeconfig and apply the Nginx manifest:

```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-west-2
kubectl apply -f nginx.yaml
```

### 6. Verify the Deployment

Check the service to get the external LoadBalancer URL:

```bash
kubectl get svc nginx-service -n default -o wide
```

Visit the EXTERNAL-IP in your browser to see the Nginx welcome page.


### 7. Clean Up

To remove all resources when done:

```bash
terraform destroy
```








