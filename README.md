# Terraform-Aws

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
  
