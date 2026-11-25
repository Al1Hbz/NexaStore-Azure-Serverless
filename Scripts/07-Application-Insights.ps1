
# ==========================================
# Step1 Lab02 - Application Insights
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"
$AppInsightsName   = "appi-lab2-dev-09"
$WorkspaceName     = "law-lab02-dev-09"


# ==========================================
# PART 1: Get Log Analytics Workspace
# ==========================================

# 1. Retrieve Existing Log Analytics Workspace
# Gets the Workspace resource ID for Application Insights integration.

$Workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $ResourceGroupName `
    -Name $WorkspaceName `
    -ErrorAction Stop


# ==========================================
# PART 2: Application Insights
# ==========================================

# 2. Create Application Insights
# Creates an Application Insights resource connected to the specified Log Analytics Workspace.

New-AzApplicationInsights `
    -ResourceGroupName $ResourceGroupName `
    -Name $AppInsightsName `
    -Location $Location `
    -Kind "web" `
    -ApplicationType "web" `
    -WorkspaceResourceId $Workspace.ResourceId `
    -ErrorAction Stop

# ==========================================
# PART 3: Verification
# ==========================================

# 3. Verify Application Insights Creation and Workspace Connection

$AppInsights = Get-AzApplicationInsights `
    -ResourceGroupName $ResourceGroupName `
    -Name $AppInsightsName

$AppInsights | Format-List `
    Name, Location, ApplicationType, WorkspaceResourceId


# ==========================================
# Step2 Lab02 - Connect Application Insights To Azure Function App
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$FunctionAppName    = "func-lab2-dev-09"
$AppInsightsName   = "appi-lab2-dev-09"


# ==========================================
# PART 1: Connect Application Insights
# ==========================================

# 1. Connect Application Insights to Function App
# Updates the existing Function App configuration
# to send monitoring telemetry to Application Insights.

Update-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName `
    -ApplicationInsightsName $AppInsightsName `
    -Force


# ==========================================
# PART 2: Verify Application Insights Connection
# ==========================================

# 2. Retrieve Function App Configuration
# Displays the Function App name, state, and Application Insights key.

Get-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName |
    Format-List Name, State, ApplicationInsightsKey
