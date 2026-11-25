# ==========================================
# Lab02 - Azure SQL Infrastructure
# ==========================================

# PART 1: Create SQL Server

# 1. Variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location          = "centralus"
$SqlServerName     = "sqlserver-azlab02-dev-09"
$AdminUser         = "sqladminuser"

# 2. Get SQL Administrator Credentials
$Credential = Get-Credential -UserName $AdminUser -Message "Enter SQL Admin Password"

# 3. Define SQL Server Parameters
$ServerParams = @{
    ResourceGroupName           = $ResourceGroupName
    ServerName                  = $SqlServerName
    Location                    = $Location
    SqlAdministratorCredentials = $Credential
    ServerVersion               = "12.0"
}

# 4. Create SQL Server
Write-Host "Creating Azure SQL Server..." -ForegroundColor Cyan

$SqlServer = New-AzSqlServer @ServerParams -ErrorAction Stop

# ==========================================
# PART 2: Create SQL Database
# ==========================================

# 1. Variables
$DatabaseName = "sqldb-lab02-dev"

# 2. Define Database Parameters
$DbParams = @{
    ResourceGroupName = $ResourceGroupName
    ServerName        = $SqlServerName
    DatabaseName      = $DatabaseName
    Edition           = "GeneralPurpose"
    ComputeGeneration = "Gen5"
    VCore             = 1
    ComputeModel      = "Serverless"
    MinimumCapacity   = 0.5
    AutoPauseDelayInMinutes = 15
}

# 3. Create SQL Database
Write-Host "Creating SQL Database..." -ForegroundColor Cyan

$Database = New-AzSqlDatabase @DbParams -ErrorAction Stop

# ==========================================
# PART 3: Verification
# ==========================================

# 1. Verify SQL Server Creation
# Displays the Server name, location, and state.

$SqlServer = Get-AzSqlServer `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName

$SqlServer | Format-List ServerName, Location, State

# 2. Verify SQL Database Creation
# Displays the Database name, location, status, and edition.

$Database = Get-AzSqlDatabase `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $SqlServerName `
    -DatabaseName $DatabaseName

$Database | Format-List DatabaseName, Location, Status, Edition