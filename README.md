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
