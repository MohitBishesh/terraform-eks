# terraform-eks

Phase-1 Terraform for a cost-conscious, production-like **Amazon EKS** cluster on AWS (`us-east-1`).

This repository provisions the VPC and EKS infrastructure only. Later phases (Hello World Go service, Helm, Prometheus/Grafana, CI/CD) are intentionally out of scope for now.

## What this creates

Worker nodes have **no public IPs**. Outbound internet goes through the single NAT Gateway. Node label: `workload.type=worker-webapp`.

### Resources created by Terraform

| # | AWS resource type | Name / identity (pattern) | Count | Module | Notes |
|---|-------------------|---------------------------|------:|--------|-------|
| 1 | VPC | `{cluster_name}-vpc` | 1 | `vpc` | CIDR `10.0.0.0/16`, DNS hostnames/support enabled |
| 2 | Internet Gateway | `{cluster_name}-igw` | 1 | `vpc` | Attached to VPC |
| 3 | Public subnet | `{cluster_name}-public-us-east-1a` | 1 | `vpc` | `10.0.0.0/24`, AZ `us-east-1a`, public IPs on launch |
| 4 | Public subnet | `{cluster_name}-public-us-east-1b` | 1 | `vpc` | `10.0.1.0/24`, AZ `us-east-1b` |
| 5 | Private subnet | `{cluster_name}-private-us-east-1a` | 1 | `vpc` | `10.0.10.0/24`, AZ `us-east-1a`, no public IPs |
| 6 | Private subnet | `{cluster_name}-private-us-east-1b` | 1 | `vpc` | `10.0.11.0/24`, AZ `us-east-1b`, no public IPs |
| 7 | Elastic IP | `{cluster_name}-nat-eip` | 1 | `vpc` | Used by the single NAT Gateway |
| 8 | NAT Gateway | `{cluster_name}-nat` | 1 | `vpc` | In public subnet `us-east-1a` only (cost trade-off) |
| 9 | Route table (public) | `{cluster_name}-public-rt` | 1 | `vpc` | `0.0.0.0/0` → IGW |
| 10 | Route (public) | — | 1 | `vpc` | Default route to Internet Gateway |
| 11 | Route table association (public) | — | 2 | `vpc` | One per public subnet |
| 12 | Route table (private) | `{cluster_name}-private-rt-{az}` | 2 | `vpc` | One per AZ |
| 13 | Route (private) | — | 2 | `vpc` | Both `0.0.0.0/0` → shared NAT Gateway |
| 14 | Route table association (private) | — | 2 | `vpc` | One per private subnet |
| 15 | IAM role | `{cluster_name}-cluster-role` | 1 | `eks` | Trust: `eks.amazonaws.com` |
| 16 | IAM role policy attachment | AmazonEKSClusterPolicy | 1 | `eks` | Attached to cluster role |
| 17 | IAM role | `{cluster_name}-node-role` | 1 | `eks` | Trust: `ec2.amazonaws.com` |
| 18 | IAM role policy attachment | AmazonEKSWorkerNodePolicy | 1 | `eks` | Attached to node role |
| 19 | IAM role policy attachment | AmazonEKS_CNI_Policy | 1 | `eks` | Attached to node role |
| 20 | IAM role policy attachment | AmazonEC2ContainerRegistryReadOnly | 1 | `eks` | Attached to node role |
| 21 | EKS cluster | `devops-kubernetes-learning` | 1 | `eks` | Kubernetes **1.35** (variable); private + CIDR-restricted public API |
| 22 | EKS managed node group | `{cluster_name}-workers` | 1 | `eks` | `t3.medium`, desired/min **2**, max **3**, private subnets; labels `role=worker`, `workload.type=worker-webapp` |
| 23 | IAM OIDC provider | `{cluster_name}-oidc` | 1 | `eks` | Enables IRSA |
| 24 | IAM role | `{cluster_name}-ebs-csi-role` | 1 | `eks` | IRSA for `kube-system:ebs-csi-controller-sa` |
| 25 | IAM role policy attachment | AmazonEBSCSIDriverPolicy | 1 | `eks` | Attached to EBS CSI IRSA role |
| 26 | EKS add-on | `vpc-cni` | 1 | `eks` | Cluster networking |
| 27 | EKS add-on | `coredns` | 1 | `eks` | Cluster DNS |
| 28 | EKS add-on | `kube-proxy` | 1 | `eks` | Service networking |
| 29 | EKS add-on | `aws-ebs-csi-driver` | 1 | `eks` | Persistent volumes via IRSA |

