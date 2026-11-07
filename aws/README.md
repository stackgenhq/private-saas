# AWS Private SaaS Template
A template for creating EKS cluster as part of Private SaaS deployment.

## Getting Started

### Prerequisites
Download the latest terraform binary from https://www.terraform.io/downloads and install.

> [!IMPORTANT]
> **Note**: The terraform version should be `1.3.x` or higher.


### Steps to create the cluster

**Step 1:** Identify the AWS account where the cluster has to be created and export the corresponding AWS credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`).
```bash
export AWS_ACCESS_KEY_ID=<redacted>
export AWS_SECRET_ACCESS_KEY=<redacted>
```

**Step 2:** Navigate to `opsverse-eks-iam` directory and initialize terraform with an S3 bucket for the state file (create one first if needed; enable versioning on it):
```bash
terraform init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=private-saas/<cluster_name>/terraform.tfstate" \
  -backend-config="region=<region>"
```
**Step 3:** Update all the variables that are required to create the cluster to a file called `vars.tfvars` file based on your environment.

**Step 4:** Create an execution plan which lets you preview the changes that Terraform plans to make to your infrastructure. Execute the following command to prepare the plan and write to a file:
```bash
terraform plan -var-file=vars.tfvars -out eks-plan.tfplan
```

The above command prepares the execution plan by reading the variables/config from `vars.tfvars`` file and writes the plan to the given path (_in this case it writes the plan to main.tfplan file_). This can be used as input to the apply command.


**Step 5:** Provision the EKS cluster. Execute the following command:
```bash
terraform apply "eks-plan.tfplan"
```
The above command executes the prepared plan which actually creates the cluster in EKS.

Your EKS cluster should be ready to use!

