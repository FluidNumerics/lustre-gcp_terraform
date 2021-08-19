
locals {

  max_gb_per_vm = 263168
  max_gb_per_pd = 64000
  max_gb_per_localssd = 9000
 
  mds_node_count = var.create_lustre ? var.mds_node_count : 0
  hsm_node_count = var.create_lustre ? var.hsm_node_count : 0
  oss_node_count = var.create_lustre ? var.oss_node_count : 0

  mdt_per_mds = var.mdt_disk_type == "local-ssd" ? ceil(var.mdt_disk_size_gb/375) : var.mdt_per_mds
  ost_per_oss = var.ost_disk_type == "local-ssd" ? ceil(var.ost_disk_size_gb/375) : var.ost_per_oss

}

resource "google_compute_disk" "mdt" {
  count = var.mdt_disk_type == "local-ssd" ? 0 : local.mds_node_count*local.mdt_per_mds
  name = "${var.cluster_name}-mdt${count.index}"
  type = var.mdt_disk_type
  zone = var.zone
  size = var.mdt_disk_size_gb 
  project = var.project
}

resource "google_compute_instance" "mds" {
  count = local.mds_node_count
  name = "${var.cluster_name}-mds${count.index}"
  project = var.project
  machine_type = var.mds_machine_type
  zone = var.zone
  tags = var.network_tags
  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.image
      size = var.mds_boot_disk_size_gb
      type = var.mds_boot_disk_type
    }
  }

  // Forcing this to only permit one mdt per mds when using PD disk
  dynamic "attached_disk" {
    for_each = var.mdt_disk_type == "local-ssd" ? [] : [1]
    content {
      source = google_compute_disk.mdt[count.index].self_link 
      device_name = "mdt"
    }
  }

  dynamic "scratch_disk" {
    for_each = var.mdt_disk_type == "local-ssd" ? range(local.mdt_per_mds) : []
    content {
      interface = "NVME"
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup-script.sh")
  metadata = {
    cluster-name = var.cluster_name
    fs-name = var.fs_name
    node-role = "MDS"
    hsm-gcs = var.hsm_gcs_bucket
    hsm-gcs-prefix = var.hsm_gcs_prefix
    mdt_per_mds = local.mdt_per_mds
    ost_per_oss = local.ost_per_oss
    mdt_disk_type = var.mdt_disk_type
    ost_disk_type = var.ost_disk_type
    enable-oslogin = "TRUE"
  }
  network_interface {
    subnetwork  = var.vpc_subnet
    access_config {
    }
  }
  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true
}


// OSS
resource "google_compute_disk" "ost" {
  count = var.ost_disk_type == "local-ssd" ? 0 : local.oss_node_count*local.ost_per_oss
  name = "${var.cluster_name}-ost${count.index}"
  type = var.ost_disk_type
  zone = var.zone
  size = var.ost_disk_size_gb 
  project = var.project
}

resource "google_compute_instance" "oss" {
  count = local.oss_node_count
  name = "${var.cluster_name}-oss${count.index}"
  project = var.project
  machine_type = var.oss_machine_type
  zone = var.zone
  tags = var.network_tags
  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.image
      size = var.oss_boot_disk_size_gb
      type = var.oss_boot_disk_type
    }
  }

  // Forcing this to only permit one mdt per mds when using PD disk
  dynamic "attached_disk" {
    for_each = var.ost_disk_type == "local-ssd" ? [] : [1]
    content {
      source = google_compute_disk.ost[count.index].self_link 
      device_name = "ost"
    }
  }

  dynamic "scratch_disk" {
    for_each = var.ost_disk_type == "local-ssd" ? range(local.ost_per_oss) : []
    content {
      interface = "NVME"
    }
  }

  metadata_startup_script = file("${path.module}/scripts/startup-script.sh")
  metadata = {
    cluster-name = var.cluster_name
    fs-name = var.cluster_name
    node-role = "OSS"
    hsm-gcs = var.hsm_gcs_bucket
    hsm-gcs-prefix = var.hsm_gcs_prefix
    mdt_per_mds = local.mdt_per_mds
    ost_per_oss = local.ost_per_oss
    mdt_disk_type = var.mdt_disk_type
    ost_disk_type = var.ost_disk_type
    enable-oslogin = "TRUE"
  }
  network_interface {
    subnetwork  = var.vpc_subnet
    access_config {
    }
  }
  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true
}

resource "google_compute_instance" "hsm" {
  count = local.hsm_node_count
  name = "${var.cluster_name}-hsm${count.index}"
  project = var.project
  machine_type = var.hsm_machine_type
  zone = var.zone
  tags = var.network_tags
  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.image
      size = 20
      type = "pd-standard"
    }
  }
  metadata_startup_script = file("${path.module}/scripts/startup-script.sh")
  metadata = {
    cluster-name = var.cluster_name
    fs-name = var.cluster_name
    node-role = "HSM"
    hsm-gcs = var.hsm_gcs_bucket
    hsm-gcs-prefix = var.hsm_gcs_prefix
    mdt_per_mds = var.mdt_per_mds
    ost_per_oss = var.ost_per_oss
    mdt_disk_type = var.mdt_disk_type
    ost_disk_type = var.ost_disk_type
    enable-oslogin = "TRUE"
  }
  network_interface {
    subnetwork  = var.vpc_subnet
    access_config {
    }
  }
  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true
}
