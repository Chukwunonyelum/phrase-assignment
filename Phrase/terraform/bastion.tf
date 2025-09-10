

resource "aws_instance" "bastion" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true # Make sure it gets public IP
   

  tags = {
    Name = "bastion"
  }
}

# Generate inventory.ini dynamically with private IPs of NGINX instances
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    bastion_ip = aws_instance.bastion.public_ip  # Use actual IP
    private_key_path = var.private_key_path
  })
  filename = "${path.module}/ansible/inventory.ini"
}

# Generate ansible.cfg so Ansible always uses Bastion as jump host
resource "local_file" "ansible_cfg" {
  filename = "${path.module}/../ansible/ansible.cfg"
  content  = templatefile("${path.module}/../ansible/ansible.cfg.tpl", {
    bastion_ip = aws_instance.bastion.public_ip
  })
}


resource "null_resource" "ansible_provision" {
  depends_on = [
    local_file.ansible_inventory,  # Fixed: was "inventory", now "ansible_inventory"
    local_file.ansible_cfg,
    aws_instance.bastion
    # Remove or comment out aws_autoscaling_group.nginx_asg if it doesn't exist
  ]
  
  provisioner "local-exec" {
    interpreter = ["wsl", "-d", "Ubuntu", "-u", "root", "--", "bash", "-c"]
    command = "cd /mnt/c/Users/MAYOR/Phrase/ansible && ansible-playbook -i inventory.ini playbook.yml"
  }
  
  triggers = {
    bastion_id = aws_instance.bastion.id
  }
}


# Bastion SG: allow SSH from your IP
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  name   = "bastion-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


