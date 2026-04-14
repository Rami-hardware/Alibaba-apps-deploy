# Alibaba-apps-deploy

Automated provisioning of **ECS VMs**, **RDS**, and **OSS** on Alibaba Cloud using **Terraform**, with VM configuration managed by **Ansible**.

## Overview

This repo automates the full infrastructure lifecycle on Alibaba Cloud:

- **Terraform** provisions ECS instances, an ApsaraDB RDS database, and an OSS storage bucket.
- **Ansible** configures the provisioned VMs — installing packages, deploying applications, and applying system settings.
- **GitHub Actions** orchestrates the pipeline end-to-end, running CI checks on every branch and deploying only on `main`.

## License

MIT License. See the [LICENSE](LICENSE) file for details.
