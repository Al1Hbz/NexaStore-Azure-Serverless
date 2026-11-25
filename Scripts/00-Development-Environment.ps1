
# ==========================================
# Azure Lab 02 - Development Environment Setup
# ==========================================

# Install Azure Functions Core Tools
winget install --exact --id Microsoft.Azure.FunctionsCoreTools

# Add NuGet Package Source
dotnet nuget add source https://api.nuget.org/v3/index.json --name nuget.org
