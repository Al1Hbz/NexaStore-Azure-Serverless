
# ==========================================
# Lab02 - Service Bus & Function Integration
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$NamespaceName     = "sb-lab02-dev"
$AuthorizationRule = "func-listen"


# ==========================================
# PART 1: Shared Access Policy
# ==========================================

# 1. Create Shared Access Policy
# Creates a Namespace-level Authorization Rule
# with Listen permission for Azure Function.

$Policy = New-AzServiceBusAuthorizationRule `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $AuthorizationRule `
    -Rights @("Listen") `
    -ErrorAction Stop


# ==========================================
# PART 2: Verify Shared Access Policy
# ==========================================

# 2. Retrieve and Verify Authorization Rule
# Displays the Policy name and assigned permissions.

Get-AzServiceBusAuthorizationRule `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $AuthorizationRule |
    Format-List Name, Rights
