# Infra Code Challenge Documentation

This guide explains how to build, test, and deploy the API that increments a counter persisted in Redis, both locally (with Docker Compose) and in a Kubernetes cluster (Minikube). Additionally, it outlines how to deploy infrastructure using Terraform for various environments, starting with the **global environment** for initial setup (such as creating the S3 bucket and DynamoDB table), while allowing customization based on your environment.

## 1. Application Code and Dockerfile

The API is written in Python and is containerized using Docker. Here are the steps to build and run the application locally:

### 1.1. Build the Docker Image Locally

Navigate to the `app` folder where the `Dockerfile` and `app.py` are located.

#### Steps:
1. **Navigate to the app folder**:
   ```bash
   cd app
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t bluecore . --platform=linux/amd64
   ```

3. **Run the Docker container**:
   ```bash
   docker run -p 8000:8000 bluecore
   ```

This will expose the API locally on `http://localhost:8000`.

### 1.2. Test the API Locally with Docker Compose

To test the API locally with Redis, use Docker Compose. The `docker-compose.yml` is located in the `app` folder.

#### Steps:
1. **Navigate to the app folder**:
   ```bash
   cd app
   ```

2. **Run Docker Compose**:
   ```bash
   docker-compose up -d
   ```

This will spin up both the API and Redis, with the API accessible on `http://localhost:8000`.

### 1.3. Docker AWS Authentication (For AWS ECR)

If you're pushing the Docker image to AWS ECR, authenticate Docker to the AWS registry:

#### Steps:
1. **Authenticate Docker to ECR**:
   ```bash
   aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com
   ```

2. **Push the Docker image to ECR**:
   After building the image, tag and push it to your AWS ECR repository.
   ```bash
   docker tag bluecore:latest <your-ecr-repository-url>:latest
   docker push <your-ecr-repository-url>:latest
   ```


### 1.2. Test the API Locally with Docker Compose

To test the API locally with Redis, use Docker Compose. The `docker-compose.yml` is located in the `app` folder.

#### Steps:
1. **Navigate to the app folder**:
   ```bash
   cd app
   ```

2. **Run Docker Compose**:
   ```bash
   docker-compose up -d
   ```

This will spin up both the API and Redis, with the API accessible on `http://localhost:8000`.


3. **GET Request to Read the Counter**:
   Use `curl` or a web browser to read the current counter value:
   ```bash
   curl http://localhost:8000/read
   ```

   You should receive a JSON response with the current counter value:
   ```json
   {"counter": 0}
   ```

4. **POST Request to Increment the Counter**:
   Use `curl` or Postman to increment the counter:
   ```bash
   curl -X POST http://localhost:8000/write
   ```

   You should receive a JSON response with the updated counter value:
   ```json
   {"counter": 1}
   ```

### 1.3. Testing on the Production Domain (`bluecore.gbanchs.com`)

After deploying the API on Kubernetes with Ingress, the API will be accessible on the domain `bluecore.gbanchs.com`. Here’s how to test the API on the real domain:

1.3. **GET Request to Read the Counter**:
   ```bash
   curl http://bluecore.gbanchs.com/read
   ```

   Example Response:
   ```json
   {"counter": 0}
   ```

1.2. **POST Request to Increment the Counter**:
   ```bash
   curl -X POST http://bluecore.gbanchs.com/write
   ```

   Example Response:
   ```json
   {"counter": 1}
   ```

---

## 2. Deploy the API on Kubernetes (Minikube)

The deployment uses Kubernetes manifests, including `Ingress`, `Service`, `Deployment`, `ConfigMap`, and `Redis` definitions.

### 2.1. Set Up Minikube

Ensure Minikube is installed and running:

#### Steps:
1. **Start Minikube**:
   ```bash
   minikube start
   ```

2. **Enable Ingress (if using Minikube)**:
   ```bash
   minikube addons enable ingress
   ```

### 2.2. Deploy the Application with Kubernetes Manifests

