
# ==========================================
# Lab02 - Azure Service Bus
# ==========================================

# Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"
$NamespaceName     = "sb-lab02-dev"
$QueueName         = "orders-queue"


# ==========================================
# PART 1: Service Bus Namespace
# ==========================================

# 1. Create Service Bus Namespace
# Creates a new Azure Service Bus Namespace using Standard SKU.

$ns = New-AzServiceBusNamespace `
    -ResourceGroupName $ResourceGroupName `
    -Name $NamespaceName `
    -Location $Location `
    -SkuName "Standard" `
    -ErrorAction Stop


# 2. Verify Service Bus Namespace Creation
# Displays the Namespace name, location, provisioning state, and status.

$ns | Format-List Name, Location, ProvisioningState, Status


# ==========================================
# PART 2: Service Bus Queue
# ==========================================

# 3. Create Service Bus Queue
# Creates a new Queue inside the specified Service Bus Namespace.

New-AzServiceBusQueue `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $QueueName `
    -ErrorAction Stop


# 4. Verify Service Bus Queue Creation
# Lists all Queues in the Namespace and displays their names and statuses.

Get-AzServiceBusQueue `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName |
    Format-Table Name, Status
