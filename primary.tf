resource "aws_instance" "primary" {
  # The number of primaries must be hard coded to 3 when Internal Production Mode
  # is selected. Currently, that mode does not support scaling. In other modes, the 
  # cluster can be scaled according the primary_count variable.
  count = "${var.install_type == "ipm" ? 3 : var.primary_count}"

  ami           = "${var.ami != "" ? var.ami : local.distro_ami}"
  instance_type = "${var.primary_instance_type}"

  subnet_id = "${element(module.common.public_subnets, count.index)}"

  vpc_security_group_ids = [
    ## ingress from lb
    "${module.lb.sg_lb_to_instance}",

    ## unrestricted egress
    "${module.common.intra_vpc_and_egress_sg_id}",

    "${module.common.allow_ptfe_sg_id}",
  ]

  iam_instance_profile = "${aws_iam_instance_profile.ptfe.name}"

  key_name = "${module.common.ssh_key_name}"

  user_data = "${element(data.template_cloudinit_config.config.*.rendered, count.index)}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
  }

  tags {
    Name           = "${var.prefix}-${module.common.install_id}:primary"
    InstallationId = "${module.common.install_id}"
  }
}

resource "aws_elb_attachment" "ptfe_app-primary" {
  count    = "${var.primary_count}"
  elb      = "${aws_elb.cluster_api.id}"
  instance = "${element(aws_instance.primary.*.id, count.index)}"
}

resource "aws_elb_attachment" "ptfe_admin-primary" {
  count    = "${var.primary_count}"
  elb      = "${aws_elb.cluster_api.id}"
  instance = "${element(aws_instance.primary.*.id, count.index)}"
}

resource "aws_elb_attachment" "cluster_api-primary" {
  count    = "${var.primary_count}"
  elb      = "${aws_elb.cluster_api.id}"
  instance = "${element(aws_instance.primary.*.id, count.index)}"
}

resource "aws_elb_attachment" "cluster_assistant-primary" {
  count    = "${var.primary_count}"
  elb      = "${aws_elb.cluster_api.id}"
  instance = "${element(aws_instance.primary.*.id, count.index)}"
}

resource "aws_lb_target_group_attachment" "admin-primary" {
  count            = "${var.primary_count}"
  target_group_arn = "${module.lb.admin_group}"
  target_id        = "${aws_instance.primary.*.id[count.index]}"
}

resource "aws_lb_target_group_attachment" "https-primary" {
  count            = "${var.primary_count}"
  target_group_arn = "${module.lb.https_group}"
  target_id        = "${aws_instance.primary.*.id[count.index]}"
}
