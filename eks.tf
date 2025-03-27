module "eks" {
  source  = "git@github.westernasset.com:bois/terraform-aws-wam-eks"
  
  cluster_name                     = "BOIS-CP-NP"
  cluster_version                  = "1.30"
  iam_role_name                    = "EKS-Cluster-Service-Role"
  vpc_id                           = module.vpc_paas.vpc_id
  subnet_ids                       = module.vpc_paas.subnet_ids
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_security_group_name      = "SG-EKS-Cluster"
  cluster_security_group_additional_rules = {
    On-prem-aws-prod-ingress = {
      description                = "On-prem/aws-prod ingress"
      protocol                   = "tcp"
      from_port                  = 0
      to_port                    = 65535
      type                       = "ingress"
      cidr_blocks                 = ["10.0.0.0/8"]
    }
  }
  cluster_enabled_log_types        = [ "audit", "api", "authenticator", "controllerManager", "scheduler" ]
  create_kms_key = false
  enable_kms_key_rotation = false
  attach_cluster_encryption_policy = false
  cluster_encryption_config = {}
  cluster_addons = {}
  node_security_group_name         = "SG-Node"
  node_security_group_additional_rules = {
    ingress_from_on_prem-aws-prod = {
    description                = "ingress_from_on_prem-aws-prod"
      protocol                   = "tcp"
      from_port                  = 0
      to_port                    = 65535
      type                       = "ingress"
      cidr_blocks                 = ["10.0.0.0/8"]
    }
  }

  enable_irsa                      = false
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large", "t3.micro"]
    iam_role_attach_cni_policy = true
    key_name = "CET-AWS-BOIS-WEST-TECH-CP-NP"
  }

  eks_managed_node_groups = {
    master = {
      name            = "Master_EKS_Managed"
      use_name_prefix = true
      launch_template_name = "Master-Template"

      subnet_ids = module.vpc_paas.subnet_ids
      # subnet_ids = [module.vpc_paas.subnet_03_id]
      
      min_size     = 0
      max_size     = 2
      desired_size = 1
      
      ami_id = "ami-0b28c6cca713e7ff4"
      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      EOT
      
      post_bootstrap_user_data = <<-EOT
    
      EOT

      capacity_type        = "ON_DEMAND"
      force_update_version = true
      instance_types       = ["m6i.2xlarge"]

      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
        # "node-role.westernasset.com/lifecycle" = "spot"
        # "node-role.westernasset.com" = "general-purpose"
        # "node-role.westernasset.com/intent" = "jenkins"
        # "node-role.westernasset.com/builder" = "true"
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      description = "EKS managed node group launch template"

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group role"

      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      tags = {
        ExtraTag = "EKS managed node group"
      }
    },
    test = {
      name            = "Test_EKS_Managed"
      use_name_prefix = true
      launch_template_name = "Test-Template"

      subnet_ids = module.vpc_paas.subnet_ids
      # subnet_ids = [module.vpc_paas.subnet_03_id]
      
      min_size     = 1
      max_size     = 3
      desired_size = 2
      
      ami_id = "ami-0b28c6cca713e7ff4"
      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      EOT
      
      post_bootstrap_user_data = <<-EOT
    
      EOT

      capacity_type        = "ON_DEMAND"
      force_update_version = true
      instance_types       = ["m6i.2xlarge"]

      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
        # "node-role.westernasset.com/lifecycle" = "spot"
        # "node-role.westernasset.com" = "general-purpose"
        # "node-role.westernasset.com/intent" = "jenkins"
         "node-role.westernasset.com/builder" = "true"
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      description = "EKS managed node group launch template"

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-test"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group role"

      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      tags = {
        ExtraTag = "EKS managed node group"
      }
    },
    /*TEST = {
      name            = "TEST_EKS_Managed"
      use_name_prefix = true
      launch_template_name = "TEST-Template"

      subnet_ids = module.vpc_paas.subnet_ids

      min_size     = 1
      max_size     = 1
      desired_size = 1
      // amazon-eks-node-1.27-v20230825
      ami_id                     = "ami-0bce9ab1f1be3282a"
      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      EOT
      
      post_bootstrap_user_data = <<-EOT
    
      EOT

      capacity_type        = "ON_DEMAND"
      force_update_version = true
      instance_types       = ["r5.2xlarge"]

      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
        # "node-role.westernasset.com/lifecycle" = "spot"
        # "node-role.westernasset.com" = "general-purpose"
        # "node-role.westernasset.com/intent" = "jenkins"
        # "node-role.westernasset.com/builder" = "true"
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      description = "EKS managed node group launch template"

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-test"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group role"

      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      tags = {
        ExtraTag = "EKS managed node group"
      }
    }*/
 }
 
 
  tags = {"EKS cluster" = "BOIS-CP-NP"
          "Platform"    = "EKS"}
         
}

module "spot-iam-role" {
      source = "git@github.westernasset.com:bois/terraform-aws-wam-iam-role?ref=v1.0.0"
      
      depends_on = [ module.spot-iam-policy ]

      name               = "Spot-Role"
      assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::922761411349:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "KkO8K3qnTwx-BaPqydNEcKpTYD1qZWKUgu2G-mHVmwk-"
                }
            }
        }
    ]
  })
       policy_arns = [module.spot-iam-policy.policy_arn]
}
