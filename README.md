# terraform-eks

Phase-1 Terraform for a cost-conscious, production-like **Amazon EKS** cluster on AWS (`us-east-1`).

This repository provisions the VPC and EKS infrastructure only. Later phases (Hello World Go service, Helm, Prometheus/Grafana, CI/CD) are intentionally out of scope for now.

## What this creates

| Layer | Resources |
|-------|-----------|
| Network | VPC (`10.0.0.0/16`), IGW, 2 public + 2 private subnets across `us-east-1a` / `us-east-1b`, **1 NAT Gateway**, route tables |
| Compute | EKS cluster (default Kubernetes **1.35**), managed node group (`t3.medium`, desired/min **2**, max **3**) in private subnets |
| Add-ons | `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver` (IRSA) |
| IAM | Cluster role, node role, EBS CSI IRSA role (no IAM users / access keys in code) |

Worker nodes have **no public IPs**. Outbound internet goes through the single NAT Gateway.

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
aws eks update-kubeconfig --region us-east-1 --name devops-take-home
kubectl get nodes
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
