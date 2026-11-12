resource "aws_iam_instance_profile" "ec2" {
  name = "terraform-infra-ec2iam-profile"
  role = "ec2iam"
}

resource "aws_launch_template" "web" {
  name_prefix   = "terraform-infra-web-"
  image_id      = data.aws_ami.rhel_9.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instances.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    dnf install -y nginx
    printf '%s\n' '<h1>RHEL web server</h1>' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform-infra-web"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "terraform-infra-web"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.private.id]
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  depends_on = [aws_route_table_association.private]

  tag {
    key                 = "Name"
    value               = "terraform-infra-web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "terraform-infra-cpu-target"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web.name

  target_tracking_configuration {
    target_value = 50

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}
