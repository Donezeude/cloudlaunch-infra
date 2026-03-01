data "http" "my_ip" {
    url = "https://api.ipify.org"
}


provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "cloudlaunch" {
    ami                     = "ami-0f9c27b471bdcd702" # Debian 13 // user: admin
    instance_type           = "t3.micro"
    key_name                = "my-key-pair"
    vpc_security_group_ids  = [aws_security_group.allowed_access.id]

    tags = {
        Name        = "CloudLaunch"
    }
}

resource "aws_security_group" "allowed_access" {
    name = "allowed_access"
    description = "ingress:SSH-HTTP-HTTPS-FLASK_API"

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

output "instance-public-ip" {
    value       = aws_instance.cloudlaunch.public_ip
    description = "EC2 Instance Public IP"
}

# TODO: in ansible make sure you add an output command that sends this information to Inventory.ini inside the ansible folder