provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_key_pair" "nodejs" {
  key_name   = "nodejs-key"
  public_key = "${var.ssh_key}"
}

resource "aws_security_group" "nodejs_sec_group" {
  name        = "nodejs_sec_group"
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  # HTTP access from anywhere
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "nodejs" {
  name = "nodejs-elb"

  # The same availability zone as our instance
  availability_zones = ["us-east-2b"]
  security_groups = ["${aws_security_group.elb.id}"]


  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 5000
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 30
  }

  # The instance is registered automatically

  instances                   = ["${aws_instance.nodejs.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

#data "template_file" "script" {
#  template = "${file("${path.module}/app_build_install.tpl")}"
#}
#
#data "template_cloudinit_config" "config" {
#  gzip          = true
#  base64_encode = true
#  part {
#    filename     = "init.cfg"
#    content_type = "text/x-shellscript"
#    content      = "${data.template_file.script.rendered}"
#  }
#}


resource "aws_instance" "nodejs" {
  ami           = "ami-e0eac385"
  instance_type = "t2.micro"
  security_groups = ["nodejs_sec_group"]
  key_name = "nodejs-key"
#  user_data = "${data.template_cloudinit_config.config.rendered}"
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
    inline = [
      "sudo yum install -y git;",
      "git clone https://github.com/vnaboychenko/nodejs-test.git;",
      "sudo bash nodejs-test/build/build.sh;",
      "sudo puppet apply -t nodejs-test/install/install.pp;",
      "exit 0"
    ]
  }
}
