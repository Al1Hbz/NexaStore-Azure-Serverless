# NexaStore – Serverless Order Processing on Azure

A serverless, event-driven order processing system built with Microsoft Azure, Bicep, and PowerShell. This project demonstrates asynchronous message processing, reliable event publishing using the Transactional Outbox Pattern, and cloud infrastructure deployment through Infrastructure as Code (IaC).

## Architecture Overview

NexaStore uses an event-driven architecture to process customer orders asynchronously and trigger notification workflows.

### Order Processing

- **Azure Service Bus:** Receives customer orders through the `orders-queue` using Peek-Lock message handling.
- **Azure Functions – ProcessOrder:** Processes incoming orders, performs validation, checks inventory, and interacts with Azure SQL Database.
- **Azure SQL Database:** Stores order and inventory data, including an Outbox table for reliable event publishing.

### Event Publishing – Outbox Pattern

- **Azure Functions – OutboxPublisher:** Runs independently using a Timer Trigger every minute to retrieve pending events from the SQL Outbox table.
- **Azure Event Grid:** Receives and distributes published events, such as `OrderCompleted`.
- **Azure Logic Apps:** Handles the notification workflow through an integrated Gmail connector.

### Monitoring & Security

- **Azure Application Insights:** Collects application telemetry.
- **Log Analytics Workspace:** Provides centralized monitoring and log analysis.
- **Azure Key Vault:** Provisioned for secure secret management.

## Azure Components

| Category | Resources |
|---|---|
| Compute | Azure Functions (ProcessOrder, OutboxPublisher) |
| Messaging | Azure Service Bus |
| Event Distribution | Azure Event Grid |
| Database | Azure SQL Database |
| Workflow Automation | Azure Logic Apps |
| Security | Azure Key Vault |
| Monitoring | Application Insights, Log Analytics Workspace |

## Repository Structure

- `bicep/` – Azure infrastructure deployment templates.
- `scripts/` – PowerShell scripts for provisioning and configuring Azure resources.
- `src/` – Application source code and Azure Functions.
- `architecture/` – Application architecture diagrams.
- `docs/` – Additional project documentation.

## Deployment

The Azure infrastructure is deployed using **Bicep** and **Azure PowerShell**.

### Prerequisites

- An active Azure subscription.
- Azure PowerShell (`Az` modules).
- Bicep CLI.
- Appropriate Azure permissions.

### Deploy with Bicep

```powershell
# Connect to Azure
Connect-AzAccount

# Set deployment variables
$ResourceGroupName = "rg-azlab02-dev-centralus"
$Location = "centralus"

# Create Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Deploy Bicep template
New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile ".\bicep\main.bicep"
```

> **Note:** If your Bicep template contains required parameters without default values, provide them through the deployment command or a parameter file.

### PowerShell Scripts

The `scripts/` directory contains individual PowerShell scripts for creating and configuring Azure resources.

Review the variables and prerequisites in each script before execution.

> **Security:** Never commit passwords, connection strings, API keys, access tokens, or other sensitive configuration values to the repository. Local configuration files such as `local.settings.json` should remain excluded through `.gitignore`.

## Design Decisions

- **Asynchronous Processing:** Azure Service Bus decouples order submission from order processing, improving scalability and reducing dependencies between application components.
- **Transactional Outbox Pattern:** Stores events in the same database as business data before publishing them, helping prevent event loss when database transactions and event publishing are not part of a single distributed transaction.
- **Timer-Based Publishing:** OutboxPublisher independently polls pending events every minute, separating event publishing from the main order processing function.
- **Serverless Architecture:** Azure Functions provide event-driven execution without requiring dedicated application server management.
- **Dead-Letter Handling:** Uses the built-in Service Bus Dead-Letter Subqueue to isolate messages that cannot be successfully processed.

## Tested Scenarios & Verification

End-to-end and failure-handling scenarios were validated using SQL queries, Application Insights KQL logs, Azure Service Bus metrics, and Gmail notifications. Test evidence is organized under `docs/test-results/`.

| Test Case | Scenario | Expected Behavior | Verification Evidence |
|---|---|---|---|
| **TC-01** | **End-to-End Order Processing (Happy Path)** | Order is processed, inventory is updated, event is recorded in `OutboxEvents` (`Attempts = 1`, `LastError = NULL`), published to Event Grid, and triggers a confirmation email via Logic Apps. | SQL `OutboxEvents` query, Logic App Run History, and Gmail Sent/Inbox confirmation. |
| **TC-02** | **Idempotency / Duplicate Order** | Re-submitting an existing `OrderId` is detected as `ALREADY_PROCESSED`, preventing duplicate inventory deduction or duplicate event generation. | Application Insights trace logs confirming duplicate detection without inventory changes. |
| **TC-03** | **Insufficient Stock Handling** | Orders exceeding available product inventory are rejected with `INSUFFICIENT_STOCK` without corrupting inventory state. | Application Insights trace logs showing rejected order status. |
| **TC-04** | **Event Grid Publish Failure & Outbox Retry** | Simulated publishing failures (`TEST_FAILURE`) are logged while events remain safely stored in the SQL Outbox table and are successfully published on subsequent timer runs. | Application Insights exception/trace logs showing initial `TEST_FAILURE` followed by successful recovery publish. |
| **TC-05** | **Dead-Letter Queue (DLQ) Isolation** | Malformed or unprocessable messages are isolated into the Service Bus Dead-Letter subqueue instead of blocking `orders-queue`. | Service Bus Queue overview showing messages routed to the Dead-Letter subqueue. |

## Security & Networking Considerations

The current implementation uses application configuration settings and secrets for service connectivity. Azure Key Vault is provisioned for secure secret management.

For a production-grade deployment, the following improvements are recommended:

### Identity & Access Management

- **Microsoft Entra ID:** Use Microsoft Entra ID for authentication and identity management.
- **Managed Identity:** Prefer Managed Identities over manually managed credentials, connection strings, and access keys wherever supported.
- **Azure RBAC:** Apply Role-Based Access Control (RBAC) following the principle of least privilege, granting each service only the permissions it requires.

> **Current Implementation:** Due to access and permission limitations within my university-managed Azure tenant, I could not fully implement the recommended Managed Identity and RBAC-based authentication approach. Therefore, the current implementation relies on application secrets and service keys. Azure Key Vault is provisioned for secure secret management.

### Network Security

- **Private Endpoints:** Use Azure Private Endpoints to establish private connectivity to supported Azure PaaS services, avoiding exposure through their public endpoints.
- **Network Isolation:** Restrict public network access wherever possible and use VNet Integration and private connectivity for application components.

> **Current Implementation:** For cost optimization within this learning project, Private Endpoints were not deployed. The current setup uses available public endpoints and service-specific access controls where configured.

## Key Concepts Demonstrated

- Infrastructure as Code (IaC) with Bicep.
- Azure resource provisioning with PowerShell.
- Serverless computing with Azure Functions.
- Asynchronous messaging with Azure Service Bus.
- Event-driven architecture with Azure Event Grid.
- Reliable event publishing using the Transactional Outbox Pattern.
- Workflow automation with Azure Logic Apps.
- Identity and access management concepts.
- Network security and private connectivity concepts.
- Cloud monitoring and observability.

## Project Status

This project is part of my hands-on Azure cloud engineering portfolio, focusing on serverless architectures, infrastructure automation, secure cloud design, and reliable event-driven application development.
