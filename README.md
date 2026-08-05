# Azure Compliance Engine

A small lab that provisions a sample Azure environment with Terraform, then scans it with a Python engine that checks the live resources against a set of compliance rules (tagging, region restrictions, public IP exposure, storage encryption-in-transit, and NSG inbound rules). Results are printed to the console and exported to CSV and Excel reports.

## What this lab demonstrates

- Writing baseline Azure infrastructure in Terraform (resource group, storage account, key vault, managed identity, virtual network, subnet, NSG, and role assignments).
- Querying live Azure resource state with the Azure CLI (`az resource list`, `az storage account show`, `az network nsg show`).
- Running a set of independent compliance checks against each resource.
- Producing human-readable and spreadsheet-friendly compliance reports.

## Architecture

```
terraform/          Provisions the Azure test environment
compliance/
  scanner.py         Pulls all resources in the subscription via `az resource list`
  checks.py           Individual compliance rules, one function per check
  main.py             Orchestrates: runs every check against every resource, prints a summary, writes reports
  report.py           Console report helper
reports/
  findings.csv        Raw findings, one row per resource/check
  findings.xlsx       Same findings, formatted with color-coded PASS/FAIL and auto-filter
```

## Compliance checks

| Check | What it verifies |
|---|---|
| `check_tags` | Resource has the required tags: `environment`, `owner` |
| `check_region` | Resource is deployed in an allowed region (`eastus` only) |
| `check_public_ip` | Resource is not a public IP address (flags any internet-facing IP) |
| `check_storage_https` | Storage accounts enforce HTTPS-only traffic |
| `check_nsg_open_ports` | NSGs have no inbound "Allow" rule open to `*` / `0.0.0.0/0` / `Internet` |

## Prerequisites

- An Azure subscription and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in (`az login`) with access to create resources.
- [Terraform](https://developer.hashicorp.com/terraform/install) (provider pinned to `azurerm ~> 5.0.0`).
- Python 3.10+ with `openpyxl` installed.

## Step-by-step: running the lab

### 1. Provision the Azure environment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- a resource group (`rg-compliance` by default)
- a storage account
- a key vault (RBAC-authorized)
- a user-assigned managed identity, with Reader / Storage Account Contributor / Contributor role assignments
- a virtual network with one subnet
- an NSG (with an inbound rule allowing HTTPS from any source) associated to the subnet

Note the outputs — subscription ID, tenant ID, resource group, storage account, and key vault names are printed at the end of `apply`.

### 2. Set up the Python environment

From the repo root:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install openpyxl
```

### 3. Confirm Azure CLI access

The scanner shells out to `az`, so make sure you're logged into the same subscription Terraform deployed into:

```bash
az account show
```

### 4. Run the compliance scan

```bash
python -m compliance.main
```

This will:
1. List every resource in the subscription (`compliance/scanner.py`).
2. Run all five checks against each resource (`compliance/checks.py`).
3. Print a summary (resources scanned, checks passed/failed) to the console.
4. Write detailed findings to `reports/findings.csv` and `reports/findings.xlsx`.

### 5. Review the results

- `reports/findings.csv` — plain-text findings, easy to diff or pipe into other tools.
- `reports/findings.xlsx` — same data with a bold header, frozen header row, auto-filter, and green/red row shading for PASS/FAIL.

Because the sample NSG rule allows inbound HTTPS from any source (`0.0.0.0/0`), expect at least one `FAIL` on `nsg_open_ports` out of the box — this is intentional, to give the scanner something to catch.

### 6. Tear down

When you're done with the lab, destroy the Azure resources to avoid ongoing cost:

```bash
cd terraform
terraform destroy
```

## Extending the lab

- Add new checks by writing a function in `compliance/checks.py` with the signature `(resource) -> (bool, str)` and registering it in the `CHECKS` tuple in `compliance/main.py`.
- Adjust `REQUIRED_TAGS` / `ALLOWED_REGIONS` in `compliance/checks.py` to match your organization's policy.
- Point the scanner at a different subscription by changing the active `az account set --subscription <id>` before running.
