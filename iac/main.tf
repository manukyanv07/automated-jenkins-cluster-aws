terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "jenkins-master" {
  most_recent = true
  owners = [
    "self"]

  filter {
    name = "name"
    values = [
      "jenkins-master-1.0"]
  }
}

data "aws_ami" "jenkins-slave" {
  most_recent = true
  owners = [
    "self"]

  filter {
    name = "name"
    values = [
      "jenkins-worker-1.0"]
  }
}

variable "key_name" {
  default = "jenkins-server"
}
variable "jenkins_master_instance_type" {
  default = "t2.micro"
}

resource "aws_security_group" "jenkins_master_sg" {
  name = "jenkins-master-sg"
  vpc_id = ""
  ingress {
    # TLS (change to whatever ports you need)
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    # TLS (change to whatever ports you need)
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    # TLS (change to whatever ports you need)
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    # TLS (change to whatever ports you need)
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  tags = {
    Name = "allow_all"
  }
}

resource "aws_instance" "jenkins_master" {
  ami = "${data.aws_ami.jenkins-master.id}"
  instance_type = "${var.jenkins_master_instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.jenkins_master_sg.id}"]
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }
}

// Jenkins slaves launch configuration
resource "aws_launch_configuration" "jenkins_slave_launch_conf" {
  name = "jenkins_slaves_config"
  image_id = "${data.aws_ami.jenkins-slave.id}"
  instance_type = "t2.micro"
  spot_price = "0.0035"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.jenkins_master_sg.id}"]
  user_data = "${data.template_file.user_data_slave.rendered}"
  root_block_device {
    volume_type = "gp2"
    volume_size = 30
    delete_on_termination = false
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a new load balancer
resource "aws_elb" "jenkins_elb" {
  name = "jenkins-elb"
  availability_zones = [
    "us-east-1a",
    "us-east-1b"]


  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 8080
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8000/"
    interval = 30
  }

  cross_zone_load_balancing = false
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags = {
    Name = "jenkins-terraform-elb"
  }
}

// ASG Jenkins slaves
resource "aws_autoscaling_group" "jenkins_slaves" {
  name = "jenkins_slaves_asg"
  launch_configuration = "${aws_launch_configuration.jenkins_slave_launch_conf.name}"
  min_size = "1"
  max_size = "5"
  availability_zones = [
    "us-east-1a",
    "us-east-1b"]
  depends_on = [
    aws_instance.jenkins_master,
    aws_elb.jenkins_elb]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key = "Name"
    value = "jenkins_slave"
    propagate_at_launch = true
  }
  tag {
    key = "Author"
    value = "mlabouardy"
    propagate_at_launch = true
  }
  tag {
    key = "Tool"
    value = "Terraform"
    propagate_at_launch = true
  }
}

data "template_file" "user_data_slave" {
  template = "${file("join-cluster.sh")}"
  depends_on = [aws_instance.jenkins_master]
  vars = {
    jenkins_url = "http://${aws_instance.jenkins_master.private_ip}:8080"
    jenkins_username = "admin"
    jenkins_password = "admin"
    jenkins_credentials_id = "jenkins-slaves"
  }
}

// Scale out
resource "aws_cloudwatch_metric_alarm" "high-cpu-jenkins-slaves-alarm" {
  alarm_name = "high-cpu-jenkins-slaves-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.scale-out.arn}"]
}
resource "aws_autoscaling_policy" "scale-out" {
  name = "scale-out-jenkins-slaves"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}
// Scale In
resource "aws_cloudwatch_metric_alarm" "low-cpu-jenkins-slaves-alarm" {
  alarm_name = "low-cpu-jenkins-slaves-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.jenkins_slaves.name}"
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.scale-in.arn}"]
}
resource "aws_autoscaling_policy" "scale-in" {
  name = "scale-in-jenkins-slaves"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.jenkins_slaves.name}"
}
