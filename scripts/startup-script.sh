#!/bin/bash
#
# Adapted from https://github.com/GoogleCloudPlatform/deploymentmanager-samples.git
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Imported variables from lustre.jinja, do not modify
CLUSTER_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-name" -H "Metadata-Flavor: Google")
MDS_HOSTNAME="${CLUSTER_NAME}-mds0"
FS_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/fs-name" -H "Metadata-Flavor: Google")
NODE_ROLE=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/node-role" -H "Metadata-Flavor: Google")
HSM_GCS_BUCKET=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/hsm-gcs" -H "Metadata-Flavor: Google")
HSM_GCS_BUCKET_IMPORT=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/hsm-gcs-prefix" -H "Metadata-Flavor: Google")

ost_mount_point="/mnt/ost"
mdt_mount_point="/mnt/mdt"
mdt_per_mds=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mdt_per_mds" -H "Metadata-Flavor: Google")
ost_per_oss=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/ost_per_oss" -H "Metadata-Flavor: Google")
mdt_disk_type=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/mdt_disk_type" -H "Metadata-Flavor: Google")
ost_disk_type=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/ost_disk_type" -H "Metadata-Flavor: Google")

#Set Message of the Day to show Lustre cluster information and declare the Lustre installation complete
function end_motd() {
	echo -e "Welcome to the Google Cloud Lustre Deployment!\nLustre MDS: $MDS_HOSTNAME\nLustre FS Name: $FS_NAME\nMount Command: mount -t lustre $MDS_HOSTNAME:/$FS_NAME <local dir>" > /etc/motd
	wall -n "*** Lustre installation is complete! *** "
	wall -n "`cat /etc/motd`"
}


function configure_lemur() {
	#Lemur Agent Configuration
	mkdir -p /var/lib/lhsmd/roots

	cat > /etc/lhsmd/agent << EOF
## The mount target for the Lustre file system that will be used with this agent.
##
client_device=  "${MDS_HOSTNAME}@tcp:/lustre"

##
## Base directory used for the Lustre mount points created by the agent
##
mount_root= "/var/lib/lhsmd/roots"

##
## List of enabled plugins
##
enabled_plugins = ["lhsm-plugin-gcs"]

##
## Directory to look for the plugins
##
plugin_dir = "/usr/libexec/lhsmd"

##
## Number of threads handling incoming HSM requests.
##
handler_count = 8

##
## Enable experimental snapshot feature.
##
snapshots {
     enabled = false
}

EOF

	#Lemur GCS Plugin Conf
	cat > /etc/lhsmd/lhsm-plugin-gcs << EOF
## Credentials file in Json format from the service account (Optional)
#service_account_key="[SA_NAME-key.json]"

## Maximum number of concurrent copies.
##
num_threads=8

##
## One or more archive definition is required.
##
archive "1" {
        id = 1
        bucket = "${HSM_GCS_BUCKET:5}"
}
EOF

	chmod 600 /etc/lhsmd/lhsm-plugin-gcs

	#Start lhsm agent daemon
	systemctl start lhsmd


}

function hsm_import_bucket()
{

	bucket_file_list=`gsutil ls -r ${HSM_GCS_BUCKET_IMPORT}/** | sed "/\/:$/d"`

	for i in $bucket_file_list
	do
		# Convert to destination file full path
		dest_file_name=`echo ${i} | sed "s%${HSM_GCS_BUCKET_IMPORT}%/mnt/%g"`
		dir_name=`dirname ${dest_file_name}`

		if [ ! -d ${dir_name} ]; then
			mkdir -p ${dir_name}
		fi

		src_file_name=`echo $i | sed "s%gs://.[^/]*/%%g"`
		lhsm import --uuid ${src_file_name} --uid 0 --gid 0 ${dest_file_name}

	done
}

function main() {

	# Load the Lustre kernel modules
	modprobe lustre
	
	# Get the hostname index (trailing digit on the hostname) 
	host_index=`hostname | grep -o -e '[[:digit:]]*' | tail -1`
	# Decrement the index by 1 to convert to Lustre's indexing
	if [ ! $host_index ]; then
		host_index=0
	#else
        #		let host_index=$host_index-1
	fi

	# If the local node running this script is a Lustre MDS, install the MDS/MGS software
	if [ "$NODE_ROLE" == "MDS" ]; then
		# Do LCTL ping to the OSS nodes and sleep until LNET is up and we get a response
		while [ `sudo lctl ping ${CLUSTER_NAME}-oss1 | grep -c "Input/output error"` -gt 0 ]; do
			sleep 10
		done

		let index=$host_index*$mdt_per_mds
		if [ "$mdt_disk_type" == "local-ssd" ]; then
			disks=$(ls /dev/nvme0n*)
		else
			disks=$(ls /dev/sd* | grep -v sda[0-9]*$ )
		fi
		for lustre_device in $disks; do
			# Make the MDT mount and mount the device
			mkdir $mdt_mount_point$index
			if [[ "$MDS_HOSTNAME" == $(hostname) && ${index} == 0 ]]; then
				# Create the first mdt as the mgs of the cluster
				mkfs.lustre --mdt --mgs --index=${index} --fsname=${FS_NAME} --mgsnode=${MDS_HOSTNAME} $lustre_device
				# Sleep 60 seconds to give MGS time to come up 
				sleep 60
			else
				mkfs.lustre --mdt --index=${index} --fsname=${FS_NAME} --mgsnode=${MDS_HOSTNAME} $lustre_device
			fi
			echo "$lustre_device	$mdt_mount_point$index	lustre" >> /etc/fstab
			mount $mdt_mount_point$index
			
			if [ $? -ne 0 ]; then
				echo -e "MDT device \"$lustre_device\" mount to \"$mdt_mount_point$index\" has failed. Please try mounting manually with \"mount -t lustre $mdt_mount_point$index\", or reboot this node."
				#exit 1
			fi
			let index=$index+1
		done

                # Enable lustre server-side read cache
		lctl set_param osd-*.*.read_cache_enable=1

		# Enable HSM on the Lustre MGS
		lctl set_param -P mdt.*-MDT0000.hsm_control=enabled

		# Setup the archive id for the specific HSM backend, we are only using 1 so id=1 is just fine
		lctl set_param -P mdt.*-MDT0000.hsm.default_archive_id=1

		# Increase the number of HSM Max requests on the MDT, you may want to
		# experiment with various values if you intend to go to production
		lctl set_param mdt.*-MDT0000.hsm.max_requests=128

		# Disable the authentication upcall by default, change if using auth
		echo NONE > /proc/fs/lustre/mdt/lustre-MDT0000/identity_upcall
	# If the local node running this script is a Lustre OSS, install the OSS software
	elif [ "$NODE_ROLE" == "OSS" ]; then
		# Do LCTL ping to the OSS nodes and sleep until LNET is up and we get a response 
		while [ `sudo lctl ping ${MDS_HOSTNAME} | grep -c "Input/output error"` -gt 0 ]; do
			sleep 5
		done

		# Sleep 60 seconds to give MDS/MGS time to come up before the OSS. More robust communication would be good.
		sleep 60

		# Make the Lustre OST
		let index=$host_index*$ost_per_oss
		echo "INDEX = $index" >> /lustre/install.log
		echo "OST_PER_OSS = $ost_per_oss" >> /lustre/install.log
		if [ "$ost_disk_type" == "local-ssd" ]; then
			disks=$(ls /dev/nvme0n*)
		else
			disks=$(ls /dev/sd* | grep -v sda[0-9]*$ )
		fi
		for lustre_device in $disks; do
		#for lustre_device in $(ls /dev/sd* | grep -v sda[0-9]*$ ); do
			echo "DEVICE = $lustre_device" >> /lustre/install.log
			# Make the directory to mount the OST, and mount the OST
			mkdir $ost_mount_point$index
			mkfs.lustre --ost --index=${index} --fsname=${FS_NAME} --mgsnode=${MDS_HOSTNAME} $lustre_device
			echo "$lustre_device	$ost_mount_point$index	lustre" >> /etc/fstab
			
			let index=$index+1
		done
		
		# Mount OST devices
		sleep 20
		mount -a
		if [ `mount | grep -c $ost_mount_point` -eq 0 ]; then
			echo "OST mount has failed. Please try mounting manually with \"mount -a\", or reboot this node." >> /lustre/install.log
			#exit 1
		fi

	# If the local node running this script is a Lustre HSM Data Mover, install the Lemur software
	elif [ "$NODE_ROLE" == "HSM" ]; then
		# Do LCTL ping to the OSS nodes and sleep until LNET is up and we get a response 
		while [ `sudo lctl ping ${MDS_HOSTNAME} | grep -c "Input/output error"` -gt 0 ]; do
			sleep 10
		done

		mount_status=1

		while [ ${mount_status} -ne 0 ]; do
			mount -t lustre ${MDS_HOSTNAME}:/${FS_NAME} /mnt
			mount_status=$?
		done

		configure_lemur

		if [ ! -z "${HSM_GCS_BUCKET_IMPORT}" ]; then
			hsm_import_bucket
		fi
	fi
	# Mark install.log as reaching stage 2
	sed -i 's/Stage 1//g'
	echo "Stage 2" >> /lustre/install.log
	# Change MOTD to mark install as complete
	end_motd

}
main $@
