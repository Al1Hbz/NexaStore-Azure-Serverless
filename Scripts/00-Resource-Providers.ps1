
# ==========================================
# Lab02 - Azure Resource Providers
# ==========================================

# 1. Check Service Bus Resource Provider Status

$Provider = Get-AzResourceProvider -ProviderNamespace Microsoft.ServiceBus

$Provider | Select-Object ProviderNamespace, RegistrationState

# 2. Register Resource Provider if Not Registered

if ($Provider.RegistrationState -ne "Registered") {

    Write-Host "Registering Service Bus Resource Provider..." -ForegroundColor Cyan

    Register-AzResourceProvider -ProviderNamespace Microsoft.ServiceBus

}
else {

    Write-Host "Service Bus Resource Provider is already registered!" -ForegroundColor Green

}

# ==========================================

# 1. Check Application Insights Resource Provider Status

$Provider = Get-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights

$Provider | Select-Object ProviderNamespace, RegistrationState


# 2. Register Resource Provider if Not Registered

if ($Provider.RegistrationState -ne "Registered") {

    Write-Host "Registering Application Insights Resource Provider..." -ForegroundColor Cyan

    Register-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights

}
else {

    Write-Host "Application Insights Resource Provider is already registered!" -ForegroundColor Green

}

# ==========================================

# 1. Check Event Grid Resource Provider Status


$Provider = Get-AzResourceProvider -ProviderNamespace Microsoft.EventGrid

$Provider | Select-Object ProviderNamespace, RegistrationState


# 2. Register Resource Provider if Not Registered

if ($Provider.RegistrationState -ne "Registered") {

    Write-Host "Registering Event Grid Resource Provider..." -ForegroundColor Cyan

    Register-AzResourceProvider -ProviderNamespace Microsoft.EventGrid

}
else {

    Write-Host "Event Grid Resource Provider is already registered!" -ForegroundColor Green

}

# ==========================================

