
# ==========================================
# Lab02 - Azure Function App
# ==========================================

# Variables
$ResourceGroupName  = "rg-azlab02-dev-centralus"
$Location           = "centralus"
$StorageAccountName = "stlab02dev09"
$FunctionAppName    = "func-lab2-dev-09"
$Runtime            = "dotnet-isolated"
$RuntimeVersion     = "10"


# ==========================================
# PART 1: Azure Function App
# ==========================================

# 1. Create Azure Function App
# Creates a Windows-based Function App using .NET Isolated Runtime.

New-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName `
    -StorageAccountName $StorageAccountName `
    -Location $Location `
    -Runtime $Runtime `
    -RuntimeVersion $RuntimeVersion `
    -FunctionsVersion "4" `
    -OSType "Windows" `
    -ErrorAction Stop


# ==========================================
# PART 2: Configure Managed Identity
# ==========================================

# 2. Enable System-Assigned Managed Identity
# Assigns an identity to the Function App
# so it can authenticate with Azure services.

Update-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName `
    -IdentityType SystemAssigned


# ==========================================
# PART 3: Verification
# ==========================================

# 3. Verify Function App
# Lists Function Apps in the specified Resource Group.
# Displays their name, runtime, runtime version, and state.

Get-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName |
    Format-Table Name, Runtime, RuntimeVersion, State
