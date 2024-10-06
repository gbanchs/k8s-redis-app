## Start Here

This document provides a comprehensive guide on how to deploy a Terraform code with Python using Amazon Elastic Container Registry (ECR). The local development setup uses Composer, and the deployment is done in the AWS cloud using the infra folder. The deployment process is automated using GitHub Actions to the Elastic Kubernetes Service (EKS) in AWS.

### Prerequisites

- AWS Account
- Terraform installed
- Python installed
- Composer installed
- Docker installed
- GitHub Account
- kubectl installed

### Local Development Setup

1. Install Composer: Follow the official Composer installation guide.

2. Clone the repository: `git clone <repository-url>`

3. Navigate to the project directory: `cd <project-directory>`

4. Install dependencies: `composer install`

### AWS ECR Setup

1. Navigate to the AWS ECR and create a new repository.

2. Authenticate Docker to the Amazon ECR registry to which you intend to push your image. Use the `aws ecr get-login-password` command to get the docker login password.

3. Build your Docker image using the following command. For information on building a Docker image, see Docker documentation.

4. After the build completes, tag your image so you can push the image to this repository.

5. Run the following command to push this image to your newly created AWS repository.

### Deploying with Terraform

1. Initialize your Terraform workspace, which will download the provider and initialize it with the values provided in the `infra/terraform.tfvars` file: `terraform init`

2. Create a plan and save it to the local file `tfplan`: `terraform plan -out=tfplan`

3. Apply the plan stored in the `tfplan` file: `terraform apply tfplan`

### GitHub Actions for Deployment to AWS EKS

1. Set up the GitHub Actions workflow in `.github/workflows/main.yml` in your repository.

2. The workflow should include steps for setting up AWS credentials, checking out the code, setting up Terraform, and applying the Terraform plan.

3. Push the changes to your repository. The GitHub Actions workflow will automatically trigger and deploy your application to AWS EKS.

### Conclusion

This guide provides a step-by-step process to deploy a Terraform code with Python using ECR, with a local development setup using Composer, and deployment in the AWS cloud using the `infra` folder. The deployment process is automated using GitHub Actions to the Elastic Kubernetes Service (EKS) in AWS.
