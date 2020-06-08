
# All
variable "role" { default = "" }
variable "servers" { default = 0 }
variable "templates" { default = [] }
variable "destinations" { default = [] }
variable "aws_bucket_region" { default = "" }
variable "aws_bucket_name" { default = "" }
variable "remote_exec" { default = [] }
variable "public_ips" { default = [] }

#Admin
variable "gitlab_backups_enabled" { default = false }

#DB
variable "num_dbs" { default = 0 }
variable "redis_dbs" { default = [] }
variable "mongo_dbs" { default = [] }
variable "pg_dbs" { default = [] }
variable "pg_fn" { default = "" }

#Leader
variable "run_service" { default = false }
variable "send_logs" { default = false }
variable "send_jsons" { default = false }
# TempLeader
variable "docker_service_name" { default = "" }
variable "consul_service_name" { default = "" }
variable "folder_location" { default = "" }
variable "logs_prefix" { default = "" }
variable "email_image" { default = "" }
variable "service_repo_name" { default = "" }

variable "prev_module_output" {}


# TODO: Dynamically make crontab/file based on multiple roles/cron files
#   ie, Admin and Leader; Leader and DB; Admin, Leader, and DB should be able to coexist on single server
resource "null_resource" "admin" {
    count      = var.role == "admin" ? var.servers : 0

    triggers = {
        wait_for_prev_module = "${join(",", var.prev_module_output)}"
    }

    provisioner "remote-exec" {
        inline = [ "mkdir -p /root/code/cron" ]
    }

    provisioner "file" {
        content = fileexists("${path.module}/templates/${var.templates["admin"]}") ? templatefile("${path.module}/templates/${var.templates["admin"]}", {
            gitlab_backups_enabled = var.gitlab_backups_enabled
            aws_bucket_region = var.aws_bucket_region
            aws_bucket_name = var.aws_bucket_name
        }) : ""
        destination = var.destinations["admin"]
    }

    provisioner "remote-exec" {
        inline = var.remote_exec
    }
    connection {
        host = element(var.public_ips, count.index)
        type = "ssh"
    }
}


# TODO: Create a scaleable resource for multiple dbs then create separate resource to combine
#  the files into a single crontab (this can be said for this entire module as illustrated
#  by their similarities, but for now 1 module with several specific resources. Steps)
resource "null_resource" "db" {
    count      = var.role == "db" ? var.servers : 0

    triggers = {
        num_dbs = var.num_dbs
        wait_for_prev_module = "${join(",", var.prev_module_output)}"
    }

    provisioner "remote-exec" {
        inline = [ "mkdir -p /root/code/cron" ]
    }

    provisioner "file" {
        # TODO: aws_bucket_name and region based off imported db's options
        content = fileexists("${path.module}/templates/${var.templates["redisdb"]}") ? templatefile("${path.module}/templates/${var.templates["redisdb"]}", {
            aws_bucket_region = var.aws_bucket_region
            aws_bucket_name = var.aws_bucket_name
            redis_dbs = length(var.redis_dbs) > 0 ? var.redis_dbs : []
        }) : ""
        destination = var.destinations["redisdb"]
    }

    provisioner "file" {
        # TODO: aws_bucket_name and region based off imported db's options
        content = fileexists("${path.module}/templates/${var.templates["mongodb"]}") ? templatefile("${path.module}/templates/${var.templates["mongodb"]}", {
            aws_bucket_region = var.aws_bucket_region
            aws_bucket_name = var.aws_bucket_name
            mongo_dbs = length(var.mongo_dbs) > 0 ? var.mongo_dbs : []
            host = "vpc.my_private_ip"  # TODO: Add ability to specific host/hostnames/ip
        }) : ""
        destination = var.destinations["mongodb"]
    }

    provisioner "file" {
        # TODO: aws_bucket_name and region based off imported db's options
        content = fileexists("${path.module}/templates/${var.templates["pgdb"]}") ? templatefile("${path.module}/templates/${var.templates["pgdb"]}", {
            aws_bucket_region = var.aws_bucket_region
            aws_bucket_name = var.aws_bucket_name
            pg_dbs = length(var.pg_dbs) > 0 ? var.pg_dbs : []
            pg_fn = length(var.pg_fn) > 0 ? var.pg_fn : "" # TODO: hack
        }) : ""
        destination = var.destinations["pgdb"]
    }

    provisioner "remote-exec" {
        inline = var.remote_exec
    }

    connection {
        host = element(var.public_ips, count.index)
        type = "ssh"
    }
}



resource "null_resource" "leader" {
    count      = var.role == "lead" ? var.servers : 0

    triggers = {
        wait_for_prev_module = "${join(",", var.prev_module_output)}"
    }

    provisioner "remote-exec" {
        inline = [ "mkdir -p /root/code/cron" ]
    }

    provisioner "file" {
        content = fileexists("${path.module}/templates/${var.templates["leader"]}") ? templatefile("${path.module}/templates/${var.templates["leader"]}", {
            run_service = var.run_service
            send_logs = var.send_logs
            send_jsons = var.send_jsons
            aws_bucket_name = var.aws_bucket_name
            aws_bucket_region = var.aws_bucket_region
            check_ssl = count.index == 0 ? true : false

            # Temp
            docker_service_name = var.docker_service_name
            consul_service_name = var.consul_service_name
            folder_location = var.folder_location
            logs_prefix = var.logs_prefix
            email_image = var.email_image
            service_repo_name = var.service_repo_name

        }) : ""
        destination = var.destinations["leader"]
    }

    provisioner "remote-exec" {
        inline = var.remote_exec
    }

    connection {
        host = element(var.public_ips, count.index)
        type = "ssh"
    }
}


output "output" {
    depends_on = [
        null_resource.admin,
        null_resource.db,
        null_resource.leader,
    ]
    value = concat(null_resource.admin.*.id, null_resource.db.*.id, null_resource.leader.*.id)
}
