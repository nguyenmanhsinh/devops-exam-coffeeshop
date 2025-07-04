resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-eks-cluster"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = {
    Name        = "${var.environment}-eks-cluster"
    Environment = var.environment
    Owner       = var.owner_name
    Temporary   = "true"
    ExpiryDate  = var.expiry_date
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [var.instance_type]
  
  disk_size = 30

  tags = {
    Name        = "${var.environment}-eks-node-group"
    Environment = var.environment
    Owner       = var.owner_name
    Temporary   = "true"
    ExpiryDate  = var.expiry_date
  }

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "addons" {
  for_each = { for addon in var.eks_addons : addon.name => addon }

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = each.value.name
  addon_version            = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"
} 