Kubernetes YAML manifests are located in the `infra` folder. They include deployment, service, configmap, and ingress definitions for the API and Redis.

#### Steps:
1. **Navigate to the k8s folder**:
   ```bash
   cd app/k8s/
   ```

2. **Apply Kubernetes Manifests**:
   Apply the manifests in the following order:

   ```bash
   kubectl apply -f .

   ```

3. **Verify the Pods**:
   Check the status of the pods:
   ```bash
   kubectl get pods
   ```

4. **Expose Minikube Ingress**:
   To expose the Ingress controller on Minikube:
   ```bash
   minikube tunnel
   ```

   Now, the API should be accessible via the Minikube IP and the Ingress host.

---

## 3. Local Environment Configuration (`setenvs.sh`)

The `setenvs.sh` script in the `app` folder is used to replace placeholder values in the Kubernetes YAML files, allowing you to deploy to different environments by changing variables dynamically.

### 3.1. Use the `setenvs.sh` Script

The script replaces placeholders in YAML files with environment-specific values.

#### Steps:
1. **Navigate to the app folder**:
   ```bash
   cd app
   ```

2. **Run the `setenvs.sh` script**:
   ```bash
   sh setenvs.sh
   ```

This will replace placeholders (e.g., environment-specific URLs, API keys, and Redis credentials) in the Kubernetes YAML manifests located in the `infra` folder.

### 3.2. Deploy to Different Environments

To deploy the application in different environments, update the values in the `setenvs.sh` script and rerun the deployment:

- Change variables for environments such as `dev`, `staging`, or `production`.
- Replace values like Redis host, image repository, and other environment-specific settings.

---

## 4. Terraform Deployment (for AWS infrastructure)

The `infra` folder includes a fully structured Terraform setup to create infrastructure for different environments such as VPC, EKS cluster, Redis, and other components. The **global environment** is used to set up the initial infrastructure, such as the S3 bucket for Terraform state and the DynamoDB table for Terraform locking.

### 4.1. Structure Overview

Here’s an overview of the folder structure:

```
├── infra
│   ├── envs
│   │   ├── demo
│   │   │   ├── backend.tf
│   │   │   ├── main_demo.tf
│   │   │   ├── output.tf
│   │   │   └── vars.tf
│   │   ├── global
│   │   │   ├── main.tf
│   │   │   ├── backend.tf
│   │   │   └── vars.tf
│   ├── modules
│   │   ├── eks
│   │   ├── redis-cluster
│   │   └── vpce
│   ├── main.tf
│   ├── providers.tf
│   ├── vars.tf
```

### 4.2. Create the Global Environment

The global environment is used to set up the initial infrastructure for managing Terraform state and locks, which includes creating the **S3 bucket** and **DynamoDB table** for Terraform’s backend.

1. **Navigate to the global environment folder**:
   ```bash
   cd infra/envs/global
   ```

2. **Deploy the Global Infrastructure**:
   Run the following commands to initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform apply
   ```

This will create:
- An S3 bucket for storing the Terraform state files.
- A DynamoDB table to handle state locks, ensuring that multiple users cannot modify the same infrastructure at the same time.

3. **Backend Configuration**:
   Once the global environment is deployed, update the `backend.tf` file in each environment (`demo`, `prod`, etc.) to use the S3 bucket and DynamoDB table created by the global environment.

### 4.3. Create New Environments

To create a new environment, duplicate the working environment folder (e.g., `demo`) and follow these steps:

1. **Duplicate and Rename the Environment Folder**:
   Copy the folder for an existing environment and rename it to your new environment (e.g., `prod`).

2. **Update Terraform Backend**:
   In the `backend.tf` file for the new environment, update the `backend` configuration to use the newly created S3 bucket and DynamoDB table for the state file and locking.

   Example:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "path/to/statefile/prod.tfstate"
       region = "us-east-1"
       dynamodb_table = "terraform-locks"
       encrypt = true
     }
   }
   ```

