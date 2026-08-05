import json
import subprocess

REQUIRED_TAGS = ["environment", "owner"]
ALLOWED_REGIONS = ["eastus"]


def check_tags(resource, required_tags=REQUIRED_TAGS):
    tags = resource.get("tags") or {}
    missing = [t for t in required_tags if t not in tags]
    return (False, f"missing tags: {', '.join(missing)}") if missing else (True, "all required tags present")


def check_region(resource, allowed_regions=ALLOWED_REGIONS):
    location = resource.get("location")
    if location not in allowed_regions:
        return False, f"region '{location}' not allowed"
    return True, f"region '{location}' allowed"


def check_public_ip(resource):
    if resource.get("type") == "Microsoft.Network/publicIPAddresses":
        return False, "public IP address exposed to the internet"
    return True, "no public IP exposure"


def check_storage_https(resource):
    if resource.get("type") != "Microsoft.Storage/storageAccounts":
        return True, "not a storage account"
    result = subprocess.run(
        ["az", "storage", "account", "show", "--ids", resource.get("id"),
         "--query", "enableHttpsTrafficOnly", "-o", "json"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return False, f"could not verify HTTPS enforcement: {result.stderr.strip()}"
    if json.loads(result.stdout) is not True:
        return False, "storage account does not enforce HTTPS-only traffic"
    return True, "HTTPS-only traffic enforced"


def check_nsg_open_ports(resource):
    if resource.get("type") != "Microsoft.Network/networkSecurityGroups":
        return True, "not a network security group"
    result = subprocess.run(
        ["az", "network", "nsg", "show", "--ids", resource.get("id"), "-o", "json"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return False, f"could not read NSG rules: {result.stderr.strip()}"
    rules = json.loads(result.stdout).get("securityRules", [])
    for rule in rules:
        if (rule.get("access") == "Allow" and rule.get("direction") == "Inbound"
                and rule.get("sourceAddressPrefix") in ("*", "0.0.0.0/0", "Internet")):
            return False, f"rule '{rule.get('name')}' allows inbound traffic from any source"
    return True, "no open inbound rules from any source"