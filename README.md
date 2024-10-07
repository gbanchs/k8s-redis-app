Here is the detailed documentation and steps for building, testing, and deploying the API in both local environments (using Docker Compose) and Kubernetes (using Minikube), as well as integrating it with a CI/CD pipeline that sets environment variables for different environments using the `setenvs.sh` script.

---

# Infra Code Challenge Documentation

This guide explains how to build, test, and deploy the API that increments a counter persisted in Redis, both locally (with Docker Compose) and in a Kubernetes cluster (Minikube). The API exposes two endpoints (`/read` and `/write`), and it can be deployed in multiple environments by modifying variables in the `setenvs.sh` script.

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
   docker build -t redis-counter-api .
   ```

3. **Run the Docker container**:
   ```bash
   docker run -p 5000:5000 redis-counter-api
   ```

This will expose the API locally on `http://localhost:5000`.

### 1.2. Test the API Locally with Docker Compose

To test the API locally with Redis, use Docker Compose. The `docker-compose.yml` is located in the `app` folder.

#### Steps:
1. **Navigate to the app folder**:
   ```bash
   cd app
   ```

2. **Run Docker Compose**:
   ```bash
   docker-compose up
   ```

This will spin up both the API and Redis, with the API accessible on `http://localhost:5000`.

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
   docker tag redis-counter-api:latest <your-ecr-repository-url>:latest
   docker push <your-ecr-repository-url>:latest
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
1. **Navigate to the infra folder**:
   ```bash
   cd infra
   ```

2. **Apply Kubernetes Manifests**:
   Apply the manifests in the following order:

   ```bash
   kubectl apply -f redis-deployment.yaml
   kubectl apply -f redis-service.yaml
   kubectl apply -f api-deployment.yaml
   kubectl apply -f api-service.yaml
   kubectl apply -f ingress.yaml
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

## 4. CI/CD Pipeline Integration

For the final deployment, the CI/CD pipeline (e.g., GitHub Actions, Bitbucket, or Jenkins) should perform the following steps:

1. **Run the `setenvs.sh` script** to dynamically replace environment values in the Kubernetes manifests.
2. **Authenticate Docker with AWS ECR** and push the image for each environment.
3. **Deploy to the target Kubernetes cluster** using `kubectl` commands or Helm.

---

## 5. Final Notes

### Scaling the Application:
- **Horizontal Pod Autoscaler (HPA)**: Kubernetes can automatically scale the number of API pods based on CPU usage or other metrics.
  ```bash
  kubectl autoscale deployment api-deployment --cpu-percent=50 --min=1 --max=10
  ```

### Security Considerations:
- Use **Kubernetes Secrets** to manage sensitive information like Redis credentials.
- Apply **Network Policies** to restrict access to Redis.

---

## Step-by-Step Summary:

1. **Local Testing**:
   - Build the Docker image: `docker build -t redis-counter-api .`
   - Run the app with Docker Compose: `docker-compose up`
   
2. **Minikube Deployment**:
   - Start Minikube: `minikube start`
   - Deploy the app using `kubectl apply -f <manifest-file>`

3. **AWS Docker Auth and Image Push**:
   - Authenticate Docker to AWS: `aws ecr get-login-password | docker login --username AWS --password-stdin`
   - Push the image to ECR: `docker push <ecr-repo-url>:latest`

4. **Environment Setup**:
   - Run `sh setenvs.sh` to replace placeholders and configure environment-specific variables.
   - Deploy using the updated Kubernetes manifests.

Let me know if you need any further clarification!