3. **Update Variables**:
   Modify the `vars.tf` file in the new environment folder, updating the variables such as environment name, domain, and specific configurations for that environment.

4. **Set ECR Repositories**:
   Define the number of ECR repositories and their configurations in the `ecr_repositories` variable.

   Example:
   ```hcl
   ecr_repositories = {
     repo1 = {
       name = "app-repo"
       lifecycle_policy = {
         rulePriority = 1
         description  = "Keep last 10 images"
         countNumber  = 10
       }
       repository_read_write_arns = ["arn:aws:iam::111111111111:role/app-role"]
     }
   }
   ```

5. **Deploy the Environment**:
   Navigate to the new environment folder and run the following commands to initialize and apply the Terraform configuration:
   
   ```bash
   cd infra/envs/prod
   terraform init
   terraform apply
   ```

### 4.4. Custom Resource Creation Configuration

In the base module, you can define whether

 to create certain resources (VPC, EKS cluster, Redis, etc.) with the following variables in the `vars.tf`:

```hcl
creation_config = {
  create_vpc           = true
  create_vpc_endpoints = true
  create_eks_cluster   = true
  create_bastion       = true
  create_redis         = true
}
```

If needed, you can share an EKS or Redis cluster across environments to save costs by setting these to `false` in the relevant environments.

---

## 5. CI/CD Pipeline Integration

For the final deployment, the CI/CD pipeline (e.g., GitHub Actions, Bitbucket, or Jenkins) should perform the following steps:

1. **Run the `setenvs.sh` script** to dynamically replace environment values in the Kubernetes manifests.
2. **Authenticate Docker with AWS ECR** and push the image for each environment.
3. **Deploy to the target Kubernetes cluster** using `kubectl` commands or Helm.

---

## Scaling and High Availability (HA) Configurations

To ensure high availability (HA) and efficient scaling for the application deployed on Amazon EKS, several components and configurations are in place:

### 1. Cluster Autoscaler
The EKS cluster is equipped with a **Cluster Autoscaler**, which automatically adjusts the number of nodes in the cluster based on the resource requests of the pods. This allows the cluster to scale up when there are insufficient resources and scale down when the resources are underutilized, optimizing cost efficiency.

### 2. Horizontal Pod Autoscaler (HPA)
A **Horizontal Pod Autoscaler** is implemented in the `deployment-template.yaml`. This allows the application to scale the number of pod replicas based on CPU utilization or other selected metrics. As demand increases, the HPA automatically adjusts the number of pods to maintain performance.

### 3. Vertical Pod Autoscaler (VPA)
The **Vertical Pod Autoscaler** (VPA) is also set up within the cluster. VPA automatically adjusts the resource requests for your pods based on usage patterns, helping ensure that pods have enough resources to operate efficiently without over-provisioning.

### 4. Karpenter
**Karpenter** is an open-source Kubernetes cluster autoscaler designed to provision and manage nodes in EKS efficiently. While it is currently disabled by default, it can be easily enabled by setting the `enable_karpenter` variable to `true`. Karpenter intelligently provisions new instances based on the needs of the pods, enabling faster scaling and optimizing costs.

### 5. Cluster Proportional Autoscaler
The **Cluster Proportional Autoscaler** is available but disabled by default. It can be enabled easily, allowing for automatic scaling of core components based on the number of pods running in the cluster.

### 6. Redis Clustering
The Redis setup utilizes **Redis Cluster Mode**, which allows for data distribution across multiple nodes and shards. This ensures high availability and data redundancy. Additionally, the Redis instances are spread across three availability zones in the `us-west-2` region (a, b, c), providing enhanced resilience and fault tolerance.

- **Horizontal Pod Autoscaler (HPA)**: Kubernetes can automatically scale the number of API pods based on CPU usage or other metrics.
  ```bash
  kubectl autoscale deployment api-deployment --cpu-percent=50 --min=1 --max=10
  ```


## Security Considerations
### 1. Principle of Least Privilege
For all AWS resources and services used in this deployment, we adhere to the principle of least privilege. This approach ensures that each resource has only the permissions necessary to perform its designated functions, thereby minimizing security risks.

### 2. Service Accounts and IAM Roles
The application is associated with a Kubernetes Service Account named sa-bluecore-demo. This service account has an IAM role assigned that provides the required permissions to interact with AWS resources. If the application needs to access additional AWS services in the future, the IAM role associated with this service account can be modified to grant the necessary permissions while still following the least privilege principle.

### 3. Encryption with KMS
Almost all sensitive data within the infrastructure is encrypted using AWS Key Management Service (KMS). This includes:

Data at rest (e.g., EBS volumes, S3 buckets).
Secrets stored in Kubernetes Secrets, ensuring that sensitive information is protected.
### 4. Kubernetes Secrets Management
Kubernetes Secrets are utilized to manage sensitive information within the cluster. In this deployment, secrets are populated from AWS Secrets Manager using an external secret provider. The setup uses the Kubernetes External Secrets project, which integrates with AWS Secrets Manager to create Kubernetes Secrets automatically based on defined configurations.

### Integration Steps:
Terraform Module Creation: Secrets are created in Terraform during the setup of the redis-cluster module. This ensures that all secrets required by the Redis instances and the application are created consistently and securely.
External Secret Provider: The Kubernetes External Secrets controller synchronizes secrets from AWS Secrets Manager into Kubernetes, allowing the application to consume these secrets directly without hardcoding them in the application code.
### 5. Port and Network Security
The application and Redis instances are deployed in private subnets, ensuring they are not directly exposed to the internet. All security groups are connected using Redis and nodes' security groups, in addition to the default node security group created by the EKS module.

Ingress Configuration: The public exposure of the application is managed through an Ingress controller that matches the path and domain for traffic routing. This provides controlled access to the application while keeping the backend services secured.

Redis Authentication: Redis is configured with AUTH to enforce authentication for clients attempting to connect, adding an additional layer of security.

### 6. AWS Shield Advanced Protection
The Load Balancer used for the application has AWS Shield Advanced protection enabled, providing enhanced security against DDoS attacks and other malicious activities. Deletion protection is also enabled to prevent accidental removal of critical resources.

### 7. Future Security Enhancements
To further enhance security and mitigate risks of DDoS attacks, plans are in place to integrate AWS WAF (Web Application Firewall). This will provide an additional layer of protection by allowing you to create custom rules to filter out unwanted traffic and protect the application from common web exploits.

---

## Future Enhancements

### 1. Monitoring
To ensure the application runs smoothly and efficiently, monitoring will be implemented using **Grafana** and **Prometheus**:
- **Prometheus** will be configured to scrape metrics from the application and Redis instances, providing insights into performance and resource utilization.
- **Grafana** is already pre-installed; it will require configuration to visualize the metrics collected by Prometheus. Dashboards will be set up to monitor key performance indicators (KPIs), such as response times, error rates, and Redis cache hits.

### 2. Integration of AWS WAF (Web Application Firewall)
Plans are in place to integrate **AWS WAF** for enhanced protection against common web exploits and DDoS attacks. This integration will allow for:
- Custom rule creation to filter out malicious traffic.
- Real-time monitoring of web traffic patterns and threats.
- Better control over access to the application based on defined security policies.

### 3. CI/CD Pipelines
To automate the deployment process for both the Terraform infrastructure and the application, CI/CD pipelines will be established:
- **Terraform Pipelines**: These will automate the execution of Terraform commands (e.g., `terraform init`, `terraform plan`, and `terraform apply`) for infrastructure provisioning. Integration with tools like GitHub Actions or Jenkins can help manage the infrastructure as code.
  
- **Application Deployment Pipelines**: Separate pipelines will be set up for building and deploying the application code to Kubernetes. This includes:
  - Building Docker images.
  - Pushing images to AWS ECR.
  - Deploying the application to the Kubernetes cluster using Helm or kubectl commands.
  


