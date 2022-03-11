# Jenkins cluster
Building automated Jenkins CiCd platform  on AWS, using concepts like Infrastructure as code, configuration as code, immutable infrastructure. This project will get your Jenkins master fully configured with plugins and a cluster of workers on AWS Autoscaling group.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

To run this project all you need is. Docker, Terraform, and AWS client installed in your local machine.

```
Packer
Terraform
AWS Cli.
```

## Automated Jenkins cluster.
A step by step series of examples that tell you how to get your fully automated jenkins cluster up and running.

###Golden images
We are using packer to generate Jenkins master and Worker Amazon Machine Images. Golden images allow you to deploy **consistently** several servers, remote applications, and virtual machines based on a single base image. Reduce operator errors during manual configuration. 

####Prerequisites 
Create packer IAM user https://www.packer.io/docs/builders/amazon.html#iam-task-or-instance-role
Configure your local aws profile with packer users credentials. After configuring aws client configuration should look something like this.
```
[default]
aws_access_key_id = AKxxxxxxxxxxTF
aws_secret_access_key = AgcYcxxxxqxxxxxxxxxxxxxxxxx/rNKCaovBQ2W6
[packer]
aws_access_key_id=AKIxxxxxxxxxxxxxxxXBQA
aws_secret_access_key=2qEMy1UxxxxxxxxxxxxxxxxxxxxxxBHxCyFPzJHHxn
```

##### Instance Prerequisites

####Build
Run packer build ami and worker ami to generate Master and Worker AMIs.
```
cd packer
packer build ami.json
packer build worker-ami.json
```
#### Verify
Once builds are done, verify your account for the 2 AMIs. 

### Create infrastructure.

Log into your aws account and launch new instance from master AMI 

make sure to choose `JenkinsEC2Profile` as instance profile

make sure to choose correct security group to allow access to git instance (TSG Jenkins Instances)

### Verify
Log into your AWS console, and check for master EC2 instance. you should be able to access http://your.master.server.ip:8080 with admin/admin credentials.

###
After you verify jenkins, change route53 domain to start pointing to your new instance.

## Built With

* [Packer](https://www.packer.io/docs/) - Open source tool for creating identical machine images for multiple platforms. 
* [AWS Cli](https://aws.amazon.com/cli/) - The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services.

## Authors

* **Manukyan Vahram** 