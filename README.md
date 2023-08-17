## Solution

I have deployed the solution using a combination of Public Terraform modules from the Registry and custom Resources.

In the folder `remote-state-mgmt` I have included some terraform which is used to deploy the resources for the backend and an IAM Role for the CI/CD pipeline to use.

> `iam.tf` - Creates an OIDC provider and an IAM Role for the CI/CD pipeline to use to access the account to be deployed into.
> `main.tf` - Creates an S3 bucket and DynamoDB table for the backend to use.

Note that these resources do not use a backend as they deploy the backed resources and the intended use is for a github actions pipeline to deploy the resources.

### Assumptions

I have made the following assumptions:
* The ASG is to be deployed in the public subnets
* The RDS instance is to be deployed in the private subnets