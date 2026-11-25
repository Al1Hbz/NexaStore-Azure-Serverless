
# ==========================================
# Azure Lab 02 - Function App SQL Integration
# ==========================================

# Define Azure SQL Server configuration
$ResourceGroupName = "rg-azlab02-dev-centralus"
$SqlServerName     = "sqlserver-azlab02-dev-09"

# ==========================================
# 1. Retrieve SQL Server Firewall Rules
# ==========================================

# Display existing firewall rules and their IP ranges
Get-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName |
Format-Table FirewallRuleName, StartIpAddress, EndIpAddress

# IMPORTANT ARCHITECTURE NOTE:
#
# For production environments, using Azure Private Endpoint is the recommended
# approach for securing connectivity between Azure Function App and Azure SQL.
# It provides private network communication and avoids dependency on the
# Function App's outbound IP addresses.
#
# Azure Service Endpoint is another alternative that allows access to Azure SQL
# through a VNet without manually managing outbound IP allowlists.
#
# However, this project is a learning lab focused on minimizing infrastructure
# costs. Therefore, we used SQL Server Firewall Rules with the Function App's
# possible outbound IP addresses instead of implementing VNet Integration,
# Private Endpoint, or Service Endpoint.
#
# This approach keeps the lab infrastructure simpler and more cost-effective,
# but requires maintaining the allowed IP addresses if the Function App's
# outbound IP configuration changes.

# ==========================================
# 2. Count and Inspect Firewall Rules
# ==========================================

# Retrieve all existing firewall rules
$Rules = Get-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName

# Display the total number of firewall rules
Write-Host "Number of Firewall Rules:" $Rules.Count

# Display all properties of each firewall rule
$Rules | Format-List *

# ==========================================
# 3. Check SQL Server Public Network Access
# ==========================================

# Retrieve SQL Server configuration and inspect network security settings
Get-AzSqlServer `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName |
Select-Object ServerName, PublicNetworkAccess, MinimalTlsVersion

# ==========================================
# 4. Retrieve Azure Function Outbound IP Addresses
# ==========================================

# Define Azure resources
$ResourceGroupName = "rg-azlab02-dev-centralus"
$SqlServerName     = "sqlserver-azlab02-dev-09"
$FunctionAppName   = "func-lab2-dev-09"

# Retrieve the Azure Function App resource
$FunctionResource = Get-AzResource `
    -ResourceGroupName $ResourceGroupName `
    -ResourceType "Microsoft.Web/sites" `
    -Name $FunctionAppName

# Display current and possible outbound IP addresses
$FunctionResource.Properties |
Select-Object outboundIpAddresses, possibleOutboundIpAddresses |
Format-List

# ==========================================
# 5. Retrieve and Format Possible Outbound IP Addresses
# ==========================================

