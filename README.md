# Lustre (Terraform)

This Terraform module is derived from the [open-source deployment-manager samples repository from Google Cloud](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/lustre). Fluid Numerics has updated the [startup-script](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/lustre/scripts/startup-script.sh) to pass certain variables through instance metadata.


## Getting Started
To use this Lustre on Google Cloud, you need to first create a Virtual Machine Image that has Lustre, E2FS, and HSM installed (along with their dependencies). This is done using Google Cloud Build, Packer, and an install script provided for you under the [`img/`](./img) subdirectory. To bake the VM image on Google Cloud, make sure that you [enable Google Cloud Build and Google Compute Engine](https://console.cloud.google.com/flows/enableapi?apiid=cloudbuild.googleapis.com,compute.googleapis.com). Additionally, you will need to provide the Google Cloud Build service account the `Compute Admin` and `Service Account User` IAM roles.

Then, you can create the VM image using the following command :
```
gcloud builds submit . --config=img/cloudbuild.yaml
```

After the image has been created, you can quickly create a Lustre cluster using the following commands from the root directory of this repository :
```
make plan
make apply
```


## Dependencies
* [Terraform 0.14.0 or greater](https://www.terraform.io/downloads.html)

## Resources
* [A great resource for learning about the Lustre architecture](http://wiki.lustre.org/Introduction_to_Lustre)
* [Lustre Tuning](http://wiki.lustre.org/Lustre_Tuning)
* [HSM Overview](https://www.seagate.com/files/www-content/solutions-content/cloud-systems-and-solutions/high-performance-computing/_shared/docs/clusterstor-inside-lustre-hsm-ti.pdf)