**Also created implicitly by AWS (not separate Terraform resources):** EKS cluster security group, node security group / ENIs, EC2 instances for the managed node group (2× `t3.medium` + root EBS volumes).

**Default cluster name:** `devops-kubernetes-learning` (override with `cluster_name` in `terraform.tfvars`).

## Architecture

```
VPC 10.0.0.0/16
├── Internet Gateway
├── Public subnet us-east-1a (10.0.0.0/24) ── NAT Gateway + EIP
├── Public subnet us-east-1b (10.0.1.0/24)
├── Private subnet us-east-1a (10.0.10.0/24) ── EKS worker nodes
└── Private subnet us-east-1b (10.0.11.0/24) ── EKS worker nodes
         └── both private route tables → single NAT
```

## Repository layout

```
.
├── versions.tf / providers.tf / backend.tf
├── main.tf / variables.tf / outputs.tf
├── terraform.tfvars.example
├── modules/
│   ├── vpc/
│   └── eks/
└── README.md
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.5`
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS credentials with permission to create VPC, EKS, IAM, EC2 (prefer an **EC2 instance profile** or temporary credentials — do not hard-code keys)
- `kubectl` (after the cluster exists)

Verify identity:

```powershell
aws sts get-caller-identity
```

## Quick start

### 1. Configure variables

```powershell
cd E:\lucidity-assign-git-devops\terraform-eks
copy terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` as needed. Important settings:

- **`public_access_cidrs`** — your **public** IP (not `192.168.x.x`). Find it with:

  ```powershell
  (Invoke-RestMethod -Uri "https://checkip.amazonaws.com").Trim()
  ```

  Example:

  ```hcl
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["YOUR.PUBLIC.IP/32"]
  ```

  Never use `0.0.0.0/0` in committed config.

- **`kubernetes_version`** — defaults to `1.35` (variable, upgradeable later).

### 2. Initialize Terraform

```powershell
terraform init
```

### 3. Format and validate

```powershell
terraform fmt -recursive
terraform validate
```

### 4. Plan

```powershell
terraform plan
```

Review the plan carefully (NAT, EKS control plane, 2× `t3.medium`, EIP).

### 5. Apply (only when you intend to create AWS resources)

```powershell
terraform apply
```

First apply typically takes **15–25 minutes** (EKS control plane + node group).

### 6. Configure kubectl

```powershell
aws eks update-kubeconfig --region us-east-1 --name devops-kubernetes-learning
kubectl get nodes
kubectl get nodes --show-labels
kubectl get pods -A
```

Useful outputs:

```powershell
terraform output
```

## Cost and availability trade-offs

These choices are intentional for a take-home budget while staying reasonably production-like:

| Choice | Benefit | Trade-off |
|--------|---------|-----------|
| 2 AZs (not 3) | Lower footprint | Less AZ diversity |
| **1 NAT Gateway** | ~½ NAT cost vs per-AZ | If the NAT’s AZ fails, private egress fails |
| `t3.medium` × 2 (max 3) | Low compute cost | Limited capacity for heavy workloads |
| Private worker nodes | Better isolation | Need NAT for outbound pulls |
| Control-plane logging off by default | Avoids CloudWatch log spend | Enable via `enable_cluster_log_types` if needed |
| No ALB / VPC interface endpoints yet | No idle LB / endpoint charges | Add in later phases when required |

**Main recurring cost drivers:** NAT Gateway, 2× `t3.medium`, EKS control plane (~$0.10/hr). Rough lean total if left running: on the order of **~$170–220/month**. Destroy when idle.

## Security notes

- Nodes run only in **private** subnets (`map_public_ip_on_launch = false`).
- EKS API: private endpoint enabled; public endpoint is optional and CIDR-restricted.
- IAM uses AWS managed policies for cluster/node roles; EBS CSI uses **IRSA** (not attached to the node role).
- No AWS access keys are stored in Terraform. `terraform.tfvars` is gitignored (do not commit personal IPs or secrets).

## Destroy / cleanup

When finished (to stop billing):

```powershell
terraform destroy
```

Confirm the NAT EIP and node group are gone in the AWS console afterward.

## What’s not included yet

- Hello World application / Dockerfile / ECR
- Helm chart
- Prometheus / Grafana
- HPA, PDB, NetworkPolicy
- GitHub Actions CI/CD

Those will be added after this cluster is verified.
