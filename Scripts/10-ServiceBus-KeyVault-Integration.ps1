
# ==========================================
# Lab02 - Service Bus & Key Vault Integration
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$NamespaceName     = "sb-lab02-dev"
$KeyVaultName      = "kv-lab02-dev-09"
$FunctionAppName   = "func-lab2-dev-09"
$PolicyName        = "func-listen"
$SecretName        = "ServiceBusConnection"


# ==========================================
# PART 1: Retrieve Service Bus Connection String
# ==========================================

# 1. Retrieve Service Bus Authorization Rule Keys

$Keys = Get-AzServiceBusKey `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $PolicyName

$ServiceBusConnectionString = $Keys.PrimaryConnectionString


# ==========================================
# PART 2: Convert Connection String to SecureString
# ==========================================

# 2. Convert Connection String to SecureString

$Secret = ConvertTo-SecureString `
    $ServiceBusConnectionString `
    -AsPlainText -Force


# ==========================================
# PART 3: Store Connection String in Key Vault
# ==========================================

# 3. Store Connection String as a Key Vault Secret

Set-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name $SecretName `
    -SecretValue $Secret


# ==========================================
# PART 4: Retrieve Key Vault Information
# ==========================================

# 4. Retrieve Existing Key Vault
# Gets the Vault URI required to construct the Secret URI.

$kv = Get-AzKeyVault `
    -VaultName $KeyVaultName `
    -ResourceGroupName $ResourceGroupName


# ==========================================
# PART 5: Create Key Vault Reference
# ==========================================

# 5. Construct Secret URI

$SecretUri = "$($kv.VaultUri)secrets/$SecretName"


# 6. Create Key Vault Reference

$KeyVaultReference = "@Microsoft.KeyVault(SecretUri=$SecretUri)"


# ==========================================
# PART 6: Configure Function App
# ==========================================

# 7. Register Key Vault Reference in Function App Settings

Update-AzFunctionAppSetting `
    -Name $FunctionAppName `
    -ResourceGroupName $ResourceGroupName `
    -AppSetting @{
        $SecretName = $KeyVaultReference
    } `
    -Force


# ==========================================
# PART 7: Verify Function App Settings
# ==========================================

# 8. Retrieve Function App Application Settings

$Settings = Get-AzFunctionAppSetting `
    -Name $FunctionAppName `
    -ResourceGroupName $ResourceGroupName


# 9. Display Application Setting Names

$Settings.Keys

# 10. Check Service Bus Connection Key Vault Reference

$Settings["ServiceBusConnection"]

# 11. Check Key Vault Reference Resolution Status

$App = Get-AzWebApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName

$App.SiteConfig.AppSettings |
    Where-Object Name -eq $SecretName |
    Select-Object Name, Value

# 12. Construct Azure REST API URI

$Uri = "https://management.azure.com/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/config/configreferences/appsettings?api-version=2022-03-01"

# 13. Retrieve Key Vault Reference Resolution Status

$result = Invoke-AzRestMethod -Method GET -Uri $Uri

# 14. Display Resolution Details

$result.Content | ConvertFrom-Json |
    ConvertTo-Json -Depth 10