data "http" "my_ip" {
    url = "https://api.ipify.org"
}

provider "aws" {
    region = "us-east-1"
}

variable "my_eip" {}

resource "aws_eip_association"  "attach_ip" {
    instance_id = aws_instance.cloudlaunch.id
    allocation_id = var.my_eip
}

resource "aws_instance" "cloudlaunch" {
    ami                     = "ami-0030e4319cbf4dbf2" # Ubuntu Server 22.04 LTS // user: ubuntu
    instance_type           = "t3.micro"
    key_name                = "my-key-pair"
    vpc_security_group_ids  = [aws_security_group.allowed_access.id]
    iam_instance_profile    = aws_iam_instance_profile.cloudlaunch_profile.name
    monitoring              = true

    tags = {
        Name        = "CloudLaunch"
    }
}

resource "aws_iam_role" "cloudlaunch_role" {
    name = "cloudlaunch-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
    role        = aws_iam_role.cloudlaunch_role.name
    policy_arn  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudlaunch_profile" {
    name    = "cloudlaunch-profile"
    role    = aws_iam_role.cloudlaunch_role.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
    alarm_name          = "cloudlaunch-high-cpu"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 80
    alarm_description   = "Triggers when CPU exceeds 80% for 10 minutes"

    dimensions = {
        Instance        = aws_instance.cloudlaunch.id
    }
}

resource "aws_security_group" "allowed_access" {
    name = "allowed_access"
    description = "ingress:SSH-HTTP-HTTPS-FLASK_API-PING(ICMP)"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }
    ingress {
        from_port   = 5000
        to_port     = 5000
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }
    ingress {
        from_port   = 5001
        to_port     = 5001
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    }
    ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] 
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allowed_access"
    }
}

# output "instance-public-ip" {
#     value       = aws_eip.cloudlaunch_ip.public_ip
#     description = "EC2 Instance Public IP"
# }

# TODO: in ansible make sure you add an output command that sends this information to Inventory.ini inside the ansible folder