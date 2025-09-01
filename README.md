# F5 Customer Edge Terraform Pipeline Demo

This repository contains a complete, end-to-end GitOps workflow for deploying F5 Distributed Cloud Customer Edge (CE) sites on AWS using Terraform and GitHub Actions.

It is designed to showcase a secure, repeatable, and automated approach to infrastructure deployment, suitable for a "Guided Automator" persona who wants to integrate a ready-made solution into their CI/CD process.

## ✨ Features

* **GitOps-Driven:** The pipeline automatically triggers a `terraform plan` when the `sites.tfvars` file is updated.
* **Manual Approval Gate:** For security, the workflow pauses after the `plan` and requires a manual approval via a GitHub Issue before proceeding with `terraform apply`.
* **Secure Credential Handling:** All sensitive credentials (AWS keys, F5 `.p12` file, and password) are handled securely using GitHub Secrets and AWS OIDC Connect. No secrets are ever stored in the repository.
* **Persistent State Management:** Uses an AWS S3 bucket as a remote backend to securely store the Terraform state file, enabling collaboration and stateful operations like `destroy`.
* **Automated Destroy Workflow:** Includes a separate, manually triggered workflow to safely tear down the infrastructure.

---

## 💡 Core Concepts Explained

### Why Use an S3 Backend for Terraform State?

When Terraform creates infrastructure, it saves a special file called `terraform.tfstate` to keep track of all the resources it manages. By default, this file is stored locally. In a CI/CD pipeline, this is a problem because the temporary machine (the GitHub runner) is destroyed after the workflow finishes, and the state file is lost forever.

Using an **AWS S3 bucket as a remote backend** solves this by storing the state file in a central, persistent location. This provides three key benefits:

1.  **Persistence:** The state file is stored safely in S3 and is not lost when the pipeline finishes. This is essential for managing your infrastructure over time and for the `destroy` workflow to know what resources to delete.
2.  **Central Source of Truth:** Every workflow run (both `deploy` and `destroy`) reads from the same state file in S3. This ensures that all operations have an up-to-date understanding of the infrastructure, preventing conflicts.
3.  **Security:** You can control access to the S3 bucket using IAM policies, enable encryption, and use versioning to keep a history of your state, which helps in case of accidental changes.

### Why Convert the `.p12` File to Base64?

A `.p12` file is a sensitive credential that contains your private key. You must **never** commit sensitive files like this directly into a Git repository.

* **Security Risk:** If you commit the file, it becomes part of the repository's history forever. Anyone with access to the repository (even in the future) can retrieve your credentials.
* **The Solution:** We convert the binary `.p12` file into a very long string of text using a standard encoding called **Base64**. This allows us to store the *content* of the file in a GitHub Secret without ever saving the file itself in our code.

### How the Base64 Method Works

The process is simple and secure:

1.  **Encode Locally:** You run a command on your local machine to convert the `.p12` file into a Base64 string.
    * **For macOS:** `base64 -i your-file.p12`
    * **For Linux:** `base64 your-file.p12`
2.  **Store in GitHub Secrets:** You copy this long string and save it as a secret in your repository settings (e.g., `P12_FILE_BASE64`).
3.  **Decode in the Workflow:** The GitHub Actions workflow retrieves this secret string at runtime and uses the `base64 --decode` command to turn it back into a temporary `.p12` file. This file only exists for the duration of the workflow and is destroyed along with the runner, ensuring your credentials are never exposed.

---

## Prerequisites

Before you can use this automation, you will need:

1.  **An AWS Account** with permissions to create IAM roles, S3 buckets, and the necessary networking/compute resources for the F5 CE sites.
2.  **An F5 Distributed Cloud (XC) Account** with an API Certificate (`.p12` file) and its corresponding password.
3.  **A GitHub Account** and a repository forked or copied from this template.

---

## 🚀 One-Time Setup

The following steps must be completed once to configure the secure connection between your GitHub repository and your AWS account.

### 1. AWS S3 Backend Setup

This workflow requires an S3 bucket to store the Terraform state file.

1.  **Create an S3 Bucket:** In your AWS account, create a new S3 bucket. It must have a **globally unique name** (e.g., `your-org-f5-pipeline-tfstate`).
2.  **Update Workflow Files:** Open both `terraform-deploy.yml` and `terraform-destroy.yml` and replace `f5-pipeline-demo-tfstate` with your unique bucket name.

### 2. AWS IAM & GitHub OIDC Configuration

This establishes a secure, passwordless trust relationship between GitHub and AWS.

1.  **Create OIDC Identity Provider:** In the AWS IAM Console, create a new **OpenID Connect** identity provider for GitHub.
    * **Provider URL:** `https://token.actions.githubusercontent.com`
    * **Audience:** `sts.amazonaws.com`
2.  **Create IAM Role:** Create a new IAM Role that trusts the OIDC provider.
    * **Trusted entity type:** Web identity
    * **Identity provider:** Select the provider you just created.
    * **Permissions:** Attach the necessary policies for Terraform to create resources (e.g., `AmazonEC2FullAccess`, `AmazonVPCFullAccess`, `AmazonS3FullAccess`).
    * **Role Name:** Give it a name like `GitHub-F5-Deploy-Role`.
    * **Copy the Role ARN** after creation.

### 3. GitHub Secrets Configuration

You must add your credentials as encrypted secrets to your repository. In your GitHub repo, go to **Settings > Secrets and variables > Actions** and add the following secrets:

* `AWS_REGION`: The AWS region you are deploying to (e.g., `eu-central-1`).
* `AWS_ROLE_TO_ASSUME`: The full ARN of the IAM role you created above.
* `P12_FILE_BASE64`: Your `.p12` file, encoded as a Base64 string.
* `P12_PASSWORD`: The password for your `.p12` file.

---

## ⚙️ How to Use

### Deploying a Site

1.  **Define Your Site:** Open the `sites.tfvars` file and configure the variables for the F5 CE site you want to deploy.
2.  **Commit and Push:** Commit and push your changes to the `main` branch.
    ```bash
    git add sites.tfvars
    git commit -m "Configure new site for deployment"
    git push origin main
    ```
3.  **Approve the Plan:**
    * Go to the **Actions** tab in your GitHub repository. A new workflow run will be in progress.
    * The workflow will pause after the `plan` step and create a new issue in the **Issues** tab.
    * Open the issue and comment `approved` or `yes` to proceed.
4.  **Monitor the Apply:** The workflow will automatically resume and run `terraform apply`. You can watch the progress in the Actions log.

### Destroying a Site

1.  **Navigate to Actions:** Go to the **Actions** tab in your repository.
2.  **Select the Destroy Workflow:** In the left sidebar, click on **"Terraform Destroy F5 Site"**.
3.  **Run the Workflow:** Click the **"Run workflow"** dropdown. You will be prompted to type `destroy` to confirm. This is a safety measure to prevent accidental deletion.
4.  **Execute:** Click the green **"Run workflow"** button to tear down the infrastructure.
