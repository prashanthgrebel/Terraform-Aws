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

```
  # Variables Demo   [type        = string]
 

# Define an input variable for the EC2 instance type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
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
resource "aws_instance" "webserv-1" {
  ami           = var.ami_id 
  instance_type = var.instance_type
}

# Define an output variable to expose the public IP address of the EC2 instance
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.webserv-1.public_ip
}

```
