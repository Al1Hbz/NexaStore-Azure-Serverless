@secure()
param vulnerabilityAssessments_Default_storageContainerPath string

@secure()
param sqlAdminPassword string

@secure()
param eventGridTopicKey string

@secure()
param eventGridWebhookEndpointUrl string

@secure()
param serviceBusConnection string

@secure()
param sqlConnectionString string

@secure()
param sqlOrderProcessorPassword string
param keyVaultAdminObjectId string
param keyVaultReaderObjectId string
param connections_gmail_name string = 'gmail'
param connections_gmail_1_name string = 'gmail-1'
param sites_func_lab2_dev_09_name string = 'func-lab2-dev-09'
param serverfarms_CentralUSPlan_name string = 'CentralUSPlan'
param connections_azureeventgrid_name string = 'azureeventgrid'
param vaults_kv_lab02_dev_09_name string = 'kv-lab02-dev-09'
param components_appi_lab2_dev_09_name string = 'appi-lab2-dev-09'
param workflows_logicapp_lab2_dev_09_name string = 'logicapp-lab2-dev-09'
param servers_sqlserver_azlab02_dev_09_name string = 'sqlserver-azlab02-dev-09'
param databases_sqldb_lab02_dev_name string = 'sqldb-lab02-dev'
param storageAccounts_stlab02dev09_name string = 'stlab02dev09'
param namespaces_sb_lab02_dev_name string = 'sb-lab02-dev'
param topics_evgt_azlab02_dev_centralus_name string = 'evgt-azlab02-dev-centralus'
param actionGroups_Application_Insights_Smart_Detection_name string = 'Application Insights Smart Detection'

resource topics_evgt_azlab02_dev_centralus_name_resource 'Microsoft.EventGrid/topics@2025-07-15-preview' = {
  name: topics_evgt_azlab02_dev_centralus_name
  location: 'centralus'
  sku: {
    name: 'Basic'
  }
  kind: 'Azure'
  properties: {
    minimumTlsVersionAllowed: '1.0'
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
    dataResidencyBoundary: 'WithinGeopair'
  }
}

