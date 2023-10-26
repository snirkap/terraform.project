# Terraform.project
## Here you can see a diagram explaining the project:


![terraform (10)](https://github.com/snirkap/terraform.project/assets/120733215/083607a7-0d56-44f5-bd23-88a12b17687f)




## AWS Web Architecture with Terraform:
This project defines a scalable AWS web architecture using Terraform. It employs Route 53 for DNS, CloudFront for content distribution, and an Application Load Balancer to manage incoming traffic. EC2 instances, governed by Auto Scaling Groups (ASG), are provisioned within a VPC. These EC2 instances fetch images from an S3 bucket to display on their web pages. Terraform scripts are available for seamless infrastructure-as-code deployment.
## requirements:
1. aws account
2. terraform installed in your local machine
3. aws cli installed in your local machine
### Setup:
1. git clone https://github.com/snirkap/terraform.project.git
2. write "aws configure" command and follow the prompts.
3. **main.tf file:**
   * in ALB & target group you need to change the subnet_id in mapping_id to the subnets that you wnat the alb will work on, and in the vpc_id Replace with your VPC ID.
   * in cloudFront section you need to change the alias to your dns name and in the acm_certificate_arn you need to write your the ssl certificate for your dns name.
   * in route 53 section you need to Replace with the Route 53 hosted zone ID for your dns name in zone_id and also change the name into your dns name.
4. write "terraform init" command.
5. write "terraform apply" command.



