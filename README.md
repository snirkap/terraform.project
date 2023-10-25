# terraform.project
## Here you can see a diagram explaining the project


![terraform (8)](https://github.com/snirkap/terraform.project/assets/120733215/14e1be6d-3c65-4252-8cd6-5b789775f395)


## requirements:
1. aws account
2. terraform installed in your local machine
3. aws cli installed in your local machine
### tutorial
1. git clone https://github.com/snirkap/terraform.project.git
2. write "aws configure" command and follow the prompts.
3. in the main.tf file in the ALB & target group you need to change the subnet_id in mapping_id to the subnets that you wnat the alb will work on, and in the vpc_id Replace with your VPC ID.
4. in the main.tf in the cloudFront section you need to change the alias to your dns name and in the acm_certificate_arn you need to write your the ssl certificate for your dns name.
5. in the route 53 section you need to Replace with the Route 53 hosted zone ID for your dns name in zone_id and also change the name into your dns name.
6. write "terraform init" command.
7. write "terraform apply" command.



