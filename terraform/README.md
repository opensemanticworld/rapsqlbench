# Terraform AWS rapsqlbench

<!-- vscode-markdown-toc -->
Table of Contents

- [Terraform AWS rapsqlbench](#terraform-aws-rapsqlbench)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
    - [Terraform CLI](#terraform-cli)
    - [AWS CLI](#aws-cli)
  - [Usage](#usage)

## Prerequisites

<details>
<summary>Details</summary>

- [Terraform Install](https://learn.hashicorp.com/tutorials/terraform/install-cli)
  - `gnupg`
  - `software-properties-common`
  - `curl`
- [AWS CLI Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - `curl`
  - `unzip`
  - [AWS CLI Post-Installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
    - [Configure SSO](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html)
    - [AWS CLI Config](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

</details>

## Installation

### Terraform CLI

<details>
<summary>Details</summary>

1. Terraform prerequisites to verify HashiCorp's GPG signature:

    ```bash
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    ```

2. Install the HashiCorp GPG key:

    ```bash
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    ```

3. Verify the key's fingerprint:

    ```bash
    gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
    ```

4. Add the official HashiCorp Linux repository:

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
    ```

5. Download the package information from HashiCorp

    ```bash
    sudo apt update
    ```

6. Install Terraform from the new repository:

    ```bash
    sudo apt-get install terraform
    ```

</details>

### AWS CLI

<details>
<summary>Details</summary>

1. To install the AWS CLI, run the following commands:

    ```bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip && rm -f awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    ```

2. To check the AWS CLI version and installation directory, run the following command:

    ```bash
    aws --version
    which aws
    ```

3. To remove the unzipped files, run the following command:

    ```bash
    sudo rm -rf ./aws
    ```

</details>

## Usage

1. To configure the AWS CLI, run the following command:

    ```bash
    aws configure sso
    ```

2. Follow the prompts

3. To initialize Terraform, run the following command:

    ```bash
    terraform init
    ```

4. To create the infrastructure, run the following command:

    ```bash
    terraform apply
    ```

5. Configure the `rapsqlbench` setup in [config.yml](../ansible/config.yml) before starting the benchmark.

6. To perform `rapsqlbench` from `terraform` directory using `ansible`, e.g. vm name `vm50k` run:

    ```bash
    ansible-playbook -i ./inventory/vm50k-eip.txt ../ansible/deploy.yml -e "@../ansible/config.yml"
    ```
