# ==========================================
# Lab02 - Azure Storage Account
# ==========================================

# Variables
$ResourceGroupName  = "rg-azlab02-dev-centralus"
$Location           = "centralus"
$StorageAccountName = "stlab02dev09"
$SkuName            = "Standard_LRS"
$Kind               = "StorageV2"


# ==========================================
# PART 1: Storage Account
# ==========================================

# 1. Create Storage Account
# Creates a Standard General-Purpose V2 Storage Account.

$StorageAccount = New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName $SkuName `
    -Kind $Kind `
    -ErrorAction Stop


# 2. Verify Storage Account Creation
# Displays the Storage Account configuration and provisioning state.

$StorageAccount | Format-List `
    StorageAccountName, Location, Kind, Sku, ProvisioningState