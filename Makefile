LUSTRE_PROJECT ?= ""
LUSTRE_ZONE ?= "us-west1-b"
LUSTRE_REGION ?= "us-west1"
LUSTRE_SUBNET ?= "default"

.PHONY: plan apply destroy

fluid.tfvars: template.tfvars
	cp template.tfvars fluid.tfvars
	sed -i "s/<project>/${LUSTRE_PROJECT}/g" fluid.tfvars
	sed -i "s/<zone>/${LUSTRE_ZONE}/g" fluid.tfvars
	sed -i "s/<region>/${LUSTRE_REGION}/g" fluid.tfvars
	sed -i "s/<subnet>/${LUSTRE_SUBNET}/g" fluid.tfvars

.terraform: 
	terraform init

plan: fluid.tfvars .terraform
	terraform plan -var-file=fluid.tfvars -out terraform.tfplan

apply: plan
	terraform apply -var-file=fluid.tfvars -auto-approve

destroy:
	terraform destroy -var-file=fluid.tfvars -auto-approve
