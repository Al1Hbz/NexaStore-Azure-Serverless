# ==========================================
# Lab02 - Resource Group
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Cyan

New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# ==========================================
# PART 2: Verification
# ==========================================

# 2. Verify Resource Group Creation
# Displays the Resource Group name, location, and provisioning state.

$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName

$ResourceGroup | Format-List ResourceGroupName, Location, ProvisioningState