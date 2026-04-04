provider "aws" {
    region = "us-east-1"
}

resource "aws_eip" "my_ip" {
    tags = {
        Name = "CloudLaunch-EIP"
    }
}

output "eip_ip" {
    value = aws_eip.my_ip.id
}

output "public_ip" {
    value = aws_eip.my_ip.public_ip
}