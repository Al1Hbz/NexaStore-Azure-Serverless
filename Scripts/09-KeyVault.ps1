
# ==========================================
# Lab02 - Azure Key Vault
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"
$KeyVaultName      = "kv-lab02-dev-09"
$FunctionAppName = "func-lab2-dev-09"


# ==========================================
# PART 1: Create Azure Key Vault
# ==========================================

# 1. Create Key Vault
# Creates a Standard Key Vault using Vault Access Policies
# instead of Azure RBAC authorization.

New-AzKeyVault `
    -Name $KeyVaultName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Sku Standard `
    -DisableRbacAuthorization


# ==========================================
# PART 2: Verify Key Vault Configuration
# ==========================================

# 2. Retrieve Existing Key Vault

$kv = Get-AzKeyVault `
    -VaultName $KeyVaultName `
    -ResourceGroupName $ResourceGroupName


# 3. Display Key Vault Information

$kv | Format-List VaultName, VaultUri, EnableRbacAuthorization


# ==========================================
# PART 3: Configure Function App Access
# ==========================================

# 4. Retrieve Function App and its Managed Identity

$func = Get-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName


# 5. Grant Function App Managed Identity Access to Key Vault Secrets

Set-AzKeyVaultAccessPolicy `
    -VaultName $KeyVaultName `
    -ResourceGroupName $ResourceGroupName `
    -ObjectId $func.Identity.PrincipalId `
    -PermissionsToSecrets Get,List

# ==========================================
# PART 4: Verify Key Vault Access Policies
# ==========================================

# 6. Retrieve and Display Key Vault Access Policies
# Displays the identities and permissions assigned to the Vault.

Get-AzKeyVault `
    -VaultName $KeyVaultName `
    -ResourceGroupName $ResourceGroupName |
    Select-Object -ExpandProperty AccessPolicies
