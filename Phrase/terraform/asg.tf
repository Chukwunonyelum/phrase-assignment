resource "aws_launch_template" "nginx" {
  name          = "nginx-template"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name      = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(file("${path.module}/userdata.tpl"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Environment = "dev"
      Role        = "nginx"
    }
  }
}



resource "aws_autoscaling_group" "nginx_asg" {
  desired_capacity    = 3
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.nginx_tg.arn]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }

  # Write Ansible inventory after ASG is ready
provisioner "local-exec" {
    command = <<EOT
  echo "[nginx]" > ../ansible/inventory.ini
  for ip in $(aws ec2 describe-instances --filters "Name=tag:Name,Values=nginx-instance" \
          --query "Reservations[*].Instances[*].PrivateIpAddress" \
          --output text --region ${var.aws_region}); do
  echo "$ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/my-key.pem" >> ../ansible/inventory.ini
  done

  echo "[bastion]" >> ../ansible/inventory.ini
  echo "${aws_instance.bastion.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/my-key.pem" >> ../ansible/inventory.ini
  EOT
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.name
  lb_target_group_arn   = aws_lb_target_group.nginx_tg.arn
}




