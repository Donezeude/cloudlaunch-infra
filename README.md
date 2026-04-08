# CloudLaunch

> Production-grade cloud infrastructure deployment platform built end-to-end with Terraform, Ansible, Docker, and GitHub Actions.

CloudLaunch is a complete DevOps reference project that provisions AWS infrastructure, configures servers, deploys a containerized application, and automates the entire workflow through CI/CD — all defined as code, all reproducible, all built from scratch.

---

## Overview

This project demonstrates the full lifecycle of modern infrastructure delivery: from empty AWS account to a live application serving traffic, with automated deployments on every code push.

The architecture intentionally separates concerns so each tool does one thing well:

- **Terraform** provisions cloud resources (the "what exists")
- **Ansible** configures servers (the "how they're set up")
- **Docker** packages the application (the "what runs")
- **GitHub Actions** automates deployment (the "when it ships")
- **CloudWatch** monitors operations (the "is it healthy")

---

## Architecture

```
┌─────────────┐
│  Developer  │
└──────┬──────┘
       │ git push
       ▼
┌─────────────────────┐
│   GitHub Actions    │  ← CI/CD Pipeline
│  Build → Deploy →   │
│      Verify         │
└──────────┬──────────┘
           │ SCP + SSH
           ▼
┌─────────────────────┐
│   AWS EC2 Instance  │
│  ┌───────────────┐  │
│  │ Docker Engine │  │
│  │  ┌─────────┐  │  │
│  │  │ Flask   │  │  │
│  │  │  App    │  │  │
│  │  └─────────┘  │  │
│  └───────────────┘  │
└──────────┬──────────┘
           │
           ▼
   ┌──────────────┐
   │  CloudWatch  │
   │  Monitoring  │
   └──────────────┘
```

---

## Tech Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Infrastructure as Code | Terraform | AWS resource provisioning |
| Configuration Management | Ansible | Server setup and hardening |
| Containerization | Docker | Application packaging |
| Application Runtime | Python / Flask | Sample web service |
| CI/CD | GitHub Actions | Automated build and deploy |
| Cloud Provider | AWS (EC2, EIP, IAM, CloudWatch) | Hosting and observability |
| Operating System | Ubuntu 24.04 LTS | Server OS |

---

## Key Design Decisions

**Separation of persistent and ephemeral infrastructure.** The Elastic IP and other long-lived resources live in a separate Terraform state from the EC2 instance. This means I can destroy and recreate compute resources at any time without losing the static IP — production infrastructure thinks at different lifecycles, and the code reflects that.

**Two-firewall defense in depth.** Network access is controlled at the AWS Security Group level (cloud perimeter) with the option to extend to host-level firewalls in production. Cloud-level enforcement is the primary control because it stops traffic before it reaches the server.

**CI/CD scoped to application deployment, not infrastructure.** The GitHub Actions pipeline only handles building and deploying the application to existing infrastructure. Provisioning new infrastructure is a deliberate, manual operation. This separation prevents accidental tear-downs and matches how real production environments operate.

**Tar-based image delivery instead of a registry.** For simplicity and to demonstrate direct deployment patterns, the pipeline builds the Docker image on the runner and SCPs it directly to the EC2 instance. In a multi-server production environment, this would be replaced with a container registry like ECR.

---

## Getting Started

### Prerequisites

- AWS account with CLI configured
- Terraform installed
- Ansible installed
- Docker installed
- An EC2 key pair

### 1. Provision persistent resources (one-time)

```bash
cd terraform/persistent
terraform init
terraform apply
```

This allocates an Elastic IP that survives infrastructure rebuilds.

### 2. Provision compute infrastructure

```bash
cd ../infrastructure
terraform init
terraform apply
```

This creates the EC2 instance, security group, IAM roles, and CloudWatch alarms.

### 3. Configure the server

```bash
cd ../../ansible
ansible-playbook playbooks/playbook.yml
```

This installs Docker, hardens the system, and prepares it to run containers.

### 4. Set up CI/CD secrets

In your GitHub repository settings, add the following secrets:

- `EC2_HOST` — Your Elastic IP address
- `EC2_SSH_KEY` — Contents of your private key file

### 5. Deploy

Push to the configured branch:

```bash
git push origin main
```

GitHub Actions will automatically build the Docker image, deploy it to EC2, and verify the health endpoint.

---

## Monitoring

CloudWatch metrics are collected automatically for:

- **CPU utilization** — alarm triggers above 80% sustained for 10 minutes
- **Memory usage** — tracked via custom CloudWatch agent
- **Disk usage** — tracked via custom CloudWatch agent
- **Application logs** — Docker container logs streamed to CloudWatch Logs

Stress test the monitoring:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<elastic-ip>
stress --cpu 2 --timeout 600
```

The CloudWatch alarm will transition from `OK` to `In alarm` after two consecutive 5-minute periods above the threshold.

---

## What I'd Do Differently in Production

This project is intentionally scoped for demonstration. For a real production deployment, the following changes would be essential:

- **Multi-AZ deployment** with auto-scaling groups for high availability
- **RDS or managed database** instead of running data services on the application instance
- **AWS Secrets Manager** for credentials instead of GitHub secrets
- **ECR or another container registry** instead of tar-based image delivery
- **Terraform remote state** in S3 with DynamoDB locking for team collaboration
- **AWS Systems Manager Session Manager** to eliminate inbound SSH access entirely
- **WAF and CloudFront** in front of the application for edge protection and DDoS mitigation
- **Centralized logging** with ELK or Datadog instead of CloudWatch alone
- **Blue/green or canary deployments** instead of single-instance redeployment
- **Infrastructure tests** with Terratest or similar before applying changes

---

## What I Learned Building This

The biggest lesson wasn't any single tool — it was understanding how the pieces fit together and where the boundaries should live. Knowing Terraform syntax is different from knowing when to use Terraform versus Ansible. Knowing Docker commands is different from understanding why your image won't run on a different architecture.

Some of the specific lessons that left a mark:

- Terraform and Ansible aren't competitors. Terraform creates resources from nothing. Ansible configures resources that exist. They hand off via the IP address.
- An Elastic IP is the difference between a portfolio project that "works" and one that's actually maintainable.
- Docker images are architecture-specific. Building on an ARM Mac and deploying to x86 EC2 will fail in subtle ways. The `--platform linux/amd64` flag exists for a reason.
- Host-level firewalls have a way of locking you out faster than they protect you. Cloud security groups are usually the right primary control.
- The gap between knowing the tools and shipping a working system is bigger than tutorials make it seem. Crossing it changes how you think about everything.

---

*Built by [Donald Ezeude](https://www.linkedin.com/in/donald-ezeude-2663901a2). 