# Retrieve the Azure Function App resource
$FunctionResource = Get-AzResource `
    -ResourceGroupName $ResourceGroupName `
    -ResourceType "Microsoft.Web/sites" `
    -Name $FunctionAppName

# Extract possible outbound IP addresses and split them into an array
$PossibleIPs = $FunctionResource.Properties.possibleOutboundIpAddresses -split ","

# Format each IP address as a PowerShell object and display it in a table
$PossibleIPs | ForEach-Object {
    [PSCustomObject]@{
        IP = $_.Trim()
    }
} | Format-Table -AutoSize

# Note:
# This command retrieves and displays the possible outbound IP addresses
# of the Azure Function App. These IPs may be used for SQL Server Firewall
# allowlisting to permit outbound connections from the Function App.
#
# No firewall rules are created or modified by this command.


# ==========================================
# 6. Allow Function App Outbound IPs in SQL Server Firewall
# ==========================================

# Define Azure SQL Server configuration
$ResourceGroupName = "rg-azlab02-dev-centralus"
$SqlServerName     = "sqlserver-azlab02-dev-09"

# IMPORTANT:
# Add the Function App's possible outbound IP addresses to this array.
# Replace the placeholder below with the actual IP addresses obtained
# from the previous step.
$PossibleIPs = @(
    "ADD_IP_ADDRESS_HERE"
    "ADD_IP_ADDRESS_HERE"
    # Add more IP addresses as needed
)

# Create a separate SQL Server Firewall Rule for each IP address
for ($i = 0; $i -lt $PossibleIPs.Count; $i++) {

    # Get the current IP address
    $IP = $PossibleIPs[$i]

    # Generate a unique firewall rule name for each IP
    $RuleName = "func-lab2-outbound-{0:D2}" -f ($i + 1)

    # Allow the specified IP address to access Azure SQL Server
    New-AzSqlServerFirewallRule `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $SqlServerName `
        -FirewallRuleName $RuleName `
        -StartIpAddress $IP `
        -EndIpAddress $IP
}

# NOTE:
# Each IP address is assigned its own firewall rule.
# StartIpAddress and EndIpAddress are set to the same value,
# allowing only that specific IP address.
#
# This configuration allows the Azure Function App to connect
# to Azure SQL Server through its approved outbound IP addresses.
#
# Firewall rules are created at the SQL Server level, not at
# the individual database level.

# ==========================================
# 7. Verify SQL Server Firewall Rules
# ==========================================

# Retrieve and display all SQL Server Firewall Rules with their names and allowed IP ranges.
Get-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName |
Format-Table FirewallRuleName, StartIpAddress, EndIpAddress

# Retrieve all SQL Server Firewall Rules and return the total number of rules.
(Get-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName).Count

# ==========================================
# 8. Store SQL Administrator Password in Azure Key Vault
# ==========================================

# Define Key Vault configuration
$KeyVaultName = "kv-lab02-dev-09"

# Prompt the user to enter the SQL Administrator password securely.
# The password is stored as a SecureString instead of being displayed as plain text.
$Password = Read-Host "Enter SQL Administrator Password" -AsSecureString

# Create a PSCredential object containing the SQL Administrator username and password.
$Credential = New-Object System.Management.Automation.PSCredential(
    "sqladminuser",
    $Password
)

# Extract the password from the PSCredential object as plain text
# and convert it back to SecureString for Key Vault storage.
$SecretValue = ConvertTo-SecureString `
    ($Credential.GetNetworkCredential().Password) `
    -AsPlainText -Force

# Store the SQL Administrator password as a secret in Azure Key Vault.
Set-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlAdminPassword" `
    -SecretValue $SecretValue

# Result:
# The SQL Administrator password is stored in Azure Key Vault
# under the secret name "SqlAdminPassword".
#
# Note:
# The password is temporarily converted to plain text during processing.
# Passing $Password directly to -SecretValue would avoid this unnecessary conversion.

# ==========================================
# 9. Configure Temporary Local Machine Access to Azure SQL
# ==========================================

# Retrieve the public IP address of the local machine.
# The IP address is obtained from the ipify external IP detection service.
$MyPublicIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()

# Display the detected public IP address.
$MyPublicIP

# IMPORTANT:
# Replace the placeholder below with your own public IP address.
# You can use the IP retrieved in the previous command.

