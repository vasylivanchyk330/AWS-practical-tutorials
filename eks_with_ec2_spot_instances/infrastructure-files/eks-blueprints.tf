terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
  }
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_ami" "amazonlinux2eks" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-*"]
  }

  owners = ["amazon"]
}

data "aws_availability_zones" "available" {}

locals {
  name   = "eksspotworkshop"
  region = "--AWS_REGION--"

  cluster_version = "--EKS_VERSION--"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint = local.name
  }
}

################################################################################
# Cluster
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    # aws-ebs-csi-driver = { most_recent = true }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }

    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group = false

  manage_aws_auth_configmap = true

  eks_managed_node_groups = {
    mg_5 = {
      node_group_name = "mg5"
      instance_types  = ["m4.xlarge", "m5.xlarge", "m5a.xlarge", "m5ad.xlarge", "m5d.xlarge", "t2.xlarge", "t3.xlarge", "t3a.xlarge"]

      create_security_group = false

      subnet_ids   = module.vpc.private_subnets
      max_size     = 2
      desired_size = 2
      min_size     = 2

      create_iam_role = false
      iam_role_arn    = aws_iam_role.managed_ng.arn
      disk_size       = 100

      # Launch template configuration
      create_launch_template = true              # false will use the default launch template
      launch_template_os     = "amazonlinux2eks" # amazonlinux2eks or bottlerocket`

      labels = {
        intent = "control-apps"
      }
    }

    spot_4vcpu_16mem = {
      node_group_name = "mng-spot-4vcpu-16gb"
      capacity_type   = "SPOT"
      instance_types  = ["m4.xlarge", "m5.xlarge", "m5a.xlarge", "m5ad.xlarge", "m5d.xlarge", "t2.xlarge", "t3.xlarge", "t3a.xlarge"]
      max_size        = 4
      desired_size    = 2
      min_size        = 0

      subnet_ids = module.vpc.private_subnets

      taints = {
        spotInstance = {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      }

      labels = {
        intent = "apps"
      }
    },

    spot_8vcpu_32mem = {
      node_group_name = "mng-spot-8vcpu-32gb"
      capacity_type   = "SPOT"
      instance_types  = ["m4.2xlarge", "m5.2xlarge", "m5a.2xlarge", "m5ad.2xlarge", "m5d.2xlarge", "t2.2xlarge", "t3.2xlarge", "t3a.2xlarge"]
      max_size        = 2
      desired_size    = 1
      min_size        = 0

      subnet_ids = module.vpc.private_subnets

      taints = {
        spotInstance = {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      }

      labels = {
        intent = "apps"
      }
    }

    # jenkins mng
    jenkins_agents_mng_spot_2vcpu_8gb = {
      node_group_name = "jenkins-agents-mng-spot-2vcpu-8gb"
      capacity_type   = "SPOT"
      instance_types  = ["m4.large", "m5.large", "m5a.large", "m5ad.large", "m5d.large", "t2.large", "t3.large", "t3a.large"]
      max_size        = 3
      desired_size    = 1
      min_size        = 0

      subnet_type = "private"
      subnet_ids  = []

      k8s_labels = {
        intent = "jenkins-agents"
      }
    }

  }

  # self-managed node groups are below
  self_managed_node_groups = {
    smng_spot_4vcpu_16mem = {
      node_group_name            = "smng-spot-4vcpu-16mem"
      capacity_rebalance         = true
      use_mixed_instances_policy = true      
      create_iam_role            = false
      iam_role_arn               = aws_iam_role.managed_ng.arn
      instance_type              = "m5.xlarge"

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=eks.amazonaws.com/capacityType=SPOT,intent=apps,type=self-managed-spot --register-with-taints=spotInstance=true:PreferNoSchedule'"

      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          { instance_type = "m4.xlarge" },
          { instance_type = "m5.xlarge" },
          { instance_type = "m5a.xlarge" },
          { instance_type = "m5ad.xlarge" },
          { instance_type = "m5d.xlarge" },
          { instance_type = "t2.xlarge" },
          { instance_type = "t3.xlarge" },
          { instance_type = "t3a.xlarge" }
        ]
      }

      max_size     = 4
      desired_size = 2
      min_size     = 0

      subnet_ids         = module.vpc.private_subnets
      launch_template_os = "amazonlinux2eks"
    }

    smng_spot_8vcpu_32mem = {
      node_group_name            = "smng-spot-8vcpu-32mem"
      capacity_rebalance         = true
      use_mixed_instances_policy = true      
      create_iam_role            = false
      iam_role_arn               = aws_iam_role.managed_ng.arn
      instance_type              = "m5.2xlarge"

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=eks.amazonaws.com/capacityType=SPOT,intent=apps,type=self-managed-spot --register-with-taints=spotInstance=true:PreferNoSchedule'"

      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          { instance_type = "m4.2xlarge" },
          { instance_type = "m5.2xlarge" },
          { instance_type = "m5a.2xlarge" },
          { instance_type = "m5ad.2xlarge" },
          { instance_type = "m5d.2xlarge" },
          { instance_type = "t2.2xlarge" },
          { instance_type = "t3.2xlarge" },
          { instance_type = "t3a.2xlarge" }
        ]
      }

      max_size     = 2
      desired_size = 1
      min_size     = 0

      subnet_ids         = module.vpc.private_subnets
      launch_template_os = "amazonlinux2eks"      
    }
  }



  tags = local.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.7.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  create_delay_dependencies = [for prof in module.eks.eks_managed_node_groups : prof.node_group_arn]

  enable_metrics_server = true

  enable_cluster_autoscaler = true

  tags = local.tags
}

#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}

#---------------------------------------------------------------
# Custom IAM roles for Node Groups
#---------------------------------------------------------------
data "aws_iam_policy_document" "managed_ng_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "managed_ng" {
  name                  = "managed-node-role"
  description           = "EKS Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.managed_ng_assume_role_policy.json
  path                  = "/"
  force_detach_policies = true
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = local.tags
}

resource "aws_iam_instance_profile" "managed_ng" {
  name = "managed-node-instance-profile"
  role = aws_iam_role.managed_ng.name
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}