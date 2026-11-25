# ==========================================
# 1. Check and Install the Azure Event Grid Module
# ==========================================

# Check whether the Az.EventGrid module is installed.
if (-not (Get-Module -ListAvailable -Name Az.EventGrid)) {
    Install-Module Az.EventGrid -Scope CurrentUser -Repository PSGallery -Force
}

# Import the Event Grid module.
Import-Module Az.EventGrid

# ==========================================
# 2. Create an Azure Event Grid Topic
# ==========================================

# Create an Event Grid Topic for publishing custom events.
New-AzEventGridTopic `
    -Name "evgt-azlab02-dev-centralus" `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -Location "centralus" `
    -SkuName "Basic" `
    -InputSchema "EventGridSchema" `
    -PublicNetworkAccess "Enabled"

# ==========================================
# 3. Retrieve Event Grid Topic Information
# ==========================================

# Retrieve the Event Grid Topic details.
$Topic = Get-AzEventGridTopic `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -Name "evgt-azlab02-dev-centralus"

# Display the Topic name, location, status, and endpoint.
$Topic | Format-List Name, Location, ProvisioningState, Endpoint


# ==========================================
# 4. Retrieve Event Grid Topic Access Keys
# ==========================================

# Retrieve the Event Grid Topic access keys.
$TopicKeys = Get-AzEventGridTopicKey `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -Name "evgt-azlab02-dev-centralus"

if ($TopicKeys.Key1) {
    Write-Host "Event Grid key retrieved successfully." -ForegroundColor Green
}


# ==========================================
# 5. Store Event Grid Key in Azure Key Vault
# ==========================================

# Convert the Topic key into a SecureString.
$SecretValue = ConvertTo-SecureString `
    $TopicKeys.Key1 -AsPlainText -Force

