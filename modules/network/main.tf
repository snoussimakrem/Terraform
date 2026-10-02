locals {
  # { "us-east-1a" = 0, "us-east-1b" = 1 }. Stable keys => adding an AZ never re-addresses others.
  az_index      = { for i, az in var.azs : az => i }
  public_cidrs  = { for az, i in local.az_index : az => cidrsubnet(var.cidr_block, var.subnet_newbits, i) }
  private_cidrs = { for az, i in local.az_index : az => cidrsubnet(var.cidr_block, var.subnet_newbits, i + 8) }
  nat_azs       = var.enable_nat ? (var.single_nat_gateway ? [var.azs[0]] : var.azs) : []
  web_rules = {
    for p in setproduct(var.allowed_ingress_cidrs, [80, 443]) :
    "${p[0]}-${p[1]}" => { cidr = p[0], port = p[1] }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.name })

  lifecycle {
    # Lifecycle precondition: fail at PLAN time with a clear message instead of an API error.
    precondition {
      condition     = length(var.azs) == length(distinct(var.azs))
      error_message = "azs must not contain duplicates."
    }
  }
}

# Default SG ships with allow-all-from-self. Adopt it and strip all rules (CIS benchmark).
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-default-locked" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "public" {
  for_each                = local.public_cidrs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false # load balancers get IPs themselves; instances should not
  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${each.key}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

resource "aws_subnet" "private" {
  for_each          = local.private_cidrs
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${each.key}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-public" })
}
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
}
resource "aws_nat_gateway" "this" {
  for_each      = toset(local.nat_azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id # NAT lives in a PUBLIC subnet
  tags          = merge(var.tags, { Name = "${var.name}-${each.key}" })
  depends_on    = [aws_internet_gateway.this] # not referenced, but required ordering (AWS docs)
}

# One private route table per AZ so HA mode can route each AZ to its own NAT.
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}
resource "aws_route" "private_nat" {
  for_each               = var.enable_nat ? aws_subnet.private : {}
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? var.azs[0] : each.key].id
}
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# NACL = stateless second layer for private subnets (security groups are the first, stateful).
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private : s.id]
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress { # return traffic for outbound connections (stateless => must allow ephemeral ports)
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(var.tags, { Name = "${var.name}-private" })
}

resource "aws_security_group" "web" {
  name        = "${var.name}-web"
  description = "HTTP/HTTPS from approved CIDRs only"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-web" })
  lifecycle { create_before_destroy = true } # SGs are referenced by ENIs; replace without a gap
}
resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each          = local.web_rules
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = "Allow ${each.value.port} from ${each.value.cidr}"
}
resource "aws_vpc_security_group_egress_rule" "web" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = var.cidr_block
  ip_protocol       = "-1"
  description       = "Web tier may only talk inside the VPC"
}

resource "aws_security_group" "internal" {
  name        = "${var.name}-internal"
  description = "Members talk freely to each other, nobody else"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-internal" })
  lifecycle { create_before_destroy = true }
}
resource "aws_vpc_security_group_ingress_rule" "internal_self" {
  security_group_id            = aws_security_group.internal.id
  referenced_security_group_id = aws_security_group.internal.id
  ip_protocol                  = "-1"
  description                  = "Self-referencing: only members of this SG"
}
resource "aws_vpc_security_group_egress_rule" "internal_all" {
  security_group_id = aws_security_group.internal.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Egress is controlled by routing (NAT or none)"
}