resource actionGroups_Application_Insights_Smart_Detection_name_resource 'microsoft.insights/actionGroups@2024-10-01-preview' = {
  name: actionGroups_Application_Insights_Smart_Detection_name
  location: 'Global'
  properties: {
    groupShortName: 'SmartDetect'
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: [
      {
        name: 'Monitoring Contributor'
        roleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
        useCommonAlertSchema: true
      }
      {
        name: 'Monitoring Reader'
        roleId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Lab02 - Log Analytics Workspace
// Created in the same resource group and region as the application resources.
resource law_lab02_dev_09 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-lab02-dev-09'
  location: 'centralus'
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource components_appi_lab2_dev_09_name_resource 'microsoft.insights/components@2020-02-02' = {
  name: components_appi_lab2_dev_09_name
  location: 'centralus'
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    WorkspaceResourceId: law_lab02_dev_09.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource vaults_kv_lab02_dev_09_name_resource 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaults_kv_lab02_dev_09_name
  location: 'centralus'
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: keyVaultAdminObjectId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: keyVaultReaderObjectId
        permissions: {
          keys: []
          secrets: [
            'Get'
            'List'
          ]
          certificates: []
          storage: []
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    publicNetworkAccess: 'Enabled'
  }
}


resource namespaces_sb_lab02_dev_name_resource 'Microsoft.ServiceBus/namespaces@2026-07-01-preview' = {
  name: namespaces_sb_lab02_dev_name
  location: 'centralus'
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    ipAddressType: 'IPv4'
    platformCapabilities: {
      confidentialCompute: {
        mode: 'Disabled'
      }
    }
    geoDataReplication: {
      maxReplicationLagDurationInSeconds: 0
      locations: [
        {
          locationName: 'centralus'
          roleType: 'Primary'
        }
      ]
    }
    premiumMessagingPartitions: 0
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
  }
}

resource servers_sqlserver_azlab02_dev_09_name_resource 'Microsoft.Sql/servers@2026-08-01-preview' = {
  name: servers_sqlserver_azlab02_dev_09_name
  location: 'centralus'
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    retentionDays: -1
  }
}

resource storageAccounts_stlab02dev09_name_resource 'Microsoft.Storage/storageAccounts@2026-06-01' = {
  name: storageAccounts_stlab02dev09_name
  location: 'centralus'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowCrossTenantDelegationSas: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_0'
    allowBlobPublicAccess: false
    networkAcls: {
      ipv6Rules: []
      bypass: 'None'
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource connections_azureeventgrid_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_azureeventgrid_name
  location: 'centralus'
  properties: {
    displayName: 'Gmail connection'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    nonSecretParameterValues: {
      'token:tenantId': tenant().tenantId
      'token:grantType': 'code'
    }
    createdTime: '2026-11-11T11:47:25.1643235Z'
    changedTime: '2026-11-11T14:49:58.3532946Z'
    api: {
      name: connections_azureeventgrid_name
      displayName: 'Azure Event Grid'
      description: 'Azure Event Grid is an eventing backplane that enables event based programing with pub/sub semantics and reliable distribution & delivery for all services in Azure as well as third parties.'
      iconUri: 'https://static.powerapps.com/resource/ppcr/releases/v1.0.1819/1.0.1819.4795/${connections_azureeventgrid_name}/icon.png'
      brandColor: '#0072c6'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/centralus/managedApis/${connections_azureeventgrid_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

resource connections_gmail_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_gmail_name
  location: 'centralus'
  properties: {
    displayName: '${connections_gmail_name}-lab02-connection'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    createdTime: '2026-11-11T12:02:41.7087592Z'
    changedTime: '2026-11-11T12:03:05.7839883Z'
    api: {
      name: connections_gmail_name
      displayName: 'Gmail'
      description: 'Gmail is a web-based email service from Google. With the Gmail connector, you can perform actions such as send or receive e-mail messages, and trigger flows on new e-mails.'
      iconUri: 'https://static.powerapps.com/resource/ppcr/releases/v1.0.1819/1.0.1819.4795/${connections_gmail_name}/icon.png'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/centralus/managedApis/${connections_gmail_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: '${environment().resourceManager}subscriptions/${subscription().subscriptionId}/resourceGroups/rg-azlab02-dev-centralus/providers/Microsoft.Web/connections/${connections_gmail_name}/extensions/proxy/TestConnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

resource connections_gmail_1_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_gmail_1_name
  location: 'centralus'
  properties: {
    displayName: 'gmail-Lab02-custom'
    statuses: [
      {
        status: 'Connected'
      }
    ]
    customParameterValues: {}
    createdTime: '2026-11-11T12:49:57.6115222Z'
    changedTime: '2026-11-11T14:03:00.5610611Z'
    api: {
      name: 'gmail'
      displayName: 'Gmail'
      description: 'Gmail is a web-based email service from Google. With the Gmail connector, you can perform actions such as send or receive e-mail messages, and trigger flows on new e-mails.'
      iconUri: 'https://static.powerapps.com/resource/ppcr/releases/v1.0.1819/1.0.1819.4795/gmail/icon.png'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/centralus/managedApis/gmail'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: '${environment().resourceManager}subscriptions/${subscription().subscriptionId}/resourceGroups/rg-azlab02-dev-centralus/providers/Microsoft.Web/connections/${connections_gmail_1_name}/extensions/proxy/TestConnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

resource serverfarms_CentralUSPlan_name_resource 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: serverfarms_CentralUSPlan_name
  location: 'Central US'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 0
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
    asyncScalingEnabled: false
  }
}


resource topics_evgt_azlab02_dev_centralus_name_LogicAppb27144d8_218d_467a_8d21_1cb3b465ee21 'Microsoft.EventGrid/topics/eventSubscriptions@2025-07-15-preview' = {
  parent: topics_evgt_azlab02_dev_centralus_name_resource
  name: 'LogicAppb27144d8-218d-467a-8d21-1cb3b465ee21'
  properties: {
    destination: {
      properties: {
        endpointUrl: eventGridWebhookEndpointUrl
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      includedEventTypes: [
        'OrderCompleted'
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

resource components_appi_lab2_dev_09_name_degradationindependencyduration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'degradationindependencyduration'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'degradationindependencyduration'
      DisplayName: 'Degradation in dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_degradationinserverresponsetime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'degradationinserverresponsetime'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'degradationinserverresponsetime'
      DisplayName: 'Degradation in server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_digestMailConfiguration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'digestMailConfiguration'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'digestMailConfiguration'
      DisplayName: 'Digest Mail Configuration'
      Description: 'This rule describes the digest mail preferences'
      HelpUrl: 'www.homail.com'
      IsHidden: true
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_billingdatavolumedailyspikeextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_billingdatavolumedailyspikeextension'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_billingdatavolumedailyspikeextension'
      DisplayName: 'Abnormal rise in daily data volume (preview)'
      Description: 'This detection rule automatically analyzes the billing data generated by your application, and can warn you about an unusual increase in your application\'s billing costs'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/tree/master/SmartDetection/billing-data-volume-daily-spike.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_canaryextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_canaryextension'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_canaryextension'
      DisplayName: 'Canary extension'
      Description: 'Canary extension'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/'
      IsHidden: true
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_exceptionchangeextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_exceptionchangeextension'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_exceptionchangeextension'
      DisplayName: 'Abnormal rise in exception volume (preview)'
      Description: 'This detection rule automatically analyzes the exceptions thrown in your application, and can warn you about unusual patterns in your exception telemetry.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/abnormal-rise-in-exception-volume.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_memoryleakextension 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_memoryleakextension'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_memoryleakextension'
      DisplayName: 'Potential memory leak detected (preview)'
      Description: 'This detection rule automatically analyzes the memory consumption of each process in your application, and can warn you about potential memory leaks or increased memory consumption.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/tree/master/SmartDetection/memory-leak.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_securityextensionspackage 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_securityextensionspackage'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_securityextensionspackage'
      DisplayName: 'Potential security issue detected (preview)'
      Description: 'This detection rule automatically analyzes the telemetry generated by your application and detects potential security issues.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/application-security-detection-pack.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_extension_traceseveritydetector 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'extension_traceseveritydetector'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'extension_traceseveritydetector'
      DisplayName: 'Degradation in trace severity ratio (preview)'
      Description: 'This detection rule automatically analyzes the trace logs emitted from your application, and can warn you about unusual patterns in the severity of your trace telemetry.'
      HelpUrl: 'https://github.com/Microsoft/ApplicationInsights-Home/blob/master/SmartDetection/degradation-in-trace-severity-ratio.md'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_longdependencyduration 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'longdependencyduration'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'longdependencyduration'
      DisplayName: 'Long dependency duration'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_migrationToAlertRulesCompleted 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'migrationToAlertRulesCompleted'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'migrationToAlertRulesCompleted'
      DisplayName: 'Migration To Alert Rules Completed'
      Description: 'A configuration that controls the migration state of Smart Detection to Smart Alerts'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: true
      IsEnabledByDefault: false
      IsInPreview: true
      SupportsEmailNotifications: false
    }
    enabled: false
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_slowpageloadtime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'slowpageloadtime'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'slowpageloadtime'
      DisplayName: 'Slow page load time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource components_appi_lab2_dev_09_name_slowserverresponsetime 'microsoft.insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  parent: components_appi_lab2_dev_09_name_resource
  name: 'slowserverresponsetime'
  location: 'centralus'
  properties: {
    ruleDefinitions: {
      Name: 'slowserverresponsetime'
      DisplayName: 'Slow server response time'
      Description: 'Smart Detection rules notify you of performance anomaly issues.'
      HelpUrl: 'https://docs.microsoft.com/en-us/azure/application-insights/app-insights-proactive-performance-diagnostics'
      IsHidden: false
      IsEnabledByDefault: true
      IsInPreview: false
      SupportsEmailNotifications: true
    }
    enabled: true
    sendEmailsToSubscriptionOwners: true
    customEmails: []
  }
}

resource vaults_kv_lab02_dev_09_name_EventGridTopicKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vaults_kv_lab02_dev_09_name_resource
  name: 'EventGridTopicKey'
  properties: {
    value: eventGridTopicKey
    attributes: {
      enabled: true
    }
  }
}

resource vaults_kv_lab02_dev_09_name_ServiceBusConnection 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vaults_kv_lab02_dev_09_name_resource
  name: 'ServiceBusConnection'
  properties: {
    value: serviceBusConnection
    attributes: {
      enabled: true
    }
  }
}

resource vaults_kv_lab02_dev_09_name_SqlAdminPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vaults_kv_lab02_dev_09_name_resource
  name: 'SqlAdminPassword'
  properties: {
    value: sqlAdminPassword
    attributes: {
      enabled: true
    }
  }
}

resource vaults_kv_lab02_dev_09_name_SqlConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vaults_kv_lab02_dev_09_name_resource
  name: 'SqlConnectionString'
  properties: {
    value: sqlConnectionString
    attributes: {
      enabled: true
    }
  }
}

resource vaults_kv_lab02_dev_09_name_SqlOrderProcessorPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vaults_kv_lab02_dev_09_name_resource
  name: 'SqlOrderProcessorPassword'
  properties: {
    value: sqlOrderProcessorPassword
    attributes: {
      enabled: true
    }
  }
}

resource workflows_logicapp_lab2_dev_09_name_default 'Microsoft.Logic/workflows/accessKeys@2015-02-01-preview' = {
  parent: workflows_logicapp_lab2_dev_09_name_resource
  name: 'default'
  properties: {}
}



resource namespaces_sb_lab02_dev_name_func_listen 'Microsoft.ServiceBus/namespaces/authorizationrules@2026-07-01-preview' = {
  parent: namespaces_sb_lab02_dev_name_resource
  name: 'func-listen'
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource namespaces_sb_lab02_dev_name_RootManageSharedAccessKey 'Microsoft.ServiceBus/namespaces/authorizationrules@2026-07-01-preview' = {
  parent: namespaces_sb_lab02_dev_name_resource
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource namespaces_sb_lab02_dev_name_test_sender 'Microsoft.ServiceBus/namespaces/authorizationrules@2026-07-01-preview' = {
  parent: namespaces_sb_lab02_dev_name_resource
  name: 'test-sender'
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource namespaces_sb_lab02_dev_name_default 'Microsoft.ServiceBus/namespaces/networkrulesets@2026-07-01-preview' = {
  parent: namespaces_sb_lab02_dev_name_resource
  name: 'default'
  properties: {
    publicNetworkAccess: 'Enabled'
    defaultAction: 'Allow'
    ipRules: []
    trustedServiceAccessEnabled: false
  }
}

resource namespaces_sb_lab02_dev_name_orders_queue 'Microsoft.ServiceBus/namespaces/queues@2026-07-01-preview' = {
  parent: namespaces_sb_lab02_dev_name_resource
  name: 'orders-queue'
  properties: {
    maxMessageSizeInKilobytes: 256
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_CreateIndex 'Microsoft.Sql/servers/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'CreateIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_DbParameterization 'Microsoft.Sql/servers/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'DbParameterization'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_DefragmentIndex 'Microsoft.Sql/servers/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'DefragmentIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_DropIndex 'Microsoft.Sql/servers/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'DropIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_ForceLastGoodPlan 'Microsoft.Sql/servers/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'ForceLastGoodPlan'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource Microsoft_Sql_servers_auditingPolicies_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/auditingPolicies@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    auditingState: 'Disabled'
  }
}

resource Microsoft_Sql_servers_auditingSettings_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/auditingSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: []
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_connectionPolicies_servers_sqlserver_azlab02_dev_09_name_default 'Microsoft.Sql/servers/connectionPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'default'
  properties: {
    connectionType: 'Default'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev 'Microsoft.Sql/servers/databases@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: databases_sqldb_lab02_dev_name
  location: 'centralus'
  sku: {
    name: 'GP_S_Gen5_1'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    autoPauseDelay: 15
    requestedBackupStorageRedundancy: 'Local'
    minCapacity: json('0.5')
    maintenanceConfigurationId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/advancedThreatProtectionSettings@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    state: 'Disabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingPolicies_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/auditingPolicies@2014-04-01' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    auditingState: 'Disabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingSettings_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/auditingSettings@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_extendedAuditingSettings_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/extendedAuditingSettings@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_geoBackupPolicies_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/geoBackupPolicies@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_master_Current 'Microsoft.Sql/servers/databases/ledgerDigestUploads@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Current'
  properties: {}
}

resource Microsoft_Sql_servers_databases_securityAlertPolicies_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/securityAlertPolicies@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    state: 'Disabled'
    disabledAlerts: [
      ''
    ]
    emailAddresses: [
      ''
    ]
    emailAccountAdmins: false
    retentionDays: 0
  }
}

resource Microsoft_Sql_servers_databases_transparentDataEncryption_servers_sqlserver_azlab02_dev_09_name_master_Current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Current'
  properties: {
    state: 'Disabled'
  }
}

resource Microsoft_Sql_servers_databases_vulnerabilityAssessments_servers_sqlserver_azlab02_dev_09_name_master_Default 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2026-08-01-preview' = {
  name: '${servers_sqlserver_azlab02_dev_09_name}/master/Default'
  properties: {
    recurringScans: {
      isEnabled: false
      emailSubscriptionAdmins: true
    }
  }
}

resource Microsoft_Sql_servers_devOpsAuditingSettings_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/devOpsAuditingSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_current 'Microsoft.Sql/servers/encryptionProtector@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'current'
  properties: {
    serverKeyName: 'ServiceManaged'
    serverKeyType: 'ServiceManaged'
    autoRotationEnabled: false
  }
}

resource Microsoft_Sql_servers_extendedAuditingSettings_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/extendedAuditingSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'default'
  properties: {
    retentionDays: 0
    auditActionsAndGroups: []
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    isManagedIdentityInUse: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_01 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-01'
  properties: {
    startIpAddress: '23.99.215.110'
    endIpAddress: '23.99.215.110'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_02 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-02'
  properties: {
    startIpAddress: '23.99.213.182'
    endIpAddress: '23.99.213.182'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_03 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-03'
  properties: {
    startIpAddress: '168.61.218.60'
    endIpAddress: '168.61.218.60'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_04 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-04'
  properties: {
    startIpAddress: '23.99.208.251'
    endIpAddress: '23.99.208.251'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_05 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-05'
  properties: {
    startIpAddress: '20.221.48.159'
    endIpAddress: '20.221.48.159'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_06 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-06'
  properties: {
    startIpAddress: '23.99.211.22'
    endIpAddress: '23.99.211.22'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_07 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-07'
  properties: {
    startIpAddress: '23.99.209.158'
    endIpAddress: '23.99.209.158'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_08 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-08'
  properties: {
    startIpAddress: '23.99.214.44'
    endIpAddress: '23.99.214.44'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_09 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-09'
  properties: {
    startIpAddress: '20.221.124.172'
    endIpAddress: '20.221.124.172'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_10 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-10'
  properties: {
    startIpAddress: '20.221.124.207'
    endIpAddress: '20.221.124.207'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_11 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-11'
  properties: {
    startIpAddress: '20.221.124.233'
    endIpAddress: '20.221.124.233'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_12 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-12'
  properties: {
    startIpAddress: '20.221.124.255'
    endIpAddress: '20.221.124.255'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_13 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-13'
  properties: {
    startIpAddress: '20.221.125.146'
    endIpAddress: '20.221.125.146'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_14 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-14'
  properties: {
    startIpAddress: '20.221.125.155'
    endIpAddress: '20.221.125.155'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_15 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-15'
  properties: {
    startIpAddress: '20.221.125.156'
    endIpAddress: '20.221.125.156'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_16 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-16'
  properties: {
    startIpAddress: '20.221.125.165'
    endIpAddress: '20.221.125.165'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_17 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-17'
  properties: {
    startIpAddress: '20.221.125.168'
    endIpAddress: '20.221.125.168'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_18 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-18'
  properties: {
    startIpAddress: '20.221.125.213'
    endIpAddress: '20.221.125.213'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_19 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-19'
  properties: {
    startIpAddress: '20.221.125.214'
    endIpAddress: '20.221.125.214'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_func_lab2_outbound_20 'Microsoft.Sql/servers/firewallRules@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'func-lab2-outbound-20'
  properties: {
    startIpAddress: '20.221.125.223'
    endIpAddress: '20.221.125.223'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_ServiceManaged 'Microsoft.Sql/servers/keys@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'ServiceManaged'
  properties: {
    serverKeyType: 'ServiceManaged'
  }
}

resource Microsoft_Sql_servers_securityAlertPolicies_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/securityAlertPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    state: 'Disabled'
    disabledAlerts: [
      ''
    ]
    emailAddresses: [
      ''
    ]
    emailAccountAdmins: false
    retentionDays: 0
  }
}

resource Microsoft_Sql_servers_sqlVulnerabilityAssessments_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/sqlVulnerabilityAssessments@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource Microsoft_Sql_servers_vulnerabilityAssessments_servers_sqlserver_azlab02_dev_09_name_Default 'Microsoft.Sql/servers/vulnerabilityAssessments@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_resource
  name: 'Default'
  properties: {
    recurringScans: {
      isEnabled: false
      emailSubscriptionAdmins: true
    }
    storageContainerPath: vulnerabilityAssessments_Default_storageContainerPath
  }
}

resource storageAccounts_stlab02dev09_name_default 'Microsoft.Storage/storageAccounts/blobServices@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_resource
  name: 'default'
  properties: {
    staticWebsite: {
      enabled: false
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_stlab02dev09_name_default 'Microsoft.Storage/storageAccounts/fileServices@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_resource
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_stlab02dev09_name_default 'Microsoft.Storage/storageAccounts/queueServices@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_stlab02dev09_name_default 'Microsoft.Storage/storageAccounts/tableServices@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource sites_func_lab2_dev_09_name_resource 'Microsoft.Web/sites@2024-11-01' = {
  name: sites_func_lab2_dev_09_name
  location: 'Central US'
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/${subscription().subscriptionId}/resourceGroups/rg-azlab02-dev-centralus/providers/microsoft.insights/components/appi-lab2-dev-09'
  }
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_func_lab2_dev_09_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${sites_func_lab2_dev_09_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: serverfarms_CentralUSPlan_name_resource.id
    reserved: false
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientAffinityProxyEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    customDomainVerificationId: 'FC7036F8013DEE0227F0007BB6EFE9B6FFCE7E9CC7E8CF5FDBA6771144C35BB3'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource sites_func_lab2_dev_09_name_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'ftp'
  properties: {
    allow: true
  }
}

resource sites_func_lab2_dev_09_name_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'scm'
  properties: {
    allow: true
  }
}

resource sites_func_lab2_dev_09_name_web 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v10.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$func-lab2-dev-09'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    localMySqlEnabled: false
    managedServiceIdentityId: 150755
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    functionAppScaleLimit: 200
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
    http20ProxyFlag: 0
  }
}

resource sites_func_lab2_dev_09_name_5f9d7fe0e6c44317bf2750257445085e 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: '5f9d7fe0e6c44317bf2750257445085e'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T02:22:20.8815662Z'
    end_time: '2026-11-11T02:22:22.5065422Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_7330c4eba57c44d0b30d521f01dc3cdc 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: '7330c4eba57c44d0b30d521f01dc3cdc'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T03:08:08.8037012Z'
    end_time: '2026-11-11T03:08:10.317219Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_9cccfd3eba7a40e7bd21abb3f7f88b06 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: '9cccfd3eba7a40e7bd21abb3f7f88b06'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T14:13:07.0517349Z'
    end_time: '2026-11-11T14:13:08.6598336Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_b7d4a41751294ffaa45ab6698465b2b6 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'b7d4a41751294ffaa45ab6698465b2b6'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T02:09:07.4881433Z'
    end_time: '2026-11-11T02:09:08.9568756Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_babfaf766ef643b5a1f5f73cb3fa5cf5 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'babfaf766ef643b5a1f5f73cb3fa5cf5'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T14:23:33.9458409Z'
    end_time: '2026-11-11T14:23:35.398978Z'
    active: true
  }
}

resource sites_func_lab2_dev_09_name_e6a06e8c6af74d4ba3f457dddb2015af 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'e6a06e8c6af74d4ba3f457dddb2015af'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T01:33:56.1297382Z'
    end_time: '2026-11-11T01:33:57.7703689Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_fb66a496a04f4008931bcfc27da787b9 'Microsoft.Web/sites/deployments@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'fb66a496a04f4008931bcfc27da787b9'
  properties: {
    status: 4
    author_email: 'N/A'
    author: 'N/A'
    deployer: 'ZipDeploy'
    message: 'Created via a push deployment'
    start_time: '2026-11-11T11:27:52.4935143Z'
    end_time: '2026-11-11T11:27:53.8685008Z'
    active: false
  }
}

resource sites_func_lab2_dev_09_name_OutboxPublisher 'Microsoft.Web/sites/functions@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'OutboxPublisher'
  properties: {
    script_href: 'https://func-lab2-dev-09.azurewebsites.net/admin/vfs/site/wwwroot/OrderProcessor.dll'
    href: 'https://func-lab2-dev-09.azurewebsites.net/admin/functions/OutboxPublisher'
    config: {
      name: 'OutboxPublisher'
      entryPoint: 'OrderProcessor.OutboxPublisher.Run'
      scriptFile: 'OrderProcessor.dll'
      language: 'dotnet-isolated'
      functionDirectory: ''
      bindings: [
        {
          name: 'timer'
          type: 'timerTrigger'
          direction: 'In'
          schedule: '0 */1 * * * *'
        }
      ]
    }
    language: 'dotnet-isolated'
    isDisabled: false
  }
}

resource sites_func_lab2_dev_09_name_ProcessOrder 'Microsoft.Web/sites/functions@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: 'ProcessOrder'
  properties: {
    script_href: 'https://func-lab2-dev-09.azurewebsites.net/admin/vfs/site/wwwroot/OrderProcessor.dll'
    href: 'https://func-lab2-dev-09.azurewebsites.net/admin/functions/ProcessOrder'
    config: {
      name: 'ProcessOrder'
      entryPoint: 'OrderProcessor.ProcessOrder.Run'
      scriptFile: 'OrderProcessor.dll'
      language: 'dotnet-isolated'
      functionDirectory: ''
      bindings: [
        {
          name: 'message'
          type: 'serviceBusTrigger'
          direction: 'In'
          properties: {
            supportsDeferredBinding: 'True'
          }
          queueName: 'orders-queue'
          connection: 'ServiceBusConnection'
          autoCompleteMessages: false
          cardinality: 'One'
        }
      ]
    }
    language: 'dotnet-isolated'
    isDisabled: false
  }
}

resource sites_func_lab2_dev_09_name_sites_func_lab2_dev_09_name_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2024-11-01' = {
  parent: sites_func_lab2_dev_09_name_resource
  name: '${sites_func_lab2_dev_09_name}.azurewebsites.net'
  properties: {
    siteName: 'func-lab2-dev-09'
    hostNameType: 'Verified'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/advancedThreatProtectionSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_CreateIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'CreateIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_DbParameterization 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'DbParameterization'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_DefragmentIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'DefragmentIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_DropIndex 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'DropIndex'
  properties: {
    autoExecuteValue: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_ForceLastGoodPlan 'Microsoft.Sql/servers/databases/advisors@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'ForceLastGoodPlan'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingPolicies_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/auditingPolicies@2014-04-01' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Default'
  properties: {
    auditingState: 'Disabled'
  }
}

resource Microsoft_Sql_servers_databases_auditingSettings_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/auditingSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_backupLongTermRetentionPolicies_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_default 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'default'
  properties: {
    timeBasedImmutability: 'Disabled'
    weeklyRetention: 'PT0S'
    monthlyRetention: 'PT0S'
    yearlyRetention: 'PT0S'
    weekOfYear: 0
  }
}

resource Microsoft_Sql_servers_databases_backupShortTermRetentionPolicies_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_default 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'default'
  properties: {
    retentionDays: 7
    diffBackupIntervalInHours: 12
  }
}

resource Microsoft_Sql_servers_databases_extendedAuditingSettings_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/extendedAuditingSettings@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'default'
  properties: {
    retentionDays: 0
    isAzureMonitorTargetEnabled: false
    state: 'Disabled'
    storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
  }
}

resource Microsoft_Sql_servers_databases_geoBackupPolicies_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/geoBackupPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
}

resource servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Current 'Microsoft.Sql/servers/databases/ledgerDigestUploads@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Current'
  properties: {}
}

resource Microsoft_Sql_servers_databases_securityAlertPolicies_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/securityAlertPolicies@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Default'
  properties: {
    state: 'Disabled'
    disabledAlerts: [
      ''
    ]
    emailAddresses: [
      ''
    ]
    emailAccountAdmins: false
    retentionDays: 0
  }
}

resource Microsoft_Sql_servers_databases_transparentDataEncryption_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Current 'Microsoft.Sql/servers/databases/transparentDataEncryption@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Current'
  properties: {
    state: 'Enabled'
    scanState: 'Complete'
  }
}

resource Microsoft_Sql_servers_databases_vulnerabilityAssessments_servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev_Default 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2026-08-01-preview' = {
  parent: servers_sqlserver_azlab02_dev_09_name_sqldb_lab02_dev
  name: 'Default'
  properties: {
    recurringScans: {
      isEnabled: false
      emailSubscriptionAdmins: true
    }
  }
}

resource storageAccounts_stlab02dev09_name_default_azure_webjobs_hosts 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_default
  name: 'azure-webjobs-hosts'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource storageAccounts_stlab02dev09_name_default_azure_webjobs_secrets 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-06-01' = {
  parent: storageAccounts_stlab02dev09_name_default
  name: 'azure-webjobs-secrets'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource storageAccounts_stlab02dev09_name_default_func_lab2_dev_09ant0e1c9 'Microsoft.Storage/storageAccounts/fileServices/shares@2026-06-01' = {
  parent: Microsoft_Storage_storageAccounts_fileServices_storageAccounts_stlab02dev09_name_default
  name: 'func-lab2-dev-09ant0e1c9'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 102400
    enabledProtocols: 'SMB'
  }
}

resource workflows_logicapp_lab2_dev_09_name_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflows_logicapp_lab2_dev_09_name
  location: 'centralus'
  properties: {
    state: 'Enabled'
    definition: {
      metadata: {
        notes: {}
      }
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_resource_event_occurs: {
          splitOn: '@triggerBody()'
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureeventgrid\'][\'connectionId\']'
              }
            }
            body: {
              properties: {
                topic: topics_evgt_azlab02_dev_centralus_name_resource.id
                destination: {
                  endpointType: 'webhook'
                  properties: {
                    endpointUrl: '@listCallbackUrl()'
                  }
                }
                filter: {
                  includedEventTypes: [
                    'OrderCompleted'
                  ]
                }
              }
            }
            path: '/subscriptions/@{encodeURIComponent(\'${subscription().subscriptionId}\')}/providers/@{encodeURIComponent(\'Microsoft.EventGrid.Topics\')}/resource/eventSubscriptions'
            queries: {
              'x-ms-api-version': '2017-09-15-preview'
            }
          }
        }
      }
      actions: {
        'Send_email_(V2)': {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'gmail-1\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              To: 'ali.hbza80@gmail.com'
              Importance: 'Normal'
              Subject: 'Lab02 - New Order Completed'
              Body: '<p class="editor-paragraph"><b><strong class="editor-text-bold" style="font-size: 20px;">NexaStore</strong></b><br><br><b><strong class="editor-text-bold">━━━━━━━━━━━━━━━━━━━━</strong></b><br><br><b><strong class="editor-text-bold" style="font-size: 17px;">ORDER COMPLETED</strong></b></p><br><p class="editor-paragraph">Your order has been processed successfully!<br><br><span style="font-size: 12px;">ORDER SUMMARY</span><br><br><b><strong class="editor-text-bold">Order ID: </strong></b>@{triggerBody()?[\'data\']?[\'orderId\']}<br><br><b><strong class="editor-text-bold">Product ID: </strong></b>@{triggerBody()?[\'data\']?[\'productId\']}<br><br><b><strong class="editor-text-bold">Quantity: </strong></b>@{triggerBody()?[\'data\']?[\'quantity\']}<br><br><b><strong class="editor-text-bold">Customer ID: </strong></b>@{triggerBody()?[\'data\']?[\'customerId\']}<br><br><b><strong class="editor-text-bold">━━━━━━━━━━━━━━━━━━━━</strong></b><br><br><span style="font-size: 12px;">This is an automated notification from NexaStore.</span></p>'
            }
            path: '/v2/Mail'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureeventgrid: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/centralus/managedApis/azureeventgrid'
            connectionId: connections_azureeventgrid_name_resource.id
            connectionName: 'azureeventgrid'
            connectionProperties: {}
          }
          'gmail-1': {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/centralus/managedApis/gmail'
            connectionId: connections_gmail_1_name_resource.id
            connectionName: 'gmail-1'
            connectionProperties: {}
          }
        }
      }
    }
    endpointsConfiguration: {
      workflow: {
        outgoingIpAddresses: [
          {
            address: '52.141.218.55'
          }
          {
            address: '20.109.202.29'
          }
          {
            address: '20.118.195.232'
          }
          {
            address: '20.118.195.233'
          }
          {
            address: '20.118.195.234'
          }
          {
            address: '20.118.195.235'
          }
          {
            address: '20.118.195.236'
          }
          {
            address: '20.118.195.237'
          }
          {
            address: '20.118.195.238'
          }
          {
            address: '20.118.195.239'
          }
        ]
        accessEndpointIpAddresses: [
          {
            address: '172.212.239.224'
          }
          {
            address: '172.212.239.225'
          }
          {
            address: '172.212.239.226'
          }
          {
            address: '172.212.239.227'
          }
          {
            address: '172.212.239.228'
          }
          {
            address: '172.212.239.229'
          }
          {
            address: '172.212.239.230'
          }
          {
            address: '172.212.239.231'
          }
        ]
      }
      connector: {
        outgoingIpAddresses: [
          {
            address: '52.173.241.27'
          }
          {
            address: '52.173.245.164'
          }
          {
            address: '13.89.171.80/28'
          }
          {
            address: '13.89.178.64/27'
          }
          {
            address: '40.77.68.110'
          }
          {
            address: '20.98.144.224/27'
          }
          {
            address: '20.98.145.0/28'
          }
          {
            address: '20.80.123.134'
          }
          {
            address: '20.80.123.57'
          }
        ]
      }
    }
  }
}
