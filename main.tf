
//store public key in aws console
resource "aws_key_pair" "tf-key" {
  key_name   = "tf-key"
   public_key = tls_private_key.rsa.public_key_openssh
}
//generate ssh keys using rsa algorithm
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
//store private key in local system
resource "local_file" "tf-key" {
    content = tls_private_key.rsa.private_key_pem
    filename = "tfkey"
}

//Create AWS linux instance
resource "aws_instance" "demo"{
    ami = var.ami
    instance_type = var.instance_type
    //count = var.instance_count
    key_name = "tf-key"
   associate_public_ip_address = true
    security_groups=["${aws_security_group.allow_http_SSH.name}"]
    user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install ansible2 -y
    sudo yum install -y git
    git clone https://github.com/Kavya5991/sample-python-web-app.git /home/ec2-user/app
    chmod +x /home/ec2-user/app/nginx.yml
    ansible-playbook -i localhost /home/ec2-user/app/nginx.yml
    //ansible-playbook -i localhost /home/ec2-user/app/python_deploy.yml
    EOF

tags= {
        Name = "Task"

    }
    
  }

//create Elastic IP
resource "aws_eip" "eip"{
    vpc = true
}
//Attach Elastic IP to instance
resource "aws_eip_association" "eip_associate" {
    depends_on = [aws_instance.demo, aws_eip.eip]
    //count = var.instance_count
    instance_id = aws_instance.demo.id
    allocation_id = aws_eip.eip.id
}
resource "aws_security_group" "allow_http_SSH" {
  name        = "ALLOW_HTTP_SSH"
  description = "Allow http inbound traffic"


  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "ALLOW_http_SSH"
  }
}

//resource "null_resource" "wait-for-instance" {
 // depends_on = [aws_instance.demo]
  // provisioner "local-exec" {
   //  command="sleep 120" 
 //}
//}

//output "instance_public_ip" {
  //value = aws_instance.demo.public_ip
//}

//# Use remote-exec provisioner to run a command on the instance
//resource "null_resource" "ssh_command" {
  //provisioner "local-exec" {
    //command = "ansible-playbook -i ${aws_instance.demo.public_ip}, --user ec2-user --private-key tfkey nginx.yml"
  //}
//}



  
