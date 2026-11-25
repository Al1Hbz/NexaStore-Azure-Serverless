
# ==========================================
# Azure Lab 02 - Function App Setup
# ==========================================

# IMPORTANT:
# Change this path according to your own
# project directory and drive letter.

$ProjectPath = "H:\Azure\Projects\Azure-Lab-02\OrderProcessor"

# Create project directory
mkdir $ProjectPath -Force

# Navigate to project directory
cd $ProjectPath

# Initialize Azure Functions project
func init --worker-runtime dotnet-isolated --target-framework net10.0

# Build the project
dotnet build

# Add Azure Service Bus Extension
dotnet add package Microsoft.Azure.Functions.Worker.Extensions.ServiceBus

# Verify installed packages
dotnet list package

# Create Service Bus Queue Trigger Function
func new --template "ServiceBusQueueTrigger" --name ProcessOrder

# Define Service Bus variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$NamespaceName     = "sb-lab02-dev"
$Location          = "centralus"

# Retrieve Service Bus Authorization Rules
Get-AzServiceBusAuthorizationRule `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName

# Retrieve the Authorization Rule keys
$SenderKey = Get-AzServiceBusKey `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name "test-sender"

# Extract the Primary Connection String
$SenderConnectionString = $SenderKey.PrimaryConnectionString

# Verify that the Connection String is not empty
$SenderConnectionString.Length

# Navigate to Azure Lab 02 project directory
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02

# Create a new .NET Console application named OrderSender
dotnet new console -n OrderSender

# Navigate to the OrderSender project directory
cd OrderSender

# Install Azure Service Bus SDK
dotnet add package Azure.Messaging.ServiceBus

# IMPORTANT - MANUAL CODE EDIT REQUIRED:
# Navigate to the OrderProcessor project directory:
# H:\Azure\Projects\Azure-Lab-02\OrderProcessor
# Change this path according to your own
#
# Open Program.cs and replace its content with the
# OrderProcessor C# code provided separately.
#
# This code reads the Service Bus connection string
# from the SB_CONNECTION_STRING environment variable
# and sends a sample order message to the "orders-queue"
# Service Bus queue.

# Build the OrderProcessor Azure Functions project
# to verify that the code and package references compile successfully.
dotnet build

# Define the Azure Resource Group and Function App names
$ResourceGroupName = "rg-azlab02-dev-centralus"
$FunctionAppName   = "func-lab2-dev-09"

# Retrieve Application Insights resources and display their names and connection strings
Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName |
    Select-Object Name, ConnectionString

# Define Function App configuration
$ResourceGroupName = "rg-azlab02-dev-centralus"
$FunctionAppName = "func-lab2-dev-09"

# Retrieve the Application Insights resource
# matching the specified resource name
$ai = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName |
    Where-Object { $_.Name -eq "appi-lab2-dev-09" }

# Configure the Function App to send telemetry to Application Insights
Update-AzFunctionAppSetting `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName `
    -AppSetting @{
        "APPLICATIONINSIGHTS_CONNECTION_STRING" = $ai.ConnectionString
    }

# Publish the updated Azure Functions project
# to the existing Function App
func azure functionapp publish $FunctionAppName

# Retrieve the Service Bus Sender Authorization Rule keys from Azure
$SenderKey = Get-AzServiceBusKey `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name "test-sender"

# Set the Primary Connection String as an Environment Variable
$env:SB_CONNECTION_STRING = $SenderKey.PrimaryConnectionString

# IMPORTANT - MANUAL CODE EDIT REQUIRED:
# Open OrderSender/Program.cs and replace its default content
# with the OrderSender C# code provided separately.
#
# This code is responsible for:
# - Reading the Service Bus connection string from an environment variable.
# - Creating an order and serializing it into JSON.
# - Sending the order message to the "orders-queue" queue.
#
# NOTE:
# The Program.cs code is maintained separately from this
# PowerShell setup script because it belongs to the OrderSender
# application, not the infrastructure setup commands.

# Navigate to the OrderSender project directory
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderSender

# Build the OrderSender project
dotnet build

# Run the OrderSender console application
# to send a sample order message to the Service Bus queue
dotnet run

# Expected output after successful execution:
# Order sent successfully: <Generated OrderId>
#
# The OrderId is generated automatically for each order.
# This message confirms that the OrderSender application
# successfully sent the order message to the Service Bus queue.


# ==========================================


# IMPORTANT:
# After completing the previous steps, open:
# Azure Portal > Application Insights > appi-lab2-dev-09 > Logs
#
# Execute the following KQL query to verify
# telemetry records generated during the last 30 minutes:
#
# union withsource=TableName traces, requests, exceptions, customEvents
# | where timestamp > ago(30m)
# | summarize Records = sum(itemCount) by TableName
# | order by Records desc
#
# NOTE:
# This is a KQL query, not a PowerShell command.
# Run it manually inside the Application Insights Logs interface.


# ==========================================


# IMPORTANT:
# Return to Azure Portal > Application Insights > Logs
#
# Execute the following KQL query to find logs
# related to the OrderProcessor Function during the last 60 minutes:
#
# traces
# | where timestamp > ago(60m)
# | where message contains "Message ID"
#     or message contains "Message Body"
#     or message contains "ProcessOrder"
# | project timestamp, message, severityLevel
# | order by timestamp desc
#
# NOTE:
# This is a KQL query, not a PowerShell command.
# Run it manually inside the Application Insights Logs interface.

# EXPECTED RESULTS:
#
# After running the query, look for:
#
# - "ProcessOrder": Indicates that logs related to the
#   OrderProcessor Function have been recorded.
#
# - "Message ID": Helps identify the specific Service Bus
#   message received by the Function.
#
# - "Message Body": Shows log entries containing the
#   received order message content.
#
# - timestamp: Shows when each log entry was generated.
#
# - severityLevel: Indicates the severity of the log entry.
#
# IMPORTANT:
# Finding these logs indicates that the Function has received
# and logged information about the message.
# Check for successful processing logs or errors to determine
# whether the order was actually processed successfully.