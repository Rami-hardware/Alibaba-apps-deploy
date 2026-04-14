# Alibaba-NextCloud-WinAD

Automated deployment of **Nextcloud Enterprise** integrated with **Windows Active Directory** on **Alibaba Cloud**, powered by **Terraform**, **Ansible**, and **GitHub Actions CI/CD**.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Secrets Reference](#secrets-reference)
- [Troubleshooting](#troubleshooting)

## Overview

This project provisions and configures a **Nextcloud Enterprise** (v32) instance on Alibaba Cloud ECS, joined to an existing **Windows Active Directory** domain for authentication. Users authenticate via Kerberos/SSSD — no separate LDAP integration required. **Collabora Online** (coolwsd) is co-deployed on the same host for in-browser document editing.

Infrastructure is defined in Terraform targeting the `me-central-1` region and deploys into an existing VPC (`FAC-VPC`). Configuration of the OS, Apache, Nextcloud, AD join, and Collabora is handled by Ansible. The full pipeline runs automatically via GitHub Actions on pushes to `development`, `staging`, and `main`.

## Architecture

```text
+---------------------------+
|  GitHub Actions CI/CD     |
|  - Terraform (infra)      |
|  - Ansible (config)       |
+---------------------------+
             |
             v
+---------------------------+       +---------------------------+
|  Alibaba Cloud ECS        |<----->|  Windows AD (fac.local)   |
|  me-central-1, FAC-VPC    |       |  Kerberos / SSSD / realm  |
|                           |       +---------------------------+
|  Apache 2 + PHP 8.3       |
|  Nextcloud Enterprise 32  |
|  Collabora Online (9980)  |
+---------------------------+
             |
             v
+---------------------------+
|  Alibaba Cloud RDS        |
|  (Nextcloud database)     |
+---------------------------+
```

- **Terraform** looks up the existing VPC/vSwitch and provisions ECS, RDS, and OSS resources.
- **Ansible** joins the host to AD, installs PHP 8.3 + Apache, deploys Nextcloud Enterprise, and sets up Collabora Online.
- **GitHub Actions** orchestrates the full pipeline end-to-end.

## Prerequisites

- Alibaba Cloud account with access to `me-central-1` and an existing VPC named `FAC-VPC`.
- Windows Active Directory domain reachable from the ECS instance (`fac.local` / `FAC.LOCAL`).
- Terraform >= 1.6.
- Ansible with Vault support.
- SSH key (PEM) for ECS access stored as a GitHub secret.
- A Nextcloud Enterprise download token (the download URL includes a customer hash).

## Repository Structure

```text
.
├── terraform/
│   ├── provider.tf          # Alibaba Cloud provider (me-central-1)
│   ├── main.tf              # VPC/vSwitch data sources; ECS/RDS/OSS modules
│   ├── variables.tf         # Input variables (db_password, etc.)
│   ├── outputs.tf
│   └── modules/
│       ├── ecs/             # ECS instance
│       ├── rds/             # ApsaraDB RDS for Nextcloud
│       └── oss/             # OSS bucket
├── ansible/
│   ├── deploy.yml           # Main playbook (packages → VirtualHost → collabora)
│   ├── inventory.ini        # Ansible Vault-encrypted host inventory
│   └── roles/
│       ├── packages/        # PHP 8.3, Apache, system packages
│       ├── join_ad/         # DNS, chrony, Kerberos, realm join, SSSD
│       ├── nextcloud/       # Download & install Nextcloud Enterprise
│       ├── VirtualHost/     # Apache VirtualHost for Nextcloud
│       └── collabora/       # Collabora Online (coolwsd) install & config
└── .github/
    └── workflows/
        └── terraform.yml    # CI/CD pipeline definition
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/terraform.yml`) triggers on push to `development`, `staging`, or `main` and runs the following steps:

1. **Terraform Init / Validate / Plan** — plans infrastructure changes.
2. **Terraform Apply** — applies the plan (auto-approved).
3. **SSH key setup** — writes the PEM key from secrets.
4. **Ansible Playbook** — decrypts the vault inventory, then runs `deploy.yml` against the target host, passing AD and DB credentials as extra vars.

AD connection parameters passed at runtime:

| Variable | Value |
| --- | --- |
| `ad_domain` | `fac.local` |
| `ad_realm` | `FAC.LOCAL` |
| `ad_server` | `10.50.6.206` |
| `ad_admin_user` | `administrator` |

## Configuration

### Nextcloud Enterprise

Set the download URL and version in [ansible/roles/nextcloud/defaults/main.yml](ansible/roles/nextcloud/defaults/main.yml):

```yaml
nextcloud_version: "32.0.6"
nextcloud_build: "25961b13"
nextcloud_download_url: "https://download.nextcloud.com/.customers/server/{{ nextcloud_version }}-{{ nextcloud_build }}/nextcloud-{{ nextcloud_version }}-enterprise.zip"
```

### PHP

PHP 8.3 tuning defaults are in [ansible/roles/packages/defaults/main.yml](ansible/roles/packages/defaults/main.yml):

```yaml
php_version: "8.3"
php_upload_max_filesize: "2048M"
php_memory_limit: "4096M"
php_fpm_max_children: 500
```

### Collabora Online

Set the `collabora_customer_hash` variable (used to build the apt repo URL) and the Nextcloud domain for the WOPI allow-list in [ansible/roles/collabora/defaults/main.yml](ansible/roles/collabora/defaults/main.yml). Collabora listens on port `9980`.

### Active Directory Join

The `join_ad` role handles the full domain join sequence:

1. Configures DNS to point at the AD server via `systemd-resolved`.
2. Installs `realmd`, `sssd`, `adcli`, `krb5-user`, `chrony`.
3. Syncs time with the AD server via chrony.
4. Writes `/etc/krb5.conf` from a Jinja2 template.
5. Runs `realm join fac.local` with the administrator password.
6. Writes `/etc/sssd/sssd.conf` and enables `mkhomedir`.

## Deployment

### Manual (local)

```bash
# 1. Provision infrastructure
cd terraform
terraform init
terraform apply -var="db_password=<password>"

# 2. Configure the host
cd ../ansible
ansible-playbook \
  -i inventory.ini \
  --private-key ~/.ssh/RamiKey.pem \
  deploy.yml \
  --vault-password-file vault_pass.txt \
  -e "ad_password=<AD_PASSWORD> db_password=<DB_PASSWORD> \
      ad_domain=fac.local ad_realm=FAC.LOCAL \
      ad_server=10.50.6.206 ad_admin_user=administrator"
```

### Automated (GitHub Actions)

Push to `development`, `staging`, or `main`. The pipeline reads credentials from repository secrets and runs Terraform + Ansible automatically.

## Secrets Reference

| Secret | Used by | Description |
| --- | --- | --- |
| `ALICLOUD_ACCESS_KEY` | Terraform | Alibaba Cloud access key |
| `ALICLOUD_SECRET_KEY` | Terraform | Alibaba Cloud secret key |
| `DB_PASSWORD` | Terraform + Ansible | Nextcloud RDS database password |
| `ALI_PEM_KEY` | Ansible | PEM private key for ECS SSH access |
| `AD_ADMIN_PASSWORD` | Ansible | Windows AD administrator password for domain join |
| `ANSIBLE_VAULT_PASSWORD` | Ansible | Password to decrypt `inventory.ini` |

## Troubleshooting

- **Terraform errors** — verify `ALICLOUD_ACCESS_KEY`/`ALICLOUD_SECRET_KEY` and that the FAC-VPC exists in `me-central-1`.
- **realm join fails** — confirm the ECS instance can reach `10.50.6.206` on UDP 88 (Kerberos) and TCP 389. Check that chrony has synced time within 5 minutes of the AD server.
- **SSSD not resolving AD users** — run `sssctl user-checks <user>@fac.local` and inspect `/var/log/sssd/`.
- **Apache / Nextcloud not starting** — check `journalctl -u apache2` and `/var/www/nextcloud/data/nextcloud.log`.
- **Collabora not reachable** — verify `coolwsd` is running (`systemctl status coolwsd`) and port 9980 is open in the ECS security group.
- **Ansible Vault errors** — ensure `vault_pass.txt` contains the exact password stored in the `ANSIBLE_VAULT_PASSWORD` secret.

## License

MIT License. See the [LICENSE](LICENSE) file for details.