# Create a temporary SQL Server Firewall Rule to allow access
# from the local machine's public IP address.
New-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName `
    -FirewallRuleName "temporary-laptop-access" `
    -StartIpAddress "ENTER_YOUR_PUBLIC_IP_HERE" `
    -EndIpAddress "ENTER_YOUR_PUBLIC_IP_HERE"

# Result:
# The local machine's public IP address is added to the SQL Server Firewall,
# allowing direct connections to Azure SQL Server from the local machine.
#
# Note:
# This rule grants access only to the specified public IP address.
# It should be removed when local access is no longer required.

# ==========================================
# 10. Connect to Azure SQL and Verify Database Access
# ==========================================

# Define Azure SQL and Key Vault configuration
$KeyVaultName = "kv-lab02-dev-09"
$DatabaseName = "sqldb-lab02-dev"
$SqlServerName = "sqlserver-azlab02-dev-09"

# Retrieve the SQL Administrator password from Azure Key Vault.
$PasswordSecret = Get-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlAdminPassword"

# Convert the SecureString secret into plain text for SQL authentication.
$SqlPassword = [System.Net.NetworkCredential]::new(
    "",
    $PasswordSecret.SecretValue
).Password

# Build the SQL connection string using the server, database, and credentials.
$ConnectionString = "Server=tcp:$SqlServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;User ID=sqladminuser;Password=$SqlPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Create a SQL connection object using the connection string.
$Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)

# Open the connection to Azure SQL Server.
$Connection.Open()

# Display a success message if the connection is established.
Write-Host "SQL CONNECTION SUCCESSFUL"


# ==========================================
# 11. Verify SQL Database Connection and Login
# ==========================================

# Create a SQL command associated with the established connection.
$Command = $Connection.CreateCommand()

# Define a query to retrieve the current database name and login identity.
$Command.CommandText = "SELECT DB_NAME() AS DatabaseName, SUSER_SNAME() AS LoginName"

# Execute the query and retrieve its results using a Data Reader.
$Reader = $Command.ExecuteReader()

# Read and display the database name and SQL login returned by the query.
while ($Reader.Read()) {
    Write-Host "Database:" $Reader["DatabaseName"]
    Write-Host "Login:" $Reader["LoginName"]
}

# Close the Data Reader after processing the query results.
$Reader.Close()

# Close the SQL connection and release associated resources.
$Connection.Close()
$Connection.Dispose()

# Clear the plain-text SQL password from the current PowerShell session.
$SqlPassword = $null


# ==========================================
# 12. Create Inventory Table in Azure SQL Database
# ==========================================

# Create a new SQL command associated with the existing database connection.
$Command = $Connection.CreateCommand()

# Define the SQL query to create the Inventory table.
$Command.CommandText = @"
CREATE TABLE dbo.Inventory
(
    ProductId NVARCHAR(50) NOT NULL PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL,
    AvailableQuantity INT NOT NULL,
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Inventory_Quantity CHECK (AvailableQuantity >= 0)
);
"@

# Execute the CREATE TABLE statement.
# ExecuteNonQuery() is used because this command does not return a result set.
$Command.ExecuteNonQuery()

# Table structure:
# ProductId: Unique product identifier and Primary Key.
# ProductName: Stores the product name.
# AvailableQuantity: Stores the available stock quantity.
# UpdatedAt: Automatically stores the current UTC timestamp when a record is inserted.
# CK_Inventory_Quantity: Prevents negative inventory quantities.
#
# Result:
# A new table named dbo.Inventory is created in the Azure SQL Database.

# ==========================================
# 13. Insert Initial Inventory Records (Data Seeding)
# ==========================================

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Define the SQL query to insert initial product records into the Inventory table.
$Command.CommandText = @"
INSERT INTO dbo.Inventory (ProductId, ProductName, AvailableQuantity)
VALUES
('LAPTOP-001', 'Gaming Laptop', 10),
('MOUSE-001', 'Wireless Mouse', 25),
('KEYBOARD-001', 'Mechanical Keyboard', 15);
"@

# Execute the INSERT statement.
# ExecuteNonQuery() returns the number of affected rows.
$Command.ExecuteNonQuery()

# Note:
# The UpdatedAt column is not explicitly included in the INSERT statement.
# SQL Server automatically assigns its value using the DEFAULT constraint:
# SYSUTCDATETIME().
#
# Result:
# Three initial product records are inserted into dbo.Inventory.
#
# Note:
# Running this INSERT statement again will cause a Primary Key violation
# because the ProductId values already exist in the table.


# ==========================================
# 14. Generate a Secure Password for the SQL Application User
# ==========================================

# Create a byte array containing 32 bytes for cryptographically secure random data.
$Bytes = New-Object byte[] 32

# Fill the byte array with cryptographically secure random values.
[System.Security.Cryptography.RandomNumberGenerator]::Fill($Bytes)

# Convert the random bytes to a Base64 string and append characters
# to satisfy common SQL password complexity requirements.
$AppSqlPassword = [Convert]::ToBase64String($Bytes) + "aA1!"

# Copy the generated SQL application user password to the clipboard.
$AppSqlPassword | Set-Clipboard

# Display a confirmation message without exposing the generated password.
Write-Host "Dedicated SQL password generated and copied to clipboard."


# ==========================================
# 15. Store the SQL Application User Password in Azure Key Vault
# ==========================================

# Define the Azure Key Vault name.
$KeyVaultName = "kv-lab02-dev-09"

# Convert the generated plain-text password into a SecureString.
$SecurePassword = ConvertTo-SecureString $AppSqlPassword -AsPlainText -Force

# Store the SQL application user password as a secret in Azure Key Vault.
Set-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlOrderProcessorPassword" `
    -SecretValue $SecurePassword

# Result:
# The SQL application user password is stored in Azure Key Vault
# under the secret name "SqlOrderProcessorPassword".
#
# Note:
# The password is temporarily held as plain text in $AppSqlPassword.
# Converting it to SecureString does not erase the original plain-text value.

# ==========================================
# 16. Create Dedicated SQL Database User Securely
# ==========================================

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Define a SQL batch to safely construct the CREATE USER statement.
$Command.CommandText = @"
DECLARE @Sql NVARCHAR(MAX);

