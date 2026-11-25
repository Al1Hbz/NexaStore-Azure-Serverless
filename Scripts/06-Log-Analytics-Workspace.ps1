
# ==========================================
# Lab02 - Log Analytics Workspace
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"
$WorkspaceName     = "law-lab02-dev-09"
$Sku               = "PerGB2018"
$RetentionInDays   = 30


# ==========================================
# PART 1: Log Analytics Workspace
# ==========================================

# 1. Create Log Analytics Workspace
# Creates a Log Analytics Workspace inside the main Resource Group.

$Workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $ResourceGroupName `
    -Name $WorkspaceName `
    -Location $Location `
    -Sku $Sku `
    -RetentionInDays $RetentionInDays `
    -ErrorAction Stop


# ==========================================
# PART 2: Verification
# ==========================================

# 2. Verify Log Analytics Workspace Creation
# Displays the Workspace configuration and resource ID.

$Workspace | Format-List `
    Name, Location, ResourceId, Sku, RetentionInDays
