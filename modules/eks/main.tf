################################################################################
# IAM — cluster role
# AmazonEKSClusterPolicy is the AWS-managed policy required for the control
# plane to manage AWS resources on your behalf. No broader admin policies.
################################################################################

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    sid     = "EKSClusterAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

################################################################################
# IAM — node role
# WorkerNode: kubelet registration with the control plane
# CNI: manage ENIs/IPs for pods (attached to nodes for simplicity in phase-1)
# ECR ReadOnly: pull container images
# EBS CSI permissions are NOT on the node role — they use IRSA (addons.tf).
################################################################################

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    sid     = "EKSNodeAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

################################################################################
# Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    # Only set when public access is enabled; root module check forbids 0.0.0.0/0.
    public_access_cidrs = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  enabled_cluster_log_types = var.enable_cluster_log_types

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

################################################################################
# Managed node group — private subnets, no public IPs, cost-capped scaling
################################################################################

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.cluster_version

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  # Explicitly keep nodes private; private subnets already have
  # map_public_ip_on_launch = false.
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-workers"
  })

  labels = {
    role            = "worker"
    "workload.type" = "worker-webapp"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}