SET @Sql =
    N'CREATE USER [orderprocessor_app] WITH PASSWORD = '
    + QUOTENAME(@Password, '''')
    + N';';

EXEC sys.sp_executesql @Sql;
"@

# Add the application password as a SQL parameter.
$Parameter = $Command.Parameters.Add(
    "@Password",
    [System.Data.SqlDbType]::NVarChar,
    128
)

# Pass the generated password separately from the SQL command text.
$Parameter.Value = $AppSqlPassword

# Execute the command to create the dedicated SQL database user.
$Command.ExecuteNonQuery()

# Clear the SQL parameter and temporary password variables.
$Parameter.Value = [DBNull]::Value
$Command.Parameters.Clear()

$AppSqlPassword = $null
$Bytes = $null

# Display a confirmation message without exposing the password.
Write-Host "Dedicated SQL user created successfully."


# ==========================================
# 17. Verify Dedicated SQL Database User
# ==========================================

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Define a query to retrieve the dedicated user information.
$Command.CommandText = @"
SELECT
    name,
    type_desc,
    authentication_type_desc
FROM sys.database_principals
WHERE name = 'orderprocessor_app';
"@

# Execute the query and retrieve the results using a Data Reader.
$Reader = $Command.ExecuteReader()

# Read and display the user information returned by the query.
while ($Reader.Read()) {
    Write-Host "User:" $Reader["name"]
    Write-Host "Type:" $Reader["type_desc"]
    Write-Host "Authentication:" $Reader["authentication_type_desc"]
}

# Close the Data Reader after processing the results.
$Reader.Close()

# Result:
# Confirms whether the orderprocessor_app database user exists
# and displays its principal type and authentication method.


# ==========================================
# 18. Create Inventory Order Processing Stored Procedure
# ==========================================

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Define the stored procedure responsible for processing inventory orders.
$Command.CommandText = @"
CREATE OR ALTER PROCEDURE dbo.usp_ProcessInventoryOrder
    @ProductId NVARCHAR(50),
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentQuantity INT;
    DECLARE @RemainingQuantity INT;
    DECLARE @Result NVARCHAR(30);

    # Validate the requested order quantity.
    IF @Quantity <= 0
    BEGIN
        SELECT
            'INVALID_QUANTITY' AS Result,
            CAST(NULL AS INT) AS RemainingQuantity;
        RETURN;
    END;

    BEGIN TRY
        # Start a transaction to ensure consistent inventory updates.
        BEGIN TRANSACTION;

        # Retrieve the current inventory quantity.
        # UPDLOCK and HOLDLOCK help prevent conflicting concurrent updates.
        SELECT @CurrentQuantity = AvailableQuantity
        FROM dbo.Inventory WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId;

        # Check whether the requested product exists.
        IF @CurrentQuantity IS NULL
        BEGIN
            SET @Result = 'PRODUCT_NOT_FOUND';
        END

        # Check whether sufficient stock is available.
        ELSE IF @CurrentQuantity < @Quantity
        BEGIN
            SET @Result = 'INSUFFICIENT_STOCK';
            SET @RemainingQuantity = @CurrentQuantity;
        END

        # Deduct the requested quantity when sufficient stock is available.
        ELSE
        BEGIN
            UPDATE dbo.Inventory
            SET
                AvailableQuantity = AvailableQuantity - @Quantity,
                UpdatedAt = SYSUTCDATETIME()
            WHERE ProductId = @ProductId;

            SET @RemainingQuantity = @CurrentQuantity - @Quantity;
            SET @Result = 'SUCCESS';
        END;

        # Commit the transaction after processing the order.
        COMMIT TRANSACTION;

        # Return the processing result and remaining stock quantity.
        SELECT
            @Result AS Result,
            @RemainingQuantity AS RemainingQuantity;
    END TRY
    BEGIN CATCH

        # Roll back the transaction if an error occurs.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        # Re-throw the original SQL error.
        THROW;
    END CATCH;
END;
"@

# Execute the CREATE OR ALTER PROCEDURE statement.
$Command.ExecuteNonQuery()


# ==========================================
# 19. Grant Execute Permission to the Dedicated SQL User
# ==========================================

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Grant the dedicated application user permission
# to execute only the inventory order processing stored procedure.
$Command.CommandText = @"
GRANT EXECUTE ON OBJECT::dbo.usp_ProcessInventoryOrder
TO [orderprocessor_app];
"@

# Execute the GRANT statement to apply the permission.
$Command.ExecuteNonQuery()

# Result:
# The orderprocessor_app user can execute
# dbo.usp_ProcessInventoryOrder.
#
# Security Note:
# No direct SELECT, INSERT, UPDATE, or DELETE permissions
# on the Inventory table are granted by this statement.
#
# The stored procedure performs inventory operations
# on behalf of the application user.


# ==========================================
# 20. Test Inventory Order Processing Scenarios
# ==========================================


# ------------------------------------------
# Test 1: Successful Inventory Order
# ------------------------------------------

# Create a SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Execute the stored procedure to order 2 units of LAPTOP-001.
$Command.CommandText = @"
EXEC dbo.usp_ProcessInventoryOrder
    @ProductId = 'LAPTOP-001',
    @Quantity = 2;
"@

# Execute the stored procedure and retrieve its result.
$Reader = $Command.ExecuteReader()

# Display the order processing result and remaining inventory quantity.
while ($Reader.Read()) {
    Write-Host "Result:" $Reader["Result"]
    Write-Host "Remaining Quantity:" $Reader["RemainingQuantity"]
}

# Close the Data Reader after retrieving the result.
$Reader.Close()

# Expected Result:
# Result: SUCCESS
# Remaining Quantity: 8
#
# Explanation:
# The initial inventory quantity is 10 units.
# The order requests 2 units, so the order is accepted.
# The remaining inventory quantity becomes 8.


# ------------------------------------------
# Test 2: Insufficient Inventory Stock
# ------------------------------------------

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Execute the stored procedure to order 9 units of LAPTOP-001.
$Command.CommandText = @"
EXEC dbo.usp_ProcessInventoryOrder
    @ProductId = 'LAPTOP-001',
    @Quantity = 9;
"@

# Execute the stored procedure and retrieve its result.
$Reader = $Command.ExecuteReader()

# Display the order processing result and remaining inventory quantity.
while ($Reader.Read()) {
    Write-Host "Result:" $Reader["Result"]
    Write-Host "Remaining Quantity:" $Reader["RemainingQuantity"]
}

# Close the Data Reader after retrieving the result.
$Reader.Close()

# Expected Result:
# Result: INSUFFICIENT_STOCK
# Remaining Quantity: 8
#
# Explanation:
# After Test 1, only 8 units remain in inventory.
# The order requests 9 units, which exceeds available stock.
# The order is rejected and the inventory quantity remains unchanged.


# ------------------------------------------
# Test 3: Product Not Found
# ------------------------------------------

# Create a new SQL command using the existing database connection.
$Command = $Connection.CreateCommand()

# Execute the stored procedure using a product ID that does not exist.
$Command.CommandText = @"
EXEC dbo.usp_ProcessInventoryOrder
    @ProductId = 'PHONE-999',
    @Quantity = 1;
"@

# Execute the stored procedure and retrieve its result.
$Reader = $Command.ExecuteReader()

# Display the order processing result and remaining inventory quantity.
while ($Reader.Read()) {
    Write-Host "Result:" $Reader["Result"]
    Write-Host "Remaining Quantity:" $Reader["RemainingQuantity"]
}

# Close the Data Reader after retrieving the result.
$Reader.Close()

# Expected Result:
# Result: PRODUCT_NOT_FOUND
# Remaining Quantity: NULL
#
# Explanation:
# The product ID PHONE-999 does not exist in dbo.Inventory.
# The order is rejected because the requested product cannot be found.
# No inventory records are modified.


# ==========================================
# 21. Authenticate Dedicated SQL Application User
# ==========================================

# Define the Azure Key Vault and SQL Database configuration.
$KeyVaultName = "kv-lab02-dev-09"
$SqlServerName = "sqlserver-azlab02-dev-09"
$DatabaseName = "sqldb-lab02-dev"

# Retrieve the dedicated application user's password from Azure Key Vault.
$AppPasswordSecret = Get-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlOrderProcessorPassword"

# Convert the retrieved SecureString password into plain text
# because SQL authentication requires the password in the connection string.
$AppSqlPassword = [System.Net.NetworkCredential]::new(
    "",
    $AppPasswordSecret.SecretValue
).Password

# Create a SQL connection string builder.
$AppConnectionStringBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder

# Configure the SQL Server address and port.
$AppConnectionStringBuilder["Data Source"] = "tcp:$SqlServerName.database.windows.net,1433"

# Specify the Azure SQL Database.
$AppConnectionStringBuilder["Initial Catalog"] = $DatabaseName

# Configure the dedicated SQL application user credentials.
$AppConnectionStringBuilder["User ID"] = "orderprocessor_app"
$AppConnectionStringBuilder["Password"] = $AppSqlPassword

# Enable encrypted communication and certificate validation.
$AppConnectionStringBuilder["Encrypt"] = $true
$AppConnectionStringBuilder["TrustServerCertificate"] = $false

# Create a SQL connection using the dedicated application user's credentials.
$AppConnection = New-Object System.Data.SqlClient.SqlConnection(
    $AppConnectionStringBuilder.ConnectionString
)

# Open the SQL connection and authenticate the application user.
$AppConnection.Open()

# Display a confirmation message after successful authentication.
Write-Host "Dedicated SQL user connected successfully."

# Clear the temporary plaintext password variable.
$AppSqlPassword = $null


# ==========================================
# 22. Test Inventory Order Processing Using Application User
# ==========================================

# Create a SQL command using the dedicated application user's connection.
$Command = $AppConnection.CreateCommand()

# Execute the inventory order processing stored procedure.
# The application user requests 2 units of MOUSE-001.
$Command.CommandText = @"
EXEC dbo.usp_ProcessInventoryOrder
    @ProductId = 'MOUSE-001',
    @Quantity = 2;
"@

# Execute the stored procedure and retrieve its result.
$Reader = $Command.ExecuteReader()

# Display the order processing result and remaining inventory quantity.
while ($Reader.Read()) {
    Write-Host "Result:" $Reader["Result"]
    Write-Host "Remaining Quantity:" $Reader["RemainingQuantity"]
}

# Close the Data Reader after retrieving the result.
$Reader.Close()

# Expected Result:
# Result: SUCCESS
# Remaining Quantity: 23
#
# Explanation:
# The initial inventory quantity of MOUSE-001 is 25 units.
# The application user requests 2 units.
# The stored procedure processes the order successfully.
# The remaining inventory quantity becomes 23.
#
# Security Verification:
# The order is processed using the orderprocessor_app database user.
# This user has EXECUTE permission on dbo.usp_ProcessInventoryOrder.
# No direct table modification permission was explicitly granted.


# ==========================================
# 23. Close Dedicated SQL Application Connection
# ==========================================

# Close the dedicated application user's SQL connection.
$AppConnection.Close()

# Dispose of the SQL connection and release associated resources.
$AppConnection.Dispose()

# Clear temporary connection-related variables.
$AppConnectionStringBuilder = $null
$AppPasswordSecret = $null
$Command = $null
$Reader = $null

# Display a confirmation message.
Write-Host "Dedicated SQL application connection closed successfully."


# ==========================================
# 24. Verify Application User Cannot Directly Update Inventory
# ==========================================

# Create a SQL command using the dedicated application user's connection.
$Command = $AppConnection.CreateCommand()

# Attempt to directly modify the inventory quantity of LAPTOP-001.
$Command.CommandText = @"
UPDATE dbo.Inventory
SET AvailableQuantity = 999
WHERE ProductId = 'LAPTOP-001';
"@

# Attempt to execute the UPDATE statement and handle the expected permission error.
try {
    $Command.ExecuteNonQuery()

    # Display a warning if the application user can directly update the table.
    Write-Host "WARNING: Direct UPDATE was allowed!"
}
catch {
    # Display the expected result if SQL Server denies the UPDATE operation.
    Write-Host "EXPECTED: Direct UPDATE was denied."

    # Display the SQL Server permission error for verification.
    Write-Host $_.Exception.Message
}

# Expected Result:
# The UPDATE operation should be denied by SQL Server.
# The application user should not have direct UPDATE permission on dbo.Inventory.
#
# Security Verification:
# The orderprocessor_app user can execute the authorized stored procedure.
# However, it cannot directly modify inventory records through UPDATE.


# ==========================================
# 25. Store SQL Application Connection String in Azure Key Vault
# ==========================================

# Define the Azure Key Vault and SQL Database configuration.
$KeyVaultName = "kv-lab02-dev-09"
$SqlServerName = "sqlserver-azlab02-dev-09"
$DatabaseName = "sqldb-lab02-dev"

# Retrieve the dedicated SQL application user's password from Azure Key Vault.
$AppPasswordSecret = Get-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlOrderProcessorPassword"

# Convert the retrieved SecureString password into plain text
# for constructing the SQL connection string.
$AppSqlPassword = [System.Net.NetworkCredential]::new(
    "",
    $AppPasswordSecret.SecretValue
).Password

# Create a SQL connection string builder.
$Builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder

# Configure the SQL Server connection details.
$Builder["Data Source"] = "tcp:$SqlServerName.database.windows.net,1433"
$Builder["Initial Catalog"] = $DatabaseName

# Configure the dedicated application user's credentials.
$Builder["User ID"] = "orderprocessor_app"
$Builder["Password"] = $AppSqlPassword

# Enable encrypted communication and certificate validation.
$Builder["Encrypt"] = $true
$Builder["TrustServerCertificate"] = $false

# Set the SQL connection timeout to 30 seconds.
$Builder["Connect Timeout"] = 30

# Convert the complete connection string into a SecureString.
$SecureConnectionString = ConvertTo-SecureString `
    $Builder.ConnectionString `
    -AsPlainText -Force

# Store the SQL connection string as a secret in Azure Key Vault.
Set-AzKeyVaultSecret `
    -VaultName $KeyVaultName `
    -Name "SqlConnectionString" `
    -SecretValue $SecureConnectionString

# Clear temporary plaintext credentials and connection string data.
$AppSqlPassword = $null
$Builder = $null
$AppPasswordSecret = $null
$SecureConnectionString = $null

# Display a confirmation message.
Write-Host "SQL Connection String stored successfully in Azure Key Vault."

# ==========================================
# 26. Configure and Verify Azure Function App Key Vault Secret Reference
# ==========================================

# Define the Function App and Resource Group configuration.
$ResourceGroupName = "rg-azlab02-dev-centralus"
$FunctionAppName = "func-lab2-dev-09"
$KeyVaultName = "kv-lab02-dev-09"

# Define the Key Vault Secret URI.
$SecretUri = "https://$KeyVaultName.vault.azure.net/secrets/SqlConnectionString"

# Configure the Function App to retrieve the SQL connection string
# through an Azure Key Vault Reference.
Update-AzFunctionAppSetting `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName `
    -AppSetting @{
        "SqlConnectionString" = "@Microsoft.KeyVault(SecretUri=$SecretUri)"
    }

# Retrieve the Function App configuration.
$Function = Get-AzFunctionApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $FunctionAppName

# Display the SqlConnectionString application setting.
$Function.ApplicationSettings["SqlConnectionString"]

# Expected Result:
# @Microsoft.KeyVault(SecretUri=https://kv-lab02-dev-09.vault.azure.net/secrets/SqlConnectionString)
#
# Explanation:
# The Function App application setting should contain a Key Vault Reference.
# The actual SQL connection string remains stored in Azure Key Vault.
#
# Note:
# This verification confirms that the reference is configured.
# It does not confirm that the Function App successfully resolved the secret.


# ==========================================
# 27. Verify Azure Function App Key Vault Reference Resolution
# ==========================================

# Define the Azure Function App and Resource Group.
$FunctionName = "func-lab2-dev-09"
$ResourceGroupName = "rg-azlab02-dev-centralus"

# Retrieve an Azure Resource Manager access token.
$Token = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"

# Convert the access token into plain text for HTTP authentication.
$AccessToken = [System.Net.NetworkCredential]::new(
    "",
    $Token.Token
).Password

# Define the Azure Resource Manager REST API endpoint
# for retrieving Function App Key Vault Reference statuses.
$Uri = "https://management.azure.com/subscriptions/<subscription-id>/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionName/config/configreferences/appsettings?api-version=2022-03-01"

# Configure the HTTP Authorization header using the Bearer token.
$Headers = @{
    Authorization = "Bearer $AccessToken"
}

# Send a GET request to retrieve the Key Vault Reference resolution status.
$Response = Invoke-RestMethod `
    -Uri $Uri `
    -Headers $Headers `
    -Method GET

# Display the resolution status of the SqlConnectionString reference.
$Response.properties.SqlConnectionString

# Display the complete API response in JSON format for inspection.
$Response | ConvertTo-Json -Depth 10

# Expected Result:
# The SqlConnectionString reference should report a successful
# resolution status, typically "Resolved".
#
# Security Verification:
# The Function App successfully resolves the SQL connection string
# reference through Azure Key Vault.
#
# Note:
# A successful resolution confirms that the Function App can retrieve
# the referenced secret. It does not independently verify SQL connectivity.


# ==========================================
# 29. Install Microsoft.Data.SqlClient NuGet Package
# ==========================================

# Navigate to the OrderProcessor Azure Function project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Add the Microsoft.Data.SqlClient NuGet package to the .NET project.
# This library provides SQL Server connectivity through classes
# such as SqlConnection, SqlCommand, and SqlDataReader.
dotnet add package Microsoft.Data.SqlClient

# Expected Result:
# Microsoft.Data.SqlClient is added as a project dependency.
# The package reference is added to the project file (.csproj).
# The project is ready to use Microsoft.Data.SqlClient for Azure SQL connectivity.


# ==========================================
# 30. Inspect Azure Function App Application Settings
# ==========================================

# Retrieve the application settings configured for the Azure Function App.
$Settings = Get-AzFunctionAppSetting `
    -ResourceGroupName "rg-azlab02-dev-centralus" `
    -Name "func-lab2-dev-09"

# Retrieve and display the SqlConnectionString application setting.
$Settings["SqlConnectionString"]

# Expected Result:
# The SqlConnectionString setting should contain the Key Vault Reference:
# @Microsoft.KeyVault(SecretUri=https://kv-lab02-dev-09.vault.azure.net/secrets/SqlConnectionString)
#
# Explanation:
# This setting allows the Function App to access the SQL connection string
# through its configured Key Vault Reference.
#
# Note:
# This command only inspects the configured application setting.
# It does not retrieve the actual secret value or verify SQL connectivity.

# ==========================================
# 31. Manually Update the Azure Function C# Code and Build the Project
# ==========================================

# IMPORTANT - MANUAL CODE EDIT REQUIRED:
# Open the ProcessOrder.cs file located in the OrderProcessor project.
# Replace or modify its existing content according to the reference
# C# implementation provided separately.
#
# The updated code is responsible for:
# - Reading the SQL connection string from the Function App
#   application setting named "SqlConnectionString".
# - Connecting to the Azure SQL Database using Microsoft.Data.SqlClient.
# - Receiving and processing incoming order requests.
# - Calling the stored procedure dbo.usp_ProcessInventoryOrder.
# - Passing the ProductId and Quantity parameters to the stored procedure.
# - Handling the result returned by SQL Server.
#
# NOTE:
# The ProcessOrder.cs file is maintained separately from this
# PowerShell setup script because it contains the application's
# C# implementation, rather than Azure infrastructure commands.
#
# IMPORTANT:
# Make sure the code matches the reference implementation before
# building the project.

# Navigate to the OrderProcessor project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Build the .NET Azure Function project.
# This command restores required dependencies if necessary,
# compiles the C# source files, and reports any build errors or warnings.
dotnet build

# Expected Result:
# The project builds successfully if the C# code and dependencies
# are correctly configured.
# A successful build confirms compilation, but does not test
# the Function App's runtime connection to Azure SQL Database.


# ==========================================
# 32. Investigate and Fix a Vulnerable NuGet Dependency
# ==========================================

# Identify why System.Security.Cryptography.Pkcs
# is included in the OrderProcessor project.
# This command displays the dependency chain responsible
# for introducing the package into the project.
dotnet nuget why OrderProcessor.csproj System.Security.Cryptography.Pkcs

# Security Finding:
# Microsoft.Data.SqlClient introduced System.Security.Cryptography.Pkcs
# as a transitive dependency.
# The resolved version was identified as vulnerable.
#
# IMPORTANT - SECURITY UPDATE REQUIRED:
# Check the latest security advisories and fixed versions
# of System.Security.Cryptography.Pkcs before updating.
# Select a currently secure version that is compatible
# with the project's Target Framework and other dependencies.
#
# Do not rely on a hardcoded package version.
# Choose the appropriate version based on the security information
# and compatibility available at the time of the update.


# Add the selected secure version as a direct dependency.
# Replace <SECURE_VERSION> with the version selected
# after reviewing the latest security advisories.
dotnet add package System.Security.Cryptography.Pkcs --version <SECURE_VERSION>


# Restore the NuGet dependencies after updating the package reference.
dotnet restore


# Build the project to verify that the updated dependencies
# do not introduce compilation errors.
dotnet build


# Verify the resolved version of System.Security.Cryptography.Pkcs.
# The --include-transitive option also displays indirect dependencies.
dotnet list OrderProcessor.csproj package --include-transitive

# Expected Result:
# System.Security.Cryptography.Pkcs should resolve to the
# selected secure version instead of the previously vulnerable version.
#
# Final Verification:
# Confirm that the resolved version is not affected by
# the relevant security advisory and that the project builds successfully.

# ==========================================
# 33. Scan NuGet Dependencies for Security Vulnerabilities
# ==========================================

# Scan direct and transitive NuGet dependencies
# and report packages with known security vulnerabilities.
dotnet list package --vulnerable --include-transitive

# Expected Result:
# Displays vulnerable packages and their affected versions,
# along with available remediation information when provided.

# ==========================================
# 34. Deploy OrderProcessor to Azure Function App
# ==========================================

# Navigate to the OrderProcessor project directory.
# Change this path according to your own
cd H:\Azure\Projects\Azure-Lab-02\OrderProcessor

# Publish the Azure Function project to the target Function App.
func azure functionapp publish func-lab2-dev-09

# Expected Result:
# The project is published to the Azure Function App:
# func-lab2-dev-09
#
# The Function App receives the deployed application code.