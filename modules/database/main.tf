############################ k8s mode ############################
resource "kubernetes_secret_v1" "postgres" {
  count = var.mode == "k8s" ? 1 : 0
  metadata {
    name      = "${var.name}-postgres"
    namespace = var.namespace
  }
  # WRITE-ONLY: the password reaches the cluster but not the Terraform state.
  # VERIFY your kubernetes provider version supports data_wo (see docs/VERIFY.md).
  data_wo          = { POSTGRES_PASSWORD = var.password }
  data_wo_revision = var.password_version
}

resource "kubernetes_service_v1" "postgres" {
  count = var.mode == "k8s" ? 1 : 0
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    selector = { app = var.name }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  count = var.mode == "k8s" ? 1 : 0
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = { app = var.name }
  }
  spec {
    service_name = var.name
    replicas     = 1
    selector {
      match_labels = { app = var.name }
    }
    template {
      metadata {
        labels = { app = var.name }
      }
      spec {
        security_context {
          run_as_user  = 70 # postgres user in the alpine image
          run_as_group = 70
          fs_group     = 70
        }
        container {
          name  = "postgres"
          image = var.postgres_image
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_USER"
            value = var.username
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres[0].metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "1", memory = "1Gi" }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.username]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = { storage = var.storage_size }
        }
      }
    }
  }
}

############################ rds mode (paid / plan-only in this project) ############################
resource "aws_db_subnet_group" "this" {
  count      = var.mode == "rds" ? 1 : 0
  name       = var.name
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  count                               = var.mode == "rds" ? 1 : 0
  identifier                          = var.name
  engine                              = "postgres"
  engine_version                      = "16"
  instance_class                      = var.instance_class
  allocated_storage                   = 20
  max_allocated_storage               = 100
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_arn
  db_subnet_group_name                = aws_db_subnet_group.this[0].name
  vpc_security_group_ids              = var.security_group_ids
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  backup_retention_period             = 7
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = !var.deletion_protection
  final_snapshot_identifier           = var.deletion_protection ? "${var.name}-final" : null
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  username                            = var.username
  password_wo                         = var.password # write-only: never in state
  password_wo_version                 = var.password_version
  tags                                = var.tags

  lifecycle {
    prevent_destroy = false # set true in prod copies; see docs/decisions/0006 on replacement strategy
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "RDS subnet groups need subnets in at least two AZs."
    }
  }
}
