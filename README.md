# Terraform-Aws

```
 aws ec2 describe-instances --profile=admin --region us-east-1 --query
 "Reservations[*].Instances[*].[InstanceId,Platform]" --output table
```
```
aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,Platform,Tags[?Key=='Name'].Value]" --output table
```
aws ec2 describe-instances --profile=admin --region us-east-1 --query "Reservations[*].Instances[*].[InstanceId,PlatformDetails,SecurityGroups]" --output text

# IAM
# * create IAM user
```
provider "aws" {
  region = "us-east-1"
  access_key = "*************"
  secret_key = "*************"
  
}
resource "aws_iam_user" "test_user" {
  name = "pavi"
  tags = {
    Description = "test user"
  }

  
}
```

# * Hide aws key in .aws/cresentials file 
```
provider "aws" {
  region = "us-east-1" 
}
resource "aws_iam_user" "test_user" {
  name = "pavi-test"
  tags = {
    Description = "test user"
  }

  
}
```


# EC2 
# * EC2 Instace creation
```
provider "aws" {
  region = "us-east-1"
  
}

resource "aws_instance" "webserver-1" {
  tags = {
    name = "webserv-1"
  }
  ami = "ami-07caf09b362be10b8"
  instance_type = "t2.micro"
  key_name = "ssh-Virginia-key"
  

  
}
```
# * EC2 Multi Region creation
```
provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
  
}

provider "aws" {
  alias = "us-east-2"
  region = "us-east-2"

}

resource "aws_instance" "webserver-1" {
  tags = {
    name = "webserv-1"
  }
  ami = "ami-07caf09b362be10b8"
  instance_type = "t2.micro"
  key_name = "ssh-Virginia-key"
  provider = aws.us-east-1
  
}

resource "aws_instance" "webserver-2" {
  tags = {
    name = "webserv-2"
  }
  ami = "ami-0d77c9d87c7e619f9"
  instance_type = "t2.micro"
  key_name = "ssh-Virginia-key"
  provider = aws.us-east-2
  
}
```
# * Variables:
* Input variable
* Output variable

* 1 string variable type
* 2 number variable type
* 3 boolean variable type
```
# Variables Demo 


# Define an input variable for the EC2 instance type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "instance_count" {
  description = "Number of Instances"
  type = number
  default = 2
  
}
variable "enable_public_ip" {
  description = "Enabling public Ip of intances"
  type = bool
  default = false
  
}
# Define an input variable for the EC2 instance AMI ID
variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string  # asks to provide ami id as user input
}

# Configure the AWS provider using the input variables
provider "aws" {
  region      = "us-east-1"
}

# Create an EC2 instance using the input variables
resource "aws_instance" "webserv" {
  ami           = var.ami_id 
  instance_type = var.instance_type  ##------String variable
  count = var.instance_count         ## ------------- Number variable
  associate_public_ip_address = var.enable_public_ip   ##-------- bool variable
  tags = {
    Name = "webserv"
    
  }
}

# Define an output variable to expose the public IP address of the EC2 instance
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.webserv.*.public_ip

}
```
* List, map, set
```
provider "aws" {
  region = "us-east-1" 
}

## List variable type##
variable "user_name" {
  description = "IAM users"
  type = list(string)
  default = [ "pavi","rebel","paru" ]
  
}
resource "aws_iam_user" "developers" {
  count = length(var.user_name)
  name = var.user_name[count.index]
  
  lifecycle {
    prevent_destroy = true
  }
  

  }

  ## Map variable type##
variable "env" {
  description = "project env"
  type = map(string)
  default = {
    "project" = "rebel",
    "env" = "dev"
  }
  
}

resource "aws_instance" "web-dev" {
  ami = "ami-07caf09b362be10b8"
  instance_type = "t2.micro"
  tags = var.env
  
}
```

# # Dynamic Variables
* Create ```main.tf```

```
provider "aws" {
  region = "us-east-1"
  
}

resource "aws_instance" "web" {
  ami = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = var.env_name
  }
  
}
```
* Create ```variable.tf```
```
variable "instance_type" {
  
}

variable "env_name" {
  
}
variable "ami_id" {
  type = string
  default = "t2.micro"
  
  
}
```
* Create ```dev.tfvars```
```
ami_id = "ami-07caf09b362be10b8"
instance_type = "t2.micro"
env_name = "dev"
```
* Commands
  ```
  terraform init -var-file="dev.tfvars"
  terraform plan -var-file="dev.tfvars"
  terraform deploy -var-file="dev.tfvars"

  --------- To destroy
  terraform destroy -var-file="dev.tfvars"
  ```

  # # count , loops, for_each

  # * Loops with count
  *  list using count
  
```
provider "aws" {
  region = "us-east-1"
  
}

variable "aws_instances" {
  description = "creating multiple instances"
  type = list(string)
  default = [ "webserv-1","webserv-2" ]
  

}
resource "aws_instance" "dev" {
  ami = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  count = length(var.aws_instances)
  tags = {
    Name = "${var.aws_instances[count.index]}"
  }
  
}
```
*  Set using count
```
provider "aws" {
  region = "us-east-1"
  
}

variable "aws_instances" {
  description = "creating multiple instances"
  type = set(string)
  default = [ "webserv-1","webserv-2" ]
  
}

#### Convert set to list ####
locals {
  my_instances_list = tolist(var.aws_instances)
}
resource "aws_instance" "dev" {
  ami = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  count = length(var.aws_instances)
  tags = {
    Name = local.my_instances_list[count.index]
  }
  
}
```

* map using count
```
provider "aws" {
  region = "us-east-1"
  
}

variable "aws_instances" {
  description = "creating multiple instances"
  type = map(string)
  default = {
    server_1 = "web-1"
    server_2 = "db-1"

  }
  
}

#### Fetch keys of map ####
locals {
  my_instances_list = keys(var.aws_instances)
}
resource "aws_instance" "dev" {
  ami = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  count = length(local.my_instances_list)
  tags = {
   Name = var.aws_instances[local.my_instances_list[count.index]]
  }
  
}
```

* for_each ```{ 
  we can't use list, Instead use set or map  }```
  * Set using for_each

```
  provider "aws" {
  region = "us-east-1"
  
}

variable "aws_instances" {
  description = "creating multiple instances"
  type = set(string)
  default = ["web-1", "web-2"]
  
}

variable "iam_users" {
  description = "creating iam users"
  type = set(string)
  default = [ "user-1","user-2","user-3" ]
  
}

resource "aws_instance" "dev" {
  ami = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  for_each = var.aws_instances
  tags = {
    Name = each.value
  }  
}

resource "aws_iam_user" "devuser" {
  for_each = var.iam_users
  name = each.value
  
}

```
* map using for_each
```
provider "aws" {
  region = "us-east-1"
  
}

variable "aws_instances" {
  description = "creating multiple instances"
  type = map(string)
  default = {
    server-1 = "web-1"
    server-2 = "web-2"
  }
  
}

variable "iam_users" {
  description = "creating iam users"
  type = map(string)
  default = {
    user1 = "user-1"
    user2 = "user-2"
  }
  
}

resource "aws_instance" "dev" {
  ami = "ami-0fe630eb857a6ec83"
  instance_type = "t2.micro"
  for_each = var.aws_instances
  tags = {
    Name = each.value
  }  
}

resource "aws_iam_user" "devuser" {
  for_each = var.iam_users
  name = each.value
  
  
}

```