# Store the Event Grid key as a Key Vault secret.
Set-AzKeyVaultSecret `
    -VaultName "kv-lab02-dev-09" `
    -Name "EventGridTopicKey" `
    -SecretValue $SecretValue

# ==========================================
# 6. Configure Event Grid Settings in Function App
# ==========================================

# Add Event Grid Topic Endpoint and Key Vault Reference to Function App.
Update-AzFunctionAppSetting `
    -Name "func-lab2-dev-09" `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -AppSetting @{
        "EventGridTopicEndpoint" = "https://evgt-azlab02-dev-centralus.centralus-1.eventgrid.azure.net/api/events"
        "EventGridTopicKey" = "@Microsoft.KeyVault(SecretUri=https://kv-lab02-dev-09.vault.azure.net/secrets/EventGridTopicKey)"
    }

# ==========================================
# 7. Verify Event Grid Key Vault Reference Resolution
# ==========================================

# Retrieve the Function App Key Vault Reference status.
$Path = "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-azlab02-dev-centralus/providers/Microsoft.Web/sites/func-lab2-dev-09/config/configreferences/appsettings?api-version=2022-03-01"

$Result = Invoke-AzRestMethod -Method GET -Path $Path

# Display the Event Grid Topic Key reference status.
($Result.Content | ConvertFrom-Json).properties.EventGridTopicKey | Format-List *

# Display the REST API response status.
$Result | Format-List StatusCode, Content

# ==========================================
# 8. Install Azure Event Grid SDK
# ==========================================

# Navigate to the OrderProcessor project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Install the Azure Event Grid SDK.
dotnet add package Azure.Messaging.EventGrid

# ==========================================
# 9. Create OutboxEvents Table
# ==========================================

# Connect to the Azure SQL Database using SQL Server Management Studio (SSMS).
# Alternatively, connect using another SQL client with the required permissions.

# Open the sqldb-lab02-dev database and execute the following SQL query:

# USE [sqldb-lab02-dev];
# GO

# Create the OutboxEvents table to store events before publishing them to Event Grid.
#
# EventId: Unique identifier for each event, generated automatically.
# OrderId: Identifier of the related order.
# EventType: Type of event associated with the order.
# Subject: Subject of the event.
# DataVersion: Event data schema version (default: 1.0).
# EventData: Event payload stored as JSON.
# CreatedAt: UTC timestamp when the event was created.
# PublishedAt: Timestamp when the event was successfully published.
# Attempts: Number of publishing attempts (default: 0).
# LastError: Details of the last publishing error.
#
# Constraints:
# PRIMARY KEY: Ensures each event has a unique EventId.
# CHECK: Ensures EventData contains valid JSON.
# UNIQUE: Prevents duplicate event types for the same order.

# CREATE TABLE dbo.OutboxEvents
# (
#     EventId UNIQUEIDENTIFIER NOT NULL
#         CONSTRAINT PK_OutboxEvents PRIMARY KEY
#         DEFAULT NEWID(),
#
#     OrderId UNIQUEIDENTIFIER NOT NULL,
#     EventType NVARCHAR(100) NOT NULL,
#     Subject NVARCHAR(255) NOT NULL,
#     DataVersion NVARCHAR(20) NOT NULL
#         CONSTRAINT DF_OutboxEvents_DataVersion DEFAULT '1.0',
#     EventData NVARCHAR(MAX) NOT NULL,
#
#     CreatedAt DATETIME2 NOT NULL
#         CONSTRAINT DF_OutboxEvents_CreatedAt DEFAULT SYSUTCDATETIME(),
#
#     PublishedAt DATETIME2 NULL,
#
#     Attempts INT NOT NULL
#         CONSTRAINT DF_OutboxEvents_Attempts DEFAULT 0,
#
#     LastError NVARCHAR(2000) NULL,
#
#     CONSTRAINT CK_OutboxEvents_EventData
#         CHECK (ISJSON(EventData) = 1),
#
#     CONSTRAINT UQ_OutboxEvents_OrderId_EventType
#         UNIQUE (OrderId, EventType)
# );

# ==========================================
# 10. Inspect the Existing Order Processing Stored Procedure
# ==========================================

# Connect to the Azure SQL Database using SQL Server Management Studio (SSMS).
# Open the sqldb-lab02-dev database before executing the query.

# Display the SQL definition of the existing stored procedure.
#
# This query retrieves the stored procedure source code
# without executing or modifying the procedure itself.
#
# It is used to review the existing order processing logic
# before integrating the Outbox Pattern.

# EXEC sp_helptext 'dbo.usp_ProcessInventoryOrder';

# Review the procedure to understand:
# - Input parameters and validation logic.
# - Product existence and stock availability checks.
# - Inventory quantity updates.
# - Transaction handling.
# - Returned execution statuses.

# This inspection helps identify where the OutboxEvents
# record should be inserted within the order processing transaction.

# ==========================================
# 11. Install Azure Functions Timer Trigger Extension
# ==========================================

# Navigate to the OrderProcessor Azure Functions project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Install the Timer Trigger extension for .NET Isolated Azure Functions.
dotnet add package Microsoft.Azure.Functions.Worker.Extensions.Timer

# This package enables the use of TimerTrigger in the Function project.
# It allows Azure Functions to execute background tasks on a scheduled basis.
#
# The Timer Trigger will be used to periodically check the OutboxEvents table
# and publish pending events to Azure Event Grid.
#
# The package reference is added to OrderProcessor.csproj.
# The extension is included automatically when the project is built and deployed.


# ==========================================
# 12. Create and Build the Outbox Publisher Function
# ==========================================

# Navigate to the OrderProcessor project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Create a new C# file named OutboxPublisher.cs.
#
# File location:
# Change this path according to your own
# H:\Azure\Projects\Azure-Lab-02\OrderProcessor\OutboxPublisher.cs

# Copy the final OutboxPublisher implementation
# from the previously prepared project source file
# into OutboxPublisher.cs.

# Build the OrderProcessor project to verify the implementation.
dotnet build


# ==========================================
# 13. Create Outbox Event Management Stored Procedures
# ==========================================

# Connect to the Azure SQL Database using SQL Server Management Studio (SSMS).
# Open the sqldb-lab02-dev database.
#
# USE [sqldb-lab02-dev];
# GO
#
# CREATE OR ALTER PROCEDURE dbo.usp_GetPendingOutboxEvents
# AS
# BEGIN
#     SET NOCOUNT ON;
#
#     SELECT TOP (10)
#         EventId, EventType, Subject, DataVersion,
#         EventData, Attempts
#     FROM dbo.OutboxEvents
#     WHERE PublishedAt IS NULL
#     ORDER BY CreatedAt ASC;
# END;
# GO
#
# CREATE OR ALTER PROCEDURE dbo.usp_MarkOutboxEventPublished
#     @EventId UNIQUEIDENTIFIER
# AS
# BEGIN
#     SET NOCOUNT ON;
#
#     UPDATE dbo.OutboxEvents
#     SET PublishedAt = SYSUTCDATETIME(),
#         Attempts = Attempts + 1,
#         LastError = NULL
#     WHERE EventId = @EventId
#       AND PublishedAt IS NULL;
# END;
# GO
#
# CREATE OR ALTER PROCEDURE dbo.usp_RecordOutboxEventFailure
#     @EventId UNIQUEIDENTIFIER,
#     @Error NVARCHAR(2000)
# AS
# BEGIN
#     SET NOCOUNT ON;
#
#     UPDATE dbo.OutboxEvents
#     SET Attempts = Attempts + 1,
#         LastError = @Error
#     WHERE EventId = @EventId
#       AND PublishedAt IS NULL;
# END;
# GO
#
# GRANT EXECUTE ON dbo.usp_GetPendingOutboxEvents TO orderprocessor_app;
# GRANT EXECUTE ON dbo.usp_MarkOutboxEventPublished TO orderprocessor_app;
# GRANT EXECUTE ON dbo.usp_RecordOutboxEventFailure TO orderprocessor_app;
# GO

# ==========================================
# 14. Test Pending Outbox Events Retrieval
# ==========================================

# Connect to the sqldb-lab02-dev database using SSMS.

# Execute the stored procedure to retrieve pending Outbox events.
# This query returns up to 10 unpublished events,
# ordered by their creation time.

# EXEC dbo.usp_GetPendingOutboxEvents;

# Review the returned records and verify:
# - EventId
# - EventType
# - Subject
# - DataVersion
# - EventData
# - Attempts

# ==========================================
# 15. Deploy the Azure Function App
# ==========================================

# Navigate to the OrderProcessor project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Publish the Azure Functions project to Azure.
func azure functionapp publish func-lab2-dev-09

# ==========================================
# 16. Restore, Configure and Run OrderSender
# ==========================================

# Navigate to the OrderSender project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderSender

# Restore the OrderSender file from the correct reference version.
# Replace the modified test version with the original reference file.

# Check the existing Service Bus environment variable.
[Environment]::GetEnvironmentVariable("SB_CONNECTION_STRING", "User")

# Retrieve the Primary Connection String for the test-sender authorization rule.
$SenderKey = Get-AzServiceBusKey `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -NamespaceName "sb-lab02-dev" `
    -Name "test-sender"

# Verify that the connection string was retrieved successfully.
if ($SenderKey.PrimaryConnectionString) {
    "Sender connection string retrieved successfully."
} else {
    "Connection string is empty."
}

# Save the connection string permanently at User level
# and configure it for the current PowerShell session.
[Environment]::SetEnvironmentVariable("SB_CONNECTION_STRING", $SenderKey.PrimaryConnectionString, "User")
$env:SB_CONNECTION_STRING = $SenderKey.PrimaryConnectionString

# Verify the environment variable configuration.
if ($env:SB_CONNECTION_STRING) { "Configured" } else { "Missing" }

# Run the OrderSender application.
dotnet run

# ==========================================
# 17. Verify Order Processing and Outbox Publishing
# ==========================================

# Copy the Order ID generated by the OrderSender application.
# Use the Order ID to retrieve the corresponding Outbox event.

# Connect to the sqldb-lab02-dev database using SSMS.

# DECLARE @OrderId UNIQUEIDENTIFIER = 'YOUR_ORDER_ID';

# SELECT
#     EventId,
#     OrderId,
#     EventType,
#     EventData,
#     CreatedAt,
#     PublishedAt,
#     Attempts,
#     LastError
# FROM dbo.OutboxEvents
# WHERE OrderId = @OrderId;

# Wait approximately one minute for the Outbox Publisher
# Timer Trigger to execute.

# Execute the same query again to verify the publishing result.
