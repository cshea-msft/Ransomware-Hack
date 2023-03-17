// Create a Resource Group Template Deployment for Alerts.JSON
resource "azurerm_resource_group_template_deployment" "rg_template_deployment" {
  name                = "rg_template_deployment"
  resource_group_name = azurerm_resource_group.rg_law.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "workspace" = {
      value = azurerm_log_analytics_workspace.law.name
    }
  })
  template_content = <<TEMPLATE
    {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workspace": {
            "type": "String"
        }
    },
    "resources": [
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/ee9dfc9f-30ad-49a6-aba6-3292a242202d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/ee9dfc9f-30ad-49a6-aba6-3292a242202d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AV detections related to Hive Ransomware",
                "description": "This query looks for Microsoft Defender AV detections related to Hive Ransomware . In Microsoft Sentinel the SecurityAlerts table includes only the Device Name of the affected device,\n this query joins the DeviceInfo table to clearly connect other information such as Device group, ip, logged on users etc. This would allow the Microsoft Sentinel analyst to have more context related to the alert, if available.",
                "severity": "High",
                "enabled": true,
                "query": "let Hive_threats = dynamic([\"Ransom:Win64/Hive\", \"Ransom:Win32/Hive\"]);\nDeviceInfo\n| extend DeviceName = tolower(DeviceName)\n| join kind=inner ( SecurityAlert\n| where ProviderName == \"MDATP\"\n| extend ThreatName = tostring(parse_json(ExtendedProperties).ThreatName)\n| extend ThreatFamilyName = tostring(parse_json(ExtendedProperties).ThreatFamilyName)\n| where ThreatName in~ (Hive_threats) or ThreatFamilyName in~ (Hive_threats)\n| extend CompromisedEntity = tolower(CompromisedEntity)\n) on $left.DeviceName == $right.CompromisedEntity\n| summarize by DisplayName, ThreatName, ThreatFamilyName, PublicIP, AlertSeverity, Description, tostring(LoggedOnUsers), DeviceId, TenantId , bin(TimeGenerated, 1d), CompromisedEntity, tostring(LoggedOnUsers), ProductName, Entities",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "4e5914a4-2ccd-429d-a845-fa597f0bd8c5",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "CompromisedEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "PublicIP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/aad2d952-3de3-41dc-83b1-a7aa3fa6890c')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/aad2d952-3de3-41dc-83b1-a7aa3fa6890c')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Dev-0270 Registry IOC - September 2022",
                "description": "The query below identifies modification of registry by Dev-0270 actor to disable security feature as well as to add ransom notes",
                "severity": "High",
                "enabled": true,
                "query": "(union isfuzzy=true\n(SecurityEvent\n| where EventID == 4688\n| where (CommandLine has_all  ('reg', 'add', 'HKLM\\\\SOFTWARE\\\\Policies\\\\', '/v','/t', 'REG_DWORD', '/d', '/f') and CommandLine has_any('DisableRealtimeMonitoring', 'UseTPMKey', 'UseTPMKeyPIN', 'UseAdvancedStartup', 'EnableBDEWithNoTPM', 'RecoveryKeyMessageSource'))\n  or CommandLine has_all ('reg', 'add', 'HKLM\\\\SOFTWARE\\\\Policies\\\\', '/v','/t', 'REG_DWORD', '/d', '/f', 'RecoveryKeyMessage', 'Your drives are Encrypted!', '@')\n| project TimeGenerated, HostCustomEntity = Computer, AccountCustomEntity = Account, AccountDomain, ProcessName, ProcessNameFullPath = NewProcessName, EventID, Activity, CommandLine, EventSourceName, Type\n),\n(DeviceProcessEvents \n| where (InitiatingProcessCommandLine has_all(@'\"reg\"', 'add', @'\"HKLM\\SOFTWARE\\Policies\\', '/v','/t', 'REG_DWORD', '/d', '/f') \n   and InitiatingProcessCommandLine has_any('DisableRealtimeMonitoring', 'UseTPMKey', 'UseTPMKeyPIN', 'UseAdvancedStartup', 'EnableBDEWithNoTPM', 'RecoveryKeyMessageSource') ) \n   or InitiatingProcessCommandLine has_all('\"reg\"', 'add', @'\"HKLM\\SOFTWARE\\Policies\\', '/v','/t', 'REG_DWORD', '/d', '/f', 'RecoveryKeyMessage', 'Your drives are Encrypted!', '@')\n| extend timestamp = TimeGenerated, AccountCustomEntity =  InitiatingProcessAccountName, HostCustomEntity = DeviceName\n )\n )",
                "queryFrequency": "PT6H",
                "queryPeriod": "PT6H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "2566e99f-ad0f-472a-b9ac-d3899c9283e6",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/c43d2284-7cf2-4987-8239-021166ae288f')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/c43d2284-7cf2-4987-8239-021166ae288f')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AV detections related to Europium actors",
                "description": "This query looks for Microsoft Defender AV detections related to  Europium actor. In Microsoft Sentinel the SecurityAlerts table includes only the Device Name of the affected device, \n this query joins the DeviceInfo table to clearly connect other information such as Device group, ip, etc. This would allow the Microsoft Sentinel analyst to have more context related to the alert, if available.\n Reference: https://www.microsoft.com/security/blog/2022/09/08/microsoft-investigates-iranian-attacks-against-the-albanian-government ",
                "severity": "High",
                "enabled": true,
                "query": "let Europium_threats = dynamic([\"TrojanDropper:ASP/WebShell!MSR\", \"Trojan:Win32/BatRunGoXml\", \"DoS:Win64/WprJooblash\", \"Ransom:Win32/Eagle!MSR\", \"Trojan:Win32/Debitom.A\"]);\nDeviceInfo\n| extend DeviceName = tolower(DeviceName)\n| join kind=inner ( SecurityAlert\n| where ProviderName == \"MDATP\"\n| extend ThreatName = tostring(parse_json(ExtendedProperties).ThreatName)\n| extend ThreatFamilyName = tostring(parse_json(ExtendedProperties).ThreatFamilyName)\n| where ThreatName in~ (Europium_threats) or ThreatFamilyName in~ (Europium_threats)\n| extend CompromisedEntity = tolower(CompromisedEntity)\n) on $left.DeviceName == $right.CompromisedEntity\n| summarize by DisplayName, ThreatName, ThreatFamilyName, PublicIP, AlertSeverity, Description, tostring(LoggedOnUsers), DeviceId, TenantId , bin(TimeGenerated, 1d), CompromisedEntity, tostring(LoggedOnUsers), ProductName, Entities",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "186970ee-5001-41c1-8c73-3178f75ce96a",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "CompromisedEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "PublicIP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/0696f014-579b-47ae-93d7-f5c98a28b964')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/0696f014-579b-47ae-93d7-f5c98a28b964')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Dev-0530 File Extension Rename",
                "description": "Dev-0530 actors are known to encrypt the contents of the victims device as well as renaming the file extensions. This query looks for the creation of files with .h0lyenc extension or presence of ransom note.",
                "severity": "High",
                "enabled": true,
                "query": "(union isfuzzy=true\n(DeviceFileEvents\n| where ActionType == \"FileCreated\"\n| where FileName endswith \".h0lyenc\" or FolderPath == \"C:\\\\FOR_DECRYPT.html\" \n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by AccountCustomEntity = iff(isnotempty(InitiatingProcessAccountUpn), InitiatingProcessAccountUpn, InitiatingProcessAccountName), HostCustomEntity = DeviceName, Type, InitiatingProcessId, FileName, FolderPath, EventType = ActionType, Commandline = InitiatingProcessCommandLine, InitiatingProcessFileName, InitiatingProcessSHA256, FileHashCustomEntity = SHA256\n),\n(imFileEvent\n| where EventType == \"FileCreated\" \n| where TargetFilePath endswith \".h0lyenc\" or TargetFilePath == \"C:\\\\FOR_DECRYPT.html\" \n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by AccountCustomEntity = ActorUsername, HostCustomEntity = DvcHostname, DvcId, Type, EventType,  FileHashCustomEntity = TargetFileSHA256, Hash, TargetFilePath, Commandline = ActingProcessCommandLine\n)\n)",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "d82eb796-d1eb-43c8-a813-325ce3417cef",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Algorithm",
                                "columnName": "FileHashCustomEntity"
                            },
                            {
                                "identifier": "Value",
                                "columnName": "FileHashCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/8afea951-653e-4a32-8771-06d3ca2807fd')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/8afea951-653e-4a32-8771-06d3ca2807fd')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AV detections related to Dev-0530 actors",
                "description": "This query looks for Microsoft Defender AV detections related to  Dev-0530 actors. In Microsoft Sentinel the SecurityAlerts table includes only the Device Name of the affected device, \n this query joins the DeviceInfo table to clearly connect other information such as Device group, ip, logged on users etc. This would allow the Microsoft Sentinel analyst to have more context related to the alert, if available.",
                "severity": "High",
                "enabled": true,
                "query": "let Dev0530_threats = dynamic([\"Trojan:Win32/SiennaPurple.A\", \"Ransom:Win32/SiennaBlue.A\", \"Ransom:Win32/SiennaBlue.B\"]);\nDeviceInfo\n| extend DeviceName = tolower(DeviceName)\n| join kind=inner ( SecurityAlert\n| where ProviderName == \"MDATP\"\n| extend ThreatName = tostring(parse_json(ExtendedProperties).ThreatName)\n| extend ThreatFamilyName = tostring(parse_json(ExtendedProperties).ThreatFamilyName)\n| where ThreatName in~ (Dev0530_threats) or ThreatFamilyName in~ (Dev0530_threats)\n| extend CompromisedEntity = tolower(CompromisedEntity)\n) on $left.DeviceName == $right.CompromisedEntity\n| summarize by DisplayName, ThreatName, ThreatFamilyName, PublicIP, AlertSeverity, Description, tostring(LoggedOnUsers), DeviceId, TenantId , bin(TimeGenerated, 1d), CompromisedEntity, tostring(LoggedOnUsers), ProductName, Entities",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "5f171045-88ab-4634-baae-a7b6509f483b",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "CompromisedEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "PublicIP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/8c4c0a71-09aa-484d-a76f-0c3b33d492ad')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/8c4c0a71-09aa-484d-a76f-0c3b33d492ad')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Hive Ransomware IOC - July 2022",
                "description": "Identifies a hash match related to Hive Ransomware across various data sources.",
                "severity": "High",
                "enabled": true,
                "query": "let iocs = externaldata(DateAdded:string,IoC:string,Type:string,TLP:string) [@\"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/HiveRansomwareJuly2022.csv\"] with (format=\"csv\", ignoreFirstRecord=True);\nlet sha256Hashes = (iocs | where Type =~ \"sha256\" | project IoC);\n(union isfuzzy=true\n(CommonSecurityLog\n| where FileHash in (sha256Hashes)\n| project TimeGenerated, Message, SourceUserID, FileHash, Type\n| extend timestamp = TimeGenerated, FileHashCustomEntity = FileHash, Account = SourceUserID\n),\n(imFileEvent\n| where TargetFileSHA256 has_any (sha256Hashes)\n| extend Account = ActorUsername, Computer = DvcHostname, IPAddress = SrcIpAddr, CommandLine = ActingProcessCommandLine, FileHash = TargetFileSHA256\n| project Type, TimeGenerated, Computer, Account, IPAddress, CommandLine, FileHashCustomEntity = FileHash\n),\n(Event\n| where Source == \"Microsoft-Windows-Sysmon\"\n| where EventID == 1\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend Image = EventDetail.[4].[\"#text\"],  CommandLine = EventDetail.[10].[\"#text\"], Hashes = tostring(EventDetail.[17].[\"#text\"])\n| extend Hashes = extract_all(@\"(?P<key>\\w+)=(?P<value>[a-zA-Z0-9]+)\", dynamic([\"key\",\"value\"]), Hashes)\n| extend Hashes = column_ifexists(\"Hashes\", \"\"), CommandLine = column_ifexists(\"CommandLine\", \"\")\n| where (Hashes has_any (sha256Hashes) )  \n| project TimeGenerated, EventDetail, UserName, Computer, Type, Source, Hashes, CommandLine, Image\n| extend Type = strcat(Type, \": \", Source)\n| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = UserName, ProcessCustomEntity = tostring(split(Image, '\\\\', -1)[-1]), FileHashCustomEntity = Hashes\n),\n(DeviceEvents\n| where InitiatingProcessSHA256 has_any (sha256Hashes) or SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n),\n(DeviceFileEvents\n| where SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n),\n(DeviceImageLoadEvents\n| where SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n)\n)",
                "queryFrequency": "PT12H",
                "queryPeriod": "PT12H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "b2199398-8942-4b8c-91a9-b0a707c5d147",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "ProcessId",
                                "columnName": "ProcessCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Algorithm",
                                "columnName": "AlgorithmCustomEntity"
                            },
                            {
                                "identifier": "Value",
                                "columnName": "AlgorithmCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/b9ed6578-5fb7-4b2d-9304-4ae988d8269d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/b9ed6578-5fb7-4b2d-9304-4ae988d8269d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AV detections related to Zinc actors",
                "description": "This query looks for Microsoft Defender AV detections related to  Zinc threat actor. In Microsoft Sentinel the SecurityAlerts table includes only the Device Name of the affected device, \n this query joins the DeviceInfo table to clearly connect other information such as Device group, ip, etc. \n This would allow the Microsoft Sentinel analyst to have more context related to the alert, if available.\n Reference: https://www.microsoft.com/security/blog/2022/09/29/zinc-weaponizing-open-source-software/",
                "severity": "High",
                "enabled": true,
                "query": "let Zinc_threats = dynamic([\"Trojan:Win32/ZetaNile.A\", \"Trojan:Win32/EventHorizon.A\", \"Trojan:Win32/FoggyBrass.A\", \"Trojan:Win32/FoggyBrass.B\", \"Trojan:Win32/PhantomStar.A\",\"Trojan:Win32/PhantomStar.C\",\"TrojanDropper:Win32/PhantomStar.A\"]);\nDeviceInfo\n| extend DeviceName = tolower(DeviceName)\n| join kind=inner ( SecurityAlert\n| where ProviderName == \"MDATP\"\n| extend ThreatName = tostring(parse_json(ExtendedProperties).ThreatName)\n| extend ThreatFamilyName = tostring(parse_json(ExtendedProperties).ThreatFamilyName)\n| where ThreatName in~ (Zinc_threats) or ThreatFamilyName in~ (Zinc_threats)\n| extend CompromisedEntity = tolower(CompromisedEntity)\n) on $left.DeviceName == $right.CompromisedEntity\n| summarize by DisplayName, ThreatName, ThreatFamilyName, PublicIP, AlertSeverity, Description, tostring(LoggedOnUsers), DeviceId, TenantId , bin(TimeGenerated, 1d), CompromisedEntity, tostring(LoggedOnUsers), ProductName, Entities",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "3705158d-e008-49c9-92dd-e538e1549090",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "CompromisedEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "PublicIP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/8bda2745-1670-4a81-aed0-3d2a761d9536')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/8bda2745-1670-4a81-aed0-3d2a761d9536')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Dev-0530 IOC - July 2022",
                "description": "Identifies a IOC match related to Dev-0530 actor across various data sources.",
                "severity": "High",
                "enabled": true,
                "query": "let iocs = externaldata(DateAdded:string,IoC:string,Type:string) [@\"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/Dev-0530_July2022.csv\"] with (format=\"csv\", ignoreFirstRecord=True);\nlet sha256Hashes = (iocs | where Type =~ \"sha256\" | project IoC);\nlet IPList = (iocs | where Type =~ \"ip\"| project IoC);\n(union isfuzzy=true \n(DeviceProcessEvents\n| where InitiatingProcessSHA256 in (sha256Hashes) or SHA256 in (sha256Hashes) or ( InitiatingProcessCommandLine has ('cmd.exe /Q /c schtasks /create /tn lockertask /tr') \nand InitiatingProcessCommandLine has ('sc minute /mo 1 /F /ru system'))\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName,  InitiatingProcessSHA256, Type, AccountName, SHA256\n| extend Account = AccountName, Computer = DeviceName,  CommandLine = InitiatingProcessCommandLine, FileHash = case(InitiatingProcessSHA256 in (sha256Hashes), \"InitiatingProcessSHA256\", SHA256 in (sha256Hashes), \"SHA256\", \"No Match\")\n| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = InitiatingProcessFileName, FileHashCustomEntity = case(FileHash == \"InitiatingProcessSHA256\", InitiatingProcessSHA256, FileHash == \"SHA256\", SHA256, \"No Match\")\n),\n( SecurityEvent\n| where EventID == 4688\n| where ( CommandLine has ('cmd.exe /Q /c schtasks /create /tn lockertask /tr') and CommandLine has ('/sc minute /mo 1 /F /ru system'))\n| project TimeGenerated, Computer, NewProcessName, ParentProcessName, Account, NewProcessId, Type, EventID, CommandLine\n| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = NewProcessName\n),\n( imFileEvent\n| where Hash in~ (sha256Hashes) or  ( ActingProcessCommandLine has ('cmd.exe /Q /c schtasks /create /tn lockertask /tr') and ActingProcessCommandLine has ('/sc minute /mo 1 /F /ru system'))\n| extend Account = ActorUsername, Computer = DvcHostname, IPAddress = SrcIpAddr, CommandLine = ActingProcessCommandLine, FileHash = TargetFileSHA256\n| project Type, TimeGenerated, Computer, Account, IPAddress, CommandLine, FileHash\n| extend timestamp = TimeGenerated, AccountCustomEntity = Account, HostCustomEntity = Computer, FileHashCustomEntity = FileHash\n),\n(Event\n| where Source == \"Microsoft-Windows-Sysmon\"\n| where EventID == 1\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend Image = EventDetail.[4].[\"#text\"],  CommandLine = EventDetail.[10].[\"#text\"], Hashes = tostring(EventDetail.[17].[\"#text\"])\n| extend Hashes = extract_all(@\"(?P<key>\\w+)=(?P<value>[a-zA-Z0-9]+)\", dynamic([\"key\",\"value\"]), Hashes)\n| extend Hashes = column_ifexists(\"Hashes\", \"\"), CommandLine = column_ifexists(\"CommandLine\", \"\")\n| where (Hashes has_any (sha256Hashes) ) or ( CommandLine has ('cmd.exe /Q /c schtasks /create /tn lockertask /tr') and CommandLine has ('/sc minute /mo 1 /F /ru system')) \n| project TimeGenerated, EventDetail, UserName, Computer, Type, Source, Hashes, CommandLine, Image\n| extend Type = strcat(Type, \": \", Source)\n| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = UserName, ProcessCustomEntity = tostring(split(Image, '\\\\', -1)[-1]), FileHashCustomEntity = Hashes\n),\n(DeviceFileEvents\n| where SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n),\n(EmailEvents\n| where SenderFromAddress == 'H0lyGh0st@mail2tor.com'\n| extend timestamp = TimeGenerated, IPCustomEntity = SenderIPv4, AccountCustomEntity = SenderFromAddress \n),\n(CommonSecurityLog \n| where isnotempty(SourceIP) or isnotempty(DestinationIP) \n| where SourceIP in (IPList) or DestinationIP in (IPList) or Message has_any (IPList) or FileHash in (sha256Hashes)\n| extend IPMatch = case(SourceIP in (IPList), \"SourceIP\", DestinationIP in (IPList), \"DestinationIP\", \"Message\")  \n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by SourceIP, DestinationIP, DeviceProduct, DeviceAction, Message, Protocol, SourcePort, DestinationPort, DeviceAddress, DeviceName, IPMatch , FileHash\n| extend timestamp = StartTimeUtc, IPCustomEntity = case(IPMatch == \"SourceIP\", SourceIP, IPMatch == \"DestinationIP\", DestinationIP, \"IP in Message Field\"), FileHashCustomEntity = FileHash\n), \n(OfficeActivity \n|extend SourceIPAddress = ClientIP, Account = UserId \n| where  SourceIPAddress in (IPList) \n| extend timestamp = TimeGenerated , IPCustomEntity = SourceIPAddress , AccountCustomEntity = Account \n),\n(SigninLogs \n| where isnotempty(IPAddress) \n| where IPAddress in (IPList) \n| extend timestamp = TimeGenerated, AccountCustomEntity = UserPrincipalName, IPCustomEntity = IPAddress \n),\n(AADNonInteractiveUserSignInLogs \n| where isnotempty(IPAddress) \n| where IPAddress in (IPList) \n| extend timestamp = TimeGenerated, AccountCustomEntity = UserPrincipalName, IPCustomEntity = IPAddress \n), \n(W3CIISLog  \n| where isnotempty(cIP) \n| where cIP in (IPList) \n| extend timestamp = TimeGenerated, IPCustomEntity = cIP, HostCustomEntity = Computer, AccountCustomEntity = csUserName \n), \n(AzureActivity  \n| where isnotempty(CallerIpAddress) \n| where CallerIpAddress in (IPList) \n| extend timestamp = TimeGenerated, IPCustomEntity = CallerIpAddress, AccountCustomEntity = Caller \n), \n( \nAWSCloudTrail \n| where isnotempty(SourceIpAddress) \n| where SourceIpAddress in (IPList) \n| extend timestamp = TimeGenerated, IPCustomEntity = SourceIpAddress, AccountCustomEntity = UserIdentityUserName \n), \n( \nDeviceNetworkEvents \n| where isnotempty(RemoteIP)  \n| where RemoteIP in (IPList)  \n| extend timestamp = TimeGenerated, IPCustomEntity = RemoteIP, HostCustomEntity = DeviceName  \n),\n(\nAzureDiagnostics\n| where ResourceType == \"AZUREFIREWALLS\"\n| where Category == \"AzureFirewallApplicationRule\"\n| parse msg_s with Protocol 'request from ' SourceHost ':' SourcePort 'to ' DestinationHost ':' DestinationPort '. Action:' Action\n| where isnotempty(DestinationHost)\n| where DestinationHost has_any (IPList)  \n| extend DestinationIP = DestinationHost \n| extend IPCustomEntity = SourceHost\n),\n(\nAzureDiagnostics\n| where ResourceType == \"AZUREFIREWALLS\"\n| where Category == \"AzureFirewallNetworkRule\"\n| parse msg_s with Protocol 'request from ' SourceHost ':' SourcePort 'to ' DestinationHost ':' DestinationPort '. Action:' Action\n| where isnotempty(DestinationHost)\n| where DestinationHost has_any (IPList)  \n| extend DestinationIP = DestinationHost \n| extend IPCustomEntity = SourceHost\n),\n(\nAZFWApplicationRule\n| where Fqdn has_any (IPList)\n| extend IPCustomEntity = SourceIp\n),\n(\nAZFWNetworkRule\n| where DestinationIp has_any (IPList)\n| extend IPCustomEntity = SourceIp\n)\n)",
                "queryFrequency": "PT12H",
                "queryPeriod": "PT12H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Impact"
                ],
                "techniques": [
                    "T1486"
                ],
                "alertRuleTemplateName": "a172107d-794c-48c0-bc26-d3349fe10b4d",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Algorithm",
                                "columnName": "AlgorithmCustomEntity"
                            },
                            {
                                "identifier": "Value",
                                "columnName": "AlgorithmCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "ProcessId",
                                "columnName": "ProcessCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/ac9f689f-6de7-47ab-97f1-cf2c79a400ef')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/ac9f689f-6de7-47ab-97f1-cf2c79a400ef')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Mass Download & copy to USB device by single user",
                "description": "This query looks for any mass download by a single user with possible file copy activity to a new USB drive. Malicious insiders may perform such activities that may cause harm to the organization. \nThis query could also reveal unintentional insider that had no intention of malicious activity but their actions may impact an organizations security posture.\nReference:https://docs.microsoft.com/defender-cloud-apps/policy-template-reference",
                "severity": "Medium",
                "enabled": true,
                "query": "let Alerts = SecurityAlert\n| where AlertName =~ \"mass download by a single user\"\n| where Status != 'Resolved'\n| extend ipEnt = parse_json(Entities), accountEnt = parse_json(Entities)\n| mv-apply tempParams = ipEnt on (\nmv-expand ipEnt\n| where ipEnt.Type == \"ip\" \n| extend IpAddress = tostring(ipEnt.Address)\n)\n| mv-apply tempParams = accountEnt on (\nmv-expand accountEnt\n| where accountEnt.Type == \"account\"\n| extend AADUserId = tostring(accountEnt.AadUserId)\n)\n| extend Alert_TimeGenerated = TimeGenerated\n| distinct Alert_TimeGenerated, IpAddress, AADUserId, DisplayName, Description, ProductName, ExtendedProperties, Entities, Status, CompromisedEntity\n;\nlet CA_Events = CloudAppEvents\n| where ActionType == \"FileDownloaded\"\n| extend parsed = parse_json(RawEventData)\n| extend UserId = tostring(parsed.UserId)\n| extend FileName = tostring(parsed.SourceFileName)\n| extend FileExtension = tostring(parsed.SourceFileExtension)\n| summarize CloudAppEvent_StartTime = min(TimeGenerated), CloudAppEvent_EndTime = max(TimeGenerated), CloudAppEvent_Files = make_set(FileName), FileCount = dcount(FileName) by Application, AccountObjectId, UserId, IPAddress, City, CountryCode\n| extend CloudAppEvents_Details = pack_all();\nlet CA_Alerts_Events = Alerts | join kind=inner (CA_Events)\non $left.AADUserId == $right.AccountObjectId and $left.IpAddress == $right.IPAddress\n// Cloud app event comes before Alert\n| where CloudAppEvent_EndTime <= Alert_TimeGenerated\n| project Alert_TimeGenerated, UserId, AADUserId, IPAddress, CloudAppEvents_Details, CloudAppEvent_Files\n;\n// setup list to filter DeviceFileEvents for only files downloaded as indicated by CloudAppEvents\nlet CA_FileList = CA_Alerts_Events | project CloudAppEvent_Files;\nCA_Alerts_Events\n| join kind=inner ( DeviceFileEvents\n| where ActionType in (\"FileCreated\", \"FileRenamed\")\n| where FileName in~ (CA_FileList)\n| summarize DeviceFileEvent_StartTime = min(TimeGenerated), DeviceFileEvent_EndTime = max(TimeGenerated), DeviceFileEvent_Files = make_set(FolderPath), DeviceFileEvent_FileCount = dcount(FolderPath) by InitiatingProcessAccountUpn, DeviceId, DeviceName, InitiatingProcessFolderPath, InitiatingProcessParentFileName//, InitiatingProcessCommandLine\n| extend DeviceFileEvents_Details = pack_all()\n) on $left.UserId == $right.InitiatingProcessAccountUpn\n| where DeviceFileEvent_StartTime >= Alert_TimeGenerated\n| join kind=inner (\n// get device events where a USB drive was mounted\nDeviceEvents\n| where ActionType == \"UsbDriveMounted\"\n| extend parsed = parse_json(AdditionalFields)\n| extend USB_DriveLetter = tostring(AdditionalFields.DriveLetter), USB_ProductName = tostring(AdditionalFields.ProductName), USB_Volume = tostring(AdditionalFields.Volume)\n| where isnotempty(USB_DriveLetter)\n| project USB_TimeGenerated = TimeGenerated, DeviceId, USB_DriveLetter, USB_ProductName, USB_Volume\n| extend USB_Details = pack_all()\n)  \non DeviceId\n// USB event occurs after the Alert\n| where USB_TimeGenerated >= Alert_TimeGenerated\n| mv-expand DeviceFileEvent_Files\n| extend DeviceFileEvent_Files = tostring(DeviceFileEvent_Files)\n// make sure that we only pickup the files that have the USB drive letter\n| where DeviceFileEvent_Files startswith USB_DriveLetter\n| summarize USB_Drive_MatchedFiles = make_set_if(DeviceFileEvent_Files, DeviceFileEvent_Files startswith USB_DriveLetter) by Alert_TimeGenerated, USB_TimeGenerated, UserId, AADUserId, DeviceId, DeviceName, IPAddress, CloudAppEvents_Details = tostring(CloudAppEvents_Details), DeviceFileEvents_Details = tostring(DeviceFileEvents_Details), USB_Details = tostring(USB_Details)\n| extend InitiatingProcessFileName = tostring(split(todynamic(DeviceFileEvents_Details).InitiatingProcessFolderPath, \"\\\\\")[-1]), InitiatingProcessFolderPath = tostring(todynamic(DeviceFileEvents_Details).InitiatingProcessFolderPath)",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Exfiltration"
                ],
                "techniques": [
                    "T1052"
                ],
                "alertRuleTemplateName": "6267ce44-1e9d-471b-9f1e-ae76a6b7aa84",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "UserId"
                            },
                            {
                                "identifier": "AadUserId",
                                "columnName": "AADUserId"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPAddress"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "HostName",
                                "columnName": "DeviceName"
                            }
                        ]
                    },
                    {
                        "entityType": "File",
                        "fieldMappings": [
                            {
                                "identifier": "Name",
                                "columnName": "InitiatingProcessFileName"
                            },
                            {
                                "identifier": "Directory",
                                "columnName": "InitiatingProcessFolderPath"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/394aa771-93f4-42ce-bf04-fae43bc5bdb3')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/394aa771-93f4-42ce-bf04-fae43bc5bdb3')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "NRT",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "NRT Security Event log cleared",
                "description": "Checks for event id 1102 which indicates the security event log was cleared.\nIt uses Event Source Name \"Microsoft-Windows-Eventlog\" to avoid generating false positives from other sources, like AD FS servers for instance.",
                "severity": "Medium",
                "enabled": true,
                "query": "SecurityEvent\n| where EventID == 1102 and EventSourceName == \"Microsoft-Windows-Eventlog\"\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), EventCount = count() by Computer, Account, EventID, Activity",
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "tactics": [
                    "DefenseEvasion"
                ],
                "techniques": [
                    "T1070"
                ],
                "alertRuleTemplateName": "508cef41-2cd8-4d40-a519-b04826a9085f",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Account"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/37fd973c-b7df-43f5-91bb-7869cd9ca370')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/37fd973c-b7df-43f5-91bb-7869cd9ca370')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "COM Registry Key Modified to Point to File in Color Profile Folder",
                "description": "This query looks for changes to COM registry keys to point to files in C:\\Windows\\System32\\spool\\drivers\\color\\.\n  This can be used to enable COM hijacking for persistence.\n  Ref: https://www.microsoft.com/security/blog/2022/07/27/untangling-knotweed-european-private-sector-offensive-actor-using-0-day-exploits/",
                "severity": "Medium",
                "enabled": true,
                "query": "let guids = dynamic([\"{ddc05a5a-351a-4e06-8eaf-54ec1bc2dcea}\",\"{1f486a52-3cb1-48fd-8f50-b8dc300d9f9d}\",\"{4590f811-1d3a-11d0-891f-00aa004b2e24}\", \"{4de225bf-cf59-4cfc-85f7-68b90f185355}\", \"{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}\"]);\n  let mde_data = DeviceRegistryEvents\n  | where ActionType =~ \"RegistryValueSet\"\n  | where RegistryKey contains \"HKEY_LOCAL_MACHINE\\\\SOFTWARE\\\\Classes\\\\CLSID\"\n  | where RegistryKey has_any (guids)\n  | where RegistryValueData has \"System32\\\\spool\\\\drivers\\\\color\";\n  let event_data = SecurityEvent\n  | where EventID == 4657\n  | where ObjectName contains \"HKEY_LOCAL_MACHINE\\\\SOFTWARE\\\\Classes\\\\CLSID\"\n  | where ObjectName has_any (guids)\n  | where NewValue has \"System32\\\\spool\\\\drivers\\\\color\"\n  | extend RegistryKey = ObjectName, RegistryValueData = NewValue, DeviceName=Computer, InitiatingProcessFileName = Process, InitiatingProcessAccountName=SubjectAccount;\n  union mde_data, event_data",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1574"
                ],
                "alertRuleTemplateName": "ed8c9153-6f7a-4602-97b4-48c336b299e1",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "RegistryKey",
                        "fieldMappings": [
                            {
                                "identifier": "Key",
                                "columnName": "RegistryKey"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "HostName",
                                "columnName": "DeviceName"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "ProcessId",
                                "columnName": "InitiatingProcessFileName"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "InitiatingProcessAccountName"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/f9e1375b-08fb-436e-9e32-77f67b9fc08d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/f9e1375b-08fb-436e-9e32-77f67b9fc08d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Tarrask malware IOC - April 2022",
                "description": "Identifies a hash match related to Tarrask malware across various data sources.\n Reference: https://www.microsoft.com/security/blog/2022/04/12/tarrask-malware-uses-scheduled-tasks-for-defense-evasion/",
                "severity": "High",
                "enabled": true,
                "query": "let iocs = externaldata(DateAdded:string,IoC:string,Type:string,TLP:string) [@\"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/Tarrask.csv\"] with (format=\"csv\", ignoreFirstRecord=True);\nlet sha256Hashes = (iocs | where Type =~ \"sha256\" | project IoC);\n(union isfuzzy=true\n(CommonSecurityLog\n| where FileHash in (sha256Hashes)\n| project TimeGenerated, Message, SourceUserID, FileHash, Type\n| extend timestamp = TimeGenerated, FileHashCustomEntity = FileHash, Account = SourceUserID\n),\n(imFileEvent\n| where TargetFileSHA256 has_any (sha256Hashes)\n| extend Account = ActorUsername, Computer = DvcHostname, IPAddress = SrcIpAddr, CommandLine = ActingProcessCommandLine, FileHash = TargetFileSHA256\n| project Type, TimeGenerated, Computer, Account, IPAddress, CommandLine, FileHashCustomEntity = FileHash\n),\n(Event\n| where Source == \"Microsoft-Windows-Sysmon\"\n| where EventID == 1\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend Image = EventDetail.[4].[\"#text\"],  CommandLine = EventDetail.[10].[\"#text\"], Hashes = tostring(EventDetail.[17].[\"#text\"])\n| extend Hashes = extract_all(@\"(?P<key>\\w+)=(?P<value>[a-zA-Z0-9]+)\", dynamic([\"key\",\"value\"]), Hashes)\n| extend Hashes = column_ifexists(\"Hashes\", \"\"), CommandLine = column_ifexists(\"CommandLine\", \"\")\n| where (Hashes has_any (sha256Hashes) )  \n| project TimeGenerated, EventDetail, UserName, Computer, Type, Source, Hashes, CommandLine, Image\n| extend Type = strcat(Type, \": \", Source)\n| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = UserName, ProcessCustomEntity = tostring(split(Image, '\\\\', -1)[-1]), FileHashCustomEntity = Hashes\n),\n(DeviceEvents\n| where InitiatingProcessSHA256 has_any (sha256Hashes) or SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n),\n(DeviceFileEvents\n| where SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n),\n(DeviceImageLoadEvents\n| where SHA256 has_any (sha256Hashes)\n| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type\n| extend timestamp = TimeGenerated, HostCustomEntity = DeviceName , AccountCustomEntity = InitiatingProcessAccountName, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = \"SHA256\", FileHashCustomEntity = InitiatingProcessSHA256,  CommandLine = InitiatingProcessCommandLine,Image = InitiatingProcessFolderPath\n)\n)",
                "queryFrequency": "PT12H",
                "queryPeriod": "PT12H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1053"
                ],
                "alertRuleTemplateName": "caf78b95-d886-4ac3-957a-a7a3691ff4ed",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "ProcessId",
                                "columnName": "ProcessCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Algorithm",
                                "columnName": "AlgorithmCustomEntity"
                            },
                            {
                                "identifier": "Value",
                                "columnName": "FileHashCustomEntity_dynamic"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/c0379a8f-8371-41a5-9801-e1a48a6b14cd')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/c0379a8f-8371-41a5-9801-e1a48a6b14cd')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AV detections related to Tarrask malware",
                "description": "This query looks for Microsoft Defender AV detections related to Tarrask malware. In Microsoft Sentinel the SecurityAlerts table \n includes only the Device Name of the affected device, this query joins the DeviceInfo table to clearly connect other information such as Device group, ip, logged on users etc. \n This would allow the Microsoft Sentinel analyst to have more context related to the alert, if available.\n Reference: https://www.microsoft.com/security/blog/2022/04/12/tarrask-malware-uses-scheduled-tasks-for-defense-evasion/",
                "severity": "High",
                "enabled": true,
                "query": "let Tarrask_threats = dynamic([\"HackTool:Win64/Tarrask!MS\", \"HackTool:Win64/Ligolo!MSR\", \"Behavior:Win32/ScheduledTaskHide.A\", \"Tarrask\"]);\nDeviceInfo\n| extend DeviceName = tolower(DeviceName)\n| join kind=rightouter ( SecurityAlert\n| where ProviderName == \"MDATP\"\n| extend ThreatName = tostring(parse_json(ExtendedProperties).ThreatName)\n| extend ThreatFamilyName = tostring(parse_json(ExtendedProperties).ThreatFamilyName)\n| where ThreatName in~ (Tarrask_threats) or ThreatFamilyName in~ (Tarrask_threats)\n| extend CompromisedEntity = tolower(CompromisedEntity)\n) on $left.DeviceName == $right.CompromisedEntity",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1053"
                ],
                "alertRuleTemplateName": "1785d372-b9fe-4283-96a6-3a1d83cabfd1",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "CompromisedEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "PublicIP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/95374120-49e4-4a41-a747-b7e7c4a815cc')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/95374120-49e4-4a41-a747-b7e7c4a815cc')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "New Agent Added to Pool by New User or Added to a New OS Type.",
                "description": "As seen in attacks such as SolarWinds attackers can look to subvert a build process by controlling build servers. Azure DevOps uses agent pools to execute pipeline tasks. \nAn attacker could insert compromised agents that they control into the pools in order to execute malicious code. This query looks for users adding agents to pools they have \nnot added agents to before, or adding agents to a pool of an OS that has not been added to that pool before. This detection has potential for false positives so has a \nconfigurable allow list to allow for certain users to be excluded from the logic.",
                "severity": "Medium",
                "enabled": true,
                "query": "let lookback = 14d;\nlet timeframe = 1d;\n// exclude allowed users from query such as the ADO service\nlet allowed_users = dynamic([\"Azure DevOps Service\"]);\nunion\n// Look for agents being added to a pool of a OS type not seen with that pool before\n(AzureDevOpsAuditing\n| where TimeGenerated > ago(lookback) and TimeGenerated < ago(timeframe)\n| where OperationName =~ \"Library.AgentAdded\"\n| where ActorUPN !in (allowed_users)\n| extend AgentPoolName = tostring(Data.AgentPoolName)\n| extend OsDescription = tostring(Data.OsDescription)\n| where isnotempty(OsDescription)\n| extend OsDescription = tostring(split(OsDescription, \"#\", 0)[0])\n| project AgentPoolName, OsDescription\n| join kind=rightanti (AzureDevOpsAuditing\n| where TimeGenerated > ago(timeframe)\n| where OperationName == \"Library.AgentAdded\"\n| extend AgentPoolName = tostring(Data.AgentPoolName)\n| extend OsDescription = tostring(Data.OsDescription)\n| where isnotempty(OsDescription)\n| extend OsDescription = tostring(split(OsDescription, \"#\", 0)[0])) on AgentPoolName, OsDescription),\n// Look for users addeing agents to a pool that they have not added agents to before.\n(AzureDevOpsAuditing\n| where TimeGenerated > ago(lookback) and TimeGenerated < ago(timeframe)\n| extend AgentPoolName = tostring(Data.AgentPoolName)\n| where ActorUPN !in (allowed_users)\n| project AgentPoolName, ActorUPN\n| join kind=rightanti (AzureDevOpsAuditing\n| where TimeGenerated > ago(timeframe)\n| where OperationName == \"Library.AgentAdded\"\n| where ActorUPN !in (allowed_users)\n| extend AgentPoolName = tostring(Data.AgentPoolName)\n) on AgentPoolName, ActorUPN)\n| extend AgentName = tostring(Data.AgentName)\n| extend OsDescription = tostring(Data.OsDescription)\n| extend SystemDetails = Data.SystemCapabilities\n| project-reorder TimeGenerated, OperationName, ScopeDisplayName, AgentPoolName, AgentName, ActorUPN, IpAddress, UserAgent, OsDescription, SystemDetails, Data\n| extend timestamp = TimeGenerated, AccountCustomEntity = ActorUPN, IPCustomEntity = IpAddress",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Execution"
                ],
                "techniques": [
                    "T1053"
                ],
                "alertRuleTemplateName": "4ce177b3-56b1-4f0e-b83e-27eed4cb0b16",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/3f85de65-5999-416a-ae0a-d057eeda8add')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/3f85de65-5999-416a-ae0a-d057eeda8add')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "COM Event System Loading New DLL",
                "description": "This query uses Sysmon Image Load (Event ID 7) and Process Create (Event ID 1) data to look for COM Event System being used to load a newly seen DLL.",
                "severity": "Medium",
                "enabled": true,
                "query": "let lookback_start = 7d;\nlet lookback_end = 1d;\nlet timedelta = 5s;\n// Get a list of previously seen DLLs being loaded\nlet known_dlls = (Event\n| where TimeGenerated between(ago(lookback_start)..ago(lookback_end))\n| where EventID == 7\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend LoadedItems = parse_json(tostring(parse_json(tostring(EvData.DataItem)).EventData)).[\"Data\"]\n| mv-expand LoadedItems\n| where tostring(LoadedItems.[\"@Name\"]) =~ \"ImageLoaded\"\n| extend DLL = tostring(LoadedItems.[\"#text\"])\n| summarize by DLL);\n// Get Image Load events related to svchost.exe\nEvent\n| where Source =~ \"Microsoft-Windows-Sysmon\"\n// Image Load Event in Sysmon\n| where EventID == 7\n| extend EvData = parse_xml(EventData)\n| extend EventDetail = EvData.DataItem.EventData.Data\n| extend Images = parse_json(tostring(parse_json(tostring(EvData.DataItem)).EventData)).[\"Data\"]\n| mv-expand Images\n// Parse out executing process\n| where tostring(Images.[\"@Name\"]) =~ \"Image\"\n| extend Image = tostring(Images.[\"#text\"])\n| where Image endswith \"\\\\svchost.exe\"\n// Parse out loaded DLLs\n| extend LoadedItems = parse_json(tostring(parse_json(tostring(EvData.DataItem)).EventData)).[\"Data\"]\n| mv-expand LoadedItems\n| where tostring(LoadedItems.[\"@Name\"]) =~ \"ImageLoaded\"\n| extend DLL = tostring(LoadedItems.[\"#text\"])\n| extend Image = tostring(Image)\n| extend ImageLoadTime = TimeGenerated\n// Join with processes with a command line related to COM Event System\n| join kind = inner(Event\n| where Source =~ \"Microsoft-Windows-Sysmon\"\n// Sysmon process execution events\n| where EventID == 1\n| extend RenderedDescription = tostring(split(RenderedDescription, \":\")[0])\n| extend EventData = parse_xml(EventData).DataItem.EventData.Data\n| mv-expand bagexpansion=array EventData\n| evaluate bag_unpack(EventData)\n| extend Key = tostring(column_ifexists('@Name', \"\")), Value = column_ifexists('#text', \"\")\n| evaluate pivot(Key, any(Value), TimeGenerated, Source, EventLog, Computer, EventLevel, EventLevelName, EventID, UserName, RenderedDescription, MG, ManagementGroupName, Type, _ResourceId)\n| extend ParentImage = tostring(column_ifexists(\"ParentImage\", \"NotAvailable\"))\n// Command line related to COM Event System\n| where ParentImage endswith \"\\\\svchost.exe\"\n//| where ParentCommandLine has_all (\" -k LocalService\",\" -p\",\" -s EventSystem\")\n| extend ProcessExecutionTime = TimeGenerated) on $left.Image == $right.ParentImage\n// Check timespan between DLL load and process creation\n| extend delta =  ProcessExecutionTime - ImageLoadTime\n| where ImageLoadTime <= ProcessExecutionTime and delta <= timedelta\n// Filter to only newly seen DLLs\n| where DLL !in (known_dlls)\n| extend ParentCommandLine = tostring(column_ifexists(\"ParentCommandLine\", \"NotAvailable\"))\n| project-reorder ImageLoadTime, ProcessExecutionTime , Image, ParentCommandLine, DLL\n| extend Hashes = tostring(column_ifexists(\"Hashes\", \"NotAvailable, NotAvailable\"))\n| extend Hashes = split(Hashes, \",\")\n| mv-apply Hashes on (summarize FileHashes = make_bag(pack(tostring(split(Hashes, \"=\")[0]), tostring(split(Hashes, \"=\")[1]))))\n| extend SHA1 = tostring(FileHashes.SHA1)\n| extend HashAlgo = \"SHA1\"",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1543"
                ],
                "alertRuleTemplateName": "02f6c2e5-219d-4426-a0bf-ad67abc63d53",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "UserName"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Value",
                                "columnName": "SHA1"
                            },
                            {
                                "identifier": "Algorithm",
                                "columnName": "HashAlgo"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/1a522e64-5e34-4f06-b0e7-34c8dff3d5c2')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/1a522e64-5e34-4f06-b0e7-34c8dff3d5c2')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "TEARDROP memory-only dropper",
                "description": "Identifies SolarWinds TEARDROP memory-only dropper IOCs in Window's defender Exploit Guard activity\nReferences:\n- https://www.fireeye.com/blog/threat-research/2020/12/evasive-attacker-leverages-solarwinds-supply-chain-compromises-with-sunburst-backdoor.html\n- https://gist.github.com/olafhartong/71ffdd4cab4b6acd5cbcd1a0691ff82f",
                "severity": "High",
                "enabled": true,
                "query": "DeviceEvents\n| where ActionType has \"ExploitGuardNonMicrosoftSignedBlocked\"\n| where InitiatingProcessFileName contains \"svchost.exe\" and FileName contains \"NetSetupSvc.dll\"\n| extend timestamp = TimeGenerated, AccountCustomEntity = iff(isnotempty(InitiatingProcessAccountUpn), InitiatingProcessAccountUpn, InitiatingProcessAccountName),\nHostCustomEntity = DeviceName, FileHashCustomEntity = InitiatingProcessSHA1, FileHashType = \"SHA1\"",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Execution",
                    "Persistence",
                    "DefenseEvasion"
                ],
                "techniques": [
                    "T1543",
                    "T1059",
                    "T1027"
                ],
                "alertRuleTemplateName": "738702fd-0a66-42c7-8586-e30f0583f8fe",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "FileHash",
                        "fieldMappings": [
                            {
                                "identifier": "Algorithm",
                                "columnName": "FileHashType"
                            },
                            {
                                "identifier": "Value",
                                "columnName": "FileHashCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.4"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/f58eff8e-23aa-4eb0-a06f-160930203752')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/f58eff8e-23aa-4eb0-a06f-160930203752')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Authentication Methods Changed for Privileged Account",
                "description": "Identifies authentication methods being changed for a privileged account. This could be an indication of an attacker adding an auth method to the account so they can have continued access.\nRef : https://docs.microsoft.com/azure/active-directory/fundamentals/security-operations-privileged-accounts#things-to-monitor-1",
                "severity": "High",
                "enabled": true,
                "query": "let queryperiod = 14d;\nlet queryfrequency = 2h;\nlet security_info_actions = dynamic([\"User registered security info\", \"User changed default security info\", \"User deleted security info\", \"Admin updated security info\", \"User reviewed security info\", \"Admin deleted security info\", \"Admin registered security info\"]);\nlet VIPUsers = (\n    IdentityInfo\n    | where TimeGenerated > ago(queryperiod)\n    | mv-expand AssignedRoles\n    | where AssignedRoles matches regex 'Admin'\n    | summarize by tolower(AccountUPN));\nAuditLogs\n| where TimeGenerated > ago(queryfrequency)\n| where Category =~ \"UserManagement\"\n| where ActivityDisplayName in (security_info_actions)\n| extend Initiator = tostring(InitiatedBy.user.userPrincipalName)\n| extend IP = tostring(InitiatedBy.user.ipAddress)\n| extend Target = tolower(tostring(TargetResources[0].userPrincipalName))\n| where Target in (VIPUsers)\n// Uncomment the line below if you are experiencing high volumes of Target entities. If this is uncommented, the Target column will not be mapped to an entity.\n//| summarize Start=min(TimeGenerated), End=max(TimeGenerated), Actions = make_set(ResultReason, MaxSize=8), Targets=make_set(Target, MaxSize=256) by Initiator, IP, Result\n// Comment out this line below, if line above is used.\n| summarize Start=min(TimeGenerated), End=max(TimeGenerated), Actions = make_set(ResultReason, MaxSize=8) by Initiator, IP, Result, Targets = Target",
                "queryFrequency": "PT2H",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "694c91ee-d606-4ba9-928e-405a2dd0ff0f",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Targets"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Initiator"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IP"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.6"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/f2e6ab80-648c-4cca-be65-cda919793010')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/f2e6ab80-648c-4cca-be65-cda919793010')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Mail.Read Permissions Granted to Application",
                "description": "This query look for applications that have been granted (Delegated or App/Role) permissions to Read Mail (Permissions field has Mail.Read) and subsequently has been consented to. This can help identify applications that have been abused to gain access to mailboxes.",
                "severity": "Medium",
                "enabled": true,
                "query": "AuditLogs\n| where Category =~ \"ApplicationManagement\"\n| where ActivityDisplayName has_any (\"Add delegated permission grant\",\"Add app role assignment to service principal\")\n| where Result =~ \"success\"\n| where tostring(InitiatedBy.user.userPrincipalName) has \"@\" or tostring(InitiatedBy.app.displayName) has \"@\"\n| extend props = parse_json(tostring(TargetResources[0].modifiedProperties))\n| mv-expand props\n| extend UserAgent = tostring(AdditionalDetails[0].value)\n| extend InitiatingUser = tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName)\n| extend UserIPAddress = tostring(parse_json(tostring(InitiatedBy.user)).ipAddress)\n| extend DisplayName = tostring(props.displayName)\n| extend Permissions = tostring(parse_json(tostring(props.newValue)))\n| where Permissions has_any (\"Mail.Read\", \"Mail.ReadWrite\")\n| extend PermissionsAddedTo = tostring(TargetResources[0].displayName)\n| extend Type = tostring(TargetResources[0].type)\n| project-away props\n| join kind=leftouter(\n  AuditLogs\n  | where ActivityDisplayName has \"Consent to application\"\n  | extend AppName = tostring(TargetResources[0].displayName)\n  | extend AppId = tostring(TargetResources[0].id)\n  | project AppName, AppId, CorrelationId) on CorrelationId\n| project-reorder TimeGenerated, OperationName, InitiatingUser, UserIPAddress, UserAgent, PermissionsAddedTo, Permissions, AppName, AppId, CorrelationId\n| extend timestamp = TimeGenerated, AccountCustomEntity = InitiatingUser, IPCustomEntity = UserIPAddress",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "2560515c-07d1-434e-87fb-ebe3af267760",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/a233a0e7-8895-4a16-ad30-b457d8724543')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/a233a0e7-8895-4a16-ad30-b457d8724543')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Azure AD Role Management Permission Grant",
                "description": "Identifies when the Microsoft Graph RoleManagement.ReadWrite.Directory (Delegated or Application) permission is granted to a service principal.\nThis permission allows an application to read and manage the role-based access control (RBAC) settings for your company's directory.\nAn adversary could use this permission to add an Azure AD object to an Admin directory role and escalate privileges.\nRef : https://docs.microsoft.com/graph/permissions-reference#role-management-permissions\nRef : https://docs.microsoft.com/graph/api/directoryrole-post-members?view=graph-rest-1.0&tabs=http",
                "severity": "High",
                "enabled": true,
                "query": "AuditLogs\n| where LoggedByService =~ \"Core Directory\"\n| where Category =~ \"ApplicationManagement\"\n| where AADOperationType =~ \"Assign\"\n| where ActivityDisplayName has_any (\"Add delegated permission grant\",\"Add app role assignment to service principal\")\n| mv-expand TargetResources\n| mv-expand TargetResources.modifiedProperties\n| extend displayName_ = tostring(TargetResources_modifiedProperties.displayName)\n| where displayName_ has_any (\"AppRole.Value\",\"DelegatedPermissionGrant.Scope\")\n| extend Permission = tostring(parse_json(tostring(TargetResources_modifiedProperties.newValue)))\n| where Permission has \"RoleManagement.ReadWrite.Directory\"\n| extend InitiatingApp = tostring(parse_json(tostring(InitiatedBy.app)).displayName)\n| extend Initiator = iif(isnotempty(InitiatingApp), InitiatingApp, tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName))\n| extend Target = tostring(parse_json(tostring(TargetResources.modifiedProperties[4].newValue)))\n| extend TargetId = iif(displayName_ =~ 'DelegatedPermissionGrant.Scope',\n  tostring(parse_json(tostring(TargetResources.modifiedProperties[2].newValue))),\n  tostring(parse_json(tostring(TargetResources.modifiedProperties[3].newValue))))\n| summarize by bin(TimeGenerated, 1h), OperationName, Initiator, Target, TargetId, Result",
                "queryFrequency": "PT2H",
                "queryPeriod": "PT2H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "Impact"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "1ff56009-db01-4615-8211-d4fda21da02d",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Initiator"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Target"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/649ab011-8c8f-430d-9655-7455556e4102')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/649ab011-8c8f-430d-9655-7455556e4102')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "DEV-0270 New User Creation",
                "description": "The following query tries to detect creation of a new user using a known DEV-0270 username/password schema",
                "severity": "High",
                "enabled": true,
                "query": "(union isfuzzy=true\n(SecurityEvent\n| where EventID == 4688\n| where CommandLine has_all ('net user', '/add') \n| parse CommandLine with * \"user \" username \" \"*\n| extend password = extract(@\"\\buser\\s+[^\\s]+\\s+([^\\s]+)\", 1, CommandLine) \n| where username in('DefaultAccount') or password in('P@ssw0rd1234', '_AS_@1394') \n| project TimeGenerated, HostCustomEntity = Computer, AccountCustomEntity = Account, AccountDomain, ProcessName, ProcessNameFullPath = NewProcessName, EventID, Activity, CommandLine, EventSourceName, Type\n),\n(DeviceProcessEvents \n| where InitiatingProcessCommandLine has_all('net user', '/add') \n| parse InitiatingProcessCommandLine with * \"user \" username \" \"* \n| extend password = extract(@\"\\buser\\s+[^\\s]+\\s+([^\\s]+)\", 1, InitiatingProcessCommandLine) \n| where username in('DefaultAccount') or password in('P@ssw0rd1234', '_AS_@1394') \n| extend timestamp = TimeGenerated, AccountCustomEntity =  InitiatingProcessAccountName, HostCustomEntity = DeviceName\n)\n)",
                "queryFrequency": "PT6H",
                "queryPeriod": "PT6H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "7965f0be-c039-4d18-8ee8-9a6add8aecf3",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/6be13ffe-1e33-44b5-ba99-9b2d358f5902')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/6be13ffe-1e33-44b5-ba99-9b2d358f5902')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Group created then added to built in domain local or global group",
                "description": "Identifies when a recently created Group was added to a privileged built in domain local group or global group such as the \nEnterprise Admins, Cert Publishers or DnsAdmins.  Be sure to verify this is an expected addition.\nReferences: For AD SID mappings - https://docs.microsoft.com/windows/security/identity-protection/access-control/active-directory-security-groups.",
                "severity": "Medium",
                "enabled": true,
                "query": "let WellKnownLocalSID = \"S-1-5-32-5[0-9][0-9]$\";\nlet WellKnownGroupSID = \"S-1-5-21-[0-9]*-[0-9]*-[0-9]*-5[0-9][0-9]$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1102$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1103$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-498$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1000$\";\nlet GroupAddition = (union isfuzzy=true   \n(SecurityEvent \n// 4728 - A member was added to a security-enabled global group\n// 4732 - A member was added to a security-enabled local group\n// 4756 - A member was added to a security-enabled universal group  \n| where EventID in (\"4728\", \"4732\", \"4756\")\n| where AccountType =~ \"User\"\n// Exclude Remote Desktop Users group: S-1-5-32-555\n| where TargetSid !in (\"S-1-5-32-555\")\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| project GroupAddTime = TimeGenerated, GroupAddEventID = EventID, GroupAddActivity = Activity, GroupAddComputer = Computer, GroupAddTargetAccount = TargetAccount, \nGroupAddTargetSid = TargetSid, GroupAddSubjectAccount = SubjectAccount, GroupAddSubjectUserSid = SubjectUserSid, GroupSid = MemberSid\n),\n(\nWindowsEvent \n// 4728 - A member was added to a security-enabled global group\n// 4732 - A member was added to a security-enabled local group\n// 4756 - A member was added to a security-enabled universal group  \n| where EventID in (\"4728\", \"4732\", \"4756\")  and not(EventData has \"S-1-5-32-555\")\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend Account = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend AccountType=case(Account endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| extend MemberName = tostring(EventData.MemberName)\n| where AccountType =~ \"User\"\n// Exclude Remote Desktop Users group: S-1-5-32-555\n| extend TargetSid = tostring(EventData.TargetSid)\n| where TargetSid !in (\"S-1-5-32-555\")\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| extend MemberSid = tostring(EventData.MemberSid)\n| extend Activity= \"GroupAddActivity\"\n| project GroupAddTime = TimeGenerated, GroupAddEventID = EventID, GroupAddActivity = Activity, GroupAddComputer = Computer, GroupAddTargetAccount = TargetAccount, \nGroupAddTargetSid = TargetSid, GroupAddSubjectAccount = Account, GroupAddSubjectUserSid = SubjectUserSid, GroupSid = MemberSid\n));\nlet GroupCreated = (union isfuzzy=true  \n(SecurityEvent\n// 4727 - A security-enabled global group was created\n// 4731 - A security-enabled local group was created\n// 4754 - A security-enabled universal group was created\n| where EventID in (\"4727\", \"4731\", \"4754\")\n| where AccountType =~ \"User\"\n| project GroupCreateTime = TimeGenerated, GroupCreateEventID = EventID, GroupCreateActivity = Activity, GroupCreateComputer = Computer, GroupCreateTargetAccount = TargetAccount, \nGroupCreateSubjectAccount = SubjectAccount, GroupCreateSubjectUserSid = SubjectUserSid, GroupSid = TargetSid\n),\n(WindowsEvent\n// 4727 - A security-enabled global group was created\n// 4731 - A security-enabled local group was created\n// 4754 - A security-enabled universal group was created\n| where EventID in (\"4727\", \"4731\", \"4754\")\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend Account = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend AccountType=case(Account endswith \"$\", \"Machine\", iff(SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", iff(isempty(SubjectUserSid), \"\", \"User\")))\n| where AccountType =~ \"User\"\n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| extend SubjectAccount = strcat(EventData.SubjectDomainName,\"\\\\\", EventData.SubjectUserName)  \n| extend TargetSid = tostring(EventData.TargetSid) \n| extend Activity= \"GroupAddActivity\"\n| project GroupCreateTime = TimeGenerated, GroupCreateEventID = EventID, GroupCreateActivity = Activity, GroupCreateComputer = Computer, GroupCreateTargetAccount = TargetAccount, \nGroupCreateSubjectAccount = SubjectAccount, GroupCreateSubjectUserSid = SubjectUserSid, GroupSid = TargetSid\n));\nGroupCreated\n| join (\nGroupAddition\n) on GroupSid",
                "queryFrequency": "PT1H",
                "queryPeriod": "PT1H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "a7564d76-ec6b-4519-a66b-fcc80c42332b",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "GroupCreateSubjectAccount"
                            },
                            {
                                "identifier": "Sid",
                                "columnName": "GroupCreateSubjectUserSid"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "GroupCreateComputer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/335ba65c-a1e2-463b-971f-277eb204f1c0')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/335ba65c-a1e2-463b-971f-277eb204f1c0')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Authentication Method Changed for Privileged Account",
                "description": "Identifies authentication methods being changed for a privileged account. This could be an indicated of an attacker adding an auth method to the account so they can have continued access.\nRef : https://docs.microsoft.com/azure/active-directory/fundamentals/security-operations-privileged-accounts#things-to-monitor-1",
                "severity": "High",
                "enabled": true,
                "query": "let VIPUsers = (IdentityInfo\n| where AssignedRoles contains \"Admin\"\n| summarize by tolower(AccountUPN));\nAuditLogs\n| where Category =~ \"UserManagement\"\n| where ActivityDisplayName =~ \"User registered security info\"\n| where LoggedByService =~ \"Authentication Methods\"\n| extend AccountCustomEntity = tostring(TargetResources[0].userPrincipalName), IPCustomEntity = tostring(parse_json(tostring(InitiatedBy.user)).ipAddress)\n| where AccountCustomEntity in (VIPUsers)",
                "queryFrequency": "PT2H",
                "queryPeriod": "PT2H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "feb0a2fb-ae75-4343-8cbc-ed545f1da289",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/fe2827db-6887-4eb3-a4ad-49a70a7c7a1c')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/fe2827db-6887-4eb3-a4ad-49a70a7c7a1c')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Anomalous login followed by Teams action",
                "description": "Detects anomalous IP address usage by user accounts and then checks to see if a suspicious Teams action is performed.\nQuery calculates IP usage Delta for each user account and selects accounts where a delta >= 90% is observed between the most and least used IP.\nTo further reduce results the query performs a prevalence check on the lowest used IP's country, only keeping IP's where the country is unusual for the tenant (dynamic ranges)\nFinally the user accounts activity within Teams logs is checked for suspicious commands (modifying user privileges or admin actions) during the period the suspicious IP was active.",
                "severity": "Medium",
                "enabled": true,
                "query": "//The bigger the window the better the data sample size, as we use IP prevalence, more sample data is better.\n//The minimum number of countries that the account has been accessed from [default: 2]\nlet minimumCountries = 2;\n//The delta (%) between the largest in-use IP and the smallest [default: 95]\nlet deltaThreshold = 95;\n//The maximum (%) threshold that the country appears in login data [default: 10]\nlet countryPrevalenceThreshold = 10;\n//The time to project forward after the last login activity [default: 60min]\nlet projectedEndTime = 60m;\nlet queryfrequency = 1d;\nlet queryperiod = 14d;\nlet aadFunc = (tableName: string) {\n    // Get successful signins to Teams\n    let signinData =\n        table(tableName)\n        | where TimeGenerated > ago(queryperiod)\n        | where AppDisplayName has \"Teams\" and ConditionalAccessStatus =~ \"success\"\n        | extend Country = tostring(todynamic(LocationDetails)['countryOrRegion'])\n        | where isnotempty(Country) and isnotempty(IPAddress);\n    // Calculate prevalence of countries\n    let countryPrevalence =\n        signinData\n        | summarize CountCountrySignin = count() by Country\n        | extend TotalSignin = toscalar(signinData | summarize count())\n        | extend CountryPrevalence = toreal(CountCountrySignin) / toreal(TotalSignin) * 100;\n    // Count signins by user and IP address\n    let userIpSignin =\n        signinData\n        | summarize CountIPSignin = count(), Country = any(Country), ListSigninTimeGenerated = make_list(TimeGenerated) by IPAddress, UserPrincipalName;\n    // Calculate delta between the IP addresses with the most and minimum activity by user\n    let userIpDelta =\n        userIpSignin\n        | summarize MaxIPSignin = max(CountIPSignin), MinIPSignin = min(CountIPSignin), DistinctCountries = dcount(Country), make_set(Country) by UserPrincipalName\n        | extend UserIPDelta = toreal(MaxIPSignin - MinIPSignin) / toreal(MaxIPSignin) * 100;\n    // Collect Team operations the user account has performed within a time range of the suspicious signins\n    OfficeActivity\n    | where TimeGenerated > ago(queryfrequency)\n    | where Operation in~ (\"TeamsAdminAction\", \"MemberAdded\", \"MemberRemoved\", \"MemberRoleChanged\", \"AppInstalled\", \"BotAddedToTeam\")\n    | project OperationTimeGenerated = TimeGenerated, UserId = tolower(UserId), Operation\n    | join kind = inner(\n        userIpDelta\n        // Check users with activity from distinct countries\n        | where DistinctCountries >= minimumCountries\n        // Check users with high IP delta\n        | where UserIPDelta >= deltaThreshold\n        // Add information about signins and countries\n        | join kind = leftouter userIpSignin on UserPrincipalName\n        | join kind = leftouter countryPrevalence on Country\n        // Check activity that comes from nonprevalent countries\n        | where CountryPrevalence < countryPrevalenceThreshold\n        | project\n            UserPrincipalName,\n            SuspiciousIP = IPAddress,\n            UserIPDelta,\n            SuspiciousSigninCountry = Country,\n            SuspiciousCountryPrevalence = CountryPrevalence,\n            EventTimes = ListSigninTimeGenerated\n    ) on $left.UserId == $right.UserPrincipalName\n    // Check the signins occured 60 min before the Teams operations\n    | mv-expand SigninTimeGenerated = EventTimes\n    | extend SigninTimeGenerated = todatetime(SigninTimeGenerated)\n    | where OperationTimeGenerated between (SigninTimeGenerated .. (SigninTimeGenerated + projectedEndTime))\n};\nlet aadSignin = aadFunc(\"SigninLogs\");\nlet aadNonInt = aadFunc(\"AADNonInteractiveUserSignInLogs\");\nunion isfuzzy=true aadSignin, aadNonInt\n| summarize arg_max(SigninTimeGenerated, *) by UserPrincipalName, SuspiciousIP, OperationTimeGenerated\n| summarize\n    ActivitySummary = make_bag(pack(tostring(SigninTimeGenerated), pack(\"Operation\", tostring(Operation), \"OperationTime\", OperationTimeGenerated)))\n    by UserPrincipalName, SuspiciousIP, SuspiciousSigninCountry, SuspiciousCountryPrevalence\n| extend IPCustomEntity = SuspiciousIP, AccountCustomEntity = UserPrincipalName",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "InitialAccess",
                    "Persistence"
                ],
                "techniques": [
                    "T1199",
                    "T1136",
                    "T1078",
                    "T1098"
                ],
                "alertRuleTemplateName": "2b701288-b428-4fb8-805e-e4372c574786",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/a3d6ec86-93e7-4a4c-92a2-f07223c85367')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/a3d6ec86-93e7-4a4c-92a2-f07223c85367')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "New user created and added to the built-in administrators group",
                "description": "Identifies when a user account was created and then added to the builtin Administrators group in the same day.\nThis should be monitored closely and all additions reviewed.",
                "severity": "Low",
                "enabled": true,
                "query": "(union isfuzzy=true\n(SecurityEvent\n| where EventID == 4720\n| where AccountType == \"User\"\n| project CreatedUserTime = TimeGenerated, CreatedUserEventID = EventID, CreatedUserActivity = Activity, Computer = toupper(Computer), \nCreatedUser = tolower(TargetAccount), CreatedUserSid = TargetSid, AccountUsedToCreateUser = strcat(SubjectAccount), SidofAccountUsedToCreateUser = SubjectUserSid\n),\n(WindowsEvent\n| where EventID == 4720\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend AccountType=case(EventData.SubjectUserName endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| where AccountType == \"User\"\n| extend SubjectAccount = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| extend Activity=\"4720 - A user account was created.\"\n| extend TargetSid = tostring(EventData.TargetSid)\n| project CreatedUserTime = TimeGenerated, CreatedUserEventID = EventID, CreatedUserActivity = Activity, Computer = toupper(Computer), \nCreatedUser = tolower(TargetAccount), CreatedUserSid = TargetSid, AccountUsedToCreateUser = strcat(SubjectAccount), SidofAccountUsedToCreateUser = SubjectUserSid\n))\n| join ((union isfuzzy=true\n(SecurityEvent \n| where AccountType == \"User\"\n// 4732 - A member was added to a security-enabled local group\n| where EventID == 4732\n// TargetSid is the builin Admins group: S-1-5-32-544\n| where TargetSid == \"S-1-5-32-544\"\n| project GroupAddTime = TimeGenerated, GroupAddEventID = EventID, GroupAddActivity = Activity, Computer = toupper(Computer), GroupName = tolower(TargetAccount), \nGroupSid = TargetSid, AccountThatAddedUser = SubjectAccount, SIDofAccountThatAddedUser = SubjectUserSid, CreatedUserSid = MemberSid\n),\n(  WindowsEvent \n// 4732 - A member was added to a security-enabled local group\n| where EventID == 4732 and EventData has \"S-1-5-32-544\"\n//TargetSid is the builin Admins group: S-1-5-32-544\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend AccountType=case(EventData.SubjectUserName endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| where AccountType == \"User\"\n| extend TargetSid = tostring(EventData.TargetSid)\n| where TargetSid == \"S-1-5-32-544\"\n| extend SubjectAccount = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| extend Activity=\"4732 - A member was added to a security-enabled local group.\"\n| extend MemberSid = tostring(EventData.MemberSid)\n| project GroupAddTime = TimeGenerated, GroupAddEventID = EventID, GroupAddActivity = Activity, Computer = toupper(Computer), GroupName = tolower(TargetAccount), \nGroupSid = TargetSid, AccountThatAddedUser = SubjectAccount, SIDofAccountThatAddedUser = SubjectUserSid, CreatedUserSid = MemberSid)\n))\non CreatedUserSid\n//Create User first, then the add to the group.\n| project Computer, CreatedUserTime, CreatedUserEventID, CreatedUserActivity, CreatedUser, CreatedUserSid, GroupAddTime, GroupAddEventID, \nGroupAddActivity, AccountUsedToCreateUser, GroupName, GroupSid, AccountThatAddedUser, SIDofAccountThatAddedUser \n| extend timestamp = CreatedUserTime, AccountCustomEntity = CreatedUser, HostCustomEntity = Computer",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "aa1eff90-29d4-49dc-a3ea-b65199f516db",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            },
                            {
                                "identifier": "Sid",
                                "columnName": "CreatedUserSid"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/19e1c609-437f-49d0-a0a1-1857bb098f0b')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/19e1c609-437f-49d0-a0a1-1857bb098f0b')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "NRT",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "NRT Malicious Inbox Rule",
                "description": "Often times after the initial compromise the attackers create inbox rules to delete emails that contain certain keywords.\n This is done so as to limit ability to warn compromised users that they've been compromised. Below is a sample query that tries to detect this.\nReference: https://www.reddit.com/r/sysadmin/comments/7kyp0a/recent_phishing_attempts_my_experience_and_what/",
                "severity": "Medium",
                "enabled": true,
                "query": "let Keywords = dynamic([\"helpdesk\", \" alert\", \" suspicious\", \"fake\", \"malicious\", \"phishing\", \"spam\", \"do not click\", \"do not open\", \"hijacked\", \"Fatal\"]);\nOfficeActivity\n| where OfficeWorkload =~ \"Exchange\"\n| where Parameters has \"Deleted Items\" or Parameters has \"Junk Email\"  or Parameters has \"DeleteMessage\"\n| extend Events=todynamic(Parameters)\n| parse Events  with * \"SubjectContainsWords\" SubjectContainsWords '}'*\n| parse Events  with * \"BodyContainsWords\" BodyContainsWords '}'*\n| parse Events  with * \"SubjectOrBodyContainsWords\" SubjectOrBodyContainsWords '}'*\n| where SubjectContainsWords has_any (Keywords)\n or BodyContainsWords has_any (Keywords)\n or SubjectOrBodyContainsWords has_any (Keywords)\n| extend ClientIPAddress = case( ClientIP has \".\", tostring(split(ClientIP,\":\")[0]), ClientIP has \"[\", tostring(trim_start(@'[[]',tostring(split(ClientIP,\"]\")[0]))), ClientIP )\n| extend Keyword = iff(isnotempty(SubjectContainsWords), SubjectContainsWords, (iff(isnotempty(BodyContainsWords),BodyContainsWords,SubjectOrBodyContainsWords )))\n| extend RuleDetail = case(OfficeObjectId contains '/' , tostring(split(OfficeObjectId, '/')[-1]) , tostring(split(OfficeObjectId, '\\\\')[-1]))\n| summarize count(), StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by  UserId, ClientIPAddress, ResultStatus, Keyword, OriginatingServer, OfficeObjectId, RuleDetail",
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "tactics": [
                    "Persistence",
                    "DefenseEvasion"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "b79f6190-d104-4691-b7db-823e05980895",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "UserId"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "OriginatingServer"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "ClientIPAddress"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/1bde628a-d519-49f7-8af4-e4324d10d6ea')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/1bde628a-d519-49f7-8af4-e4324d10d6ea')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Office policy tampering",
                "description": "Identifies if any tampering is done to either auditlog, ATP Safelink, SafeAttachment, AntiPhish or Dlp policy. \nAn adversary may use this technique to evade detection or avoid other policy based defenses.\nReferences: https://docs.microsoft.com/powershell/module/exchange/advanced-threat-protection/remove-antiphishrule?view=exchange-ps.",
                "severity": "Medium",
                "enabled": true,
                "query": "let opList = OfficeActivity \n| summarize by Operation\n//| where Operation startswith \"Remove-\" or Operation startswith \"Disable-\"\n| where Operation has_any (\"Remove\", \"Disable\")\n| where Operation contains \"AntiPhish\" or Operation contains \"SafeAttachment\" or Operation contains \"SafeLinks\" or Operation contains \"Dlp\" or Operation contains \"Audit\"\n| summarize make_set(Operation);\nOfficeActivity\n// Only admin or global-admin can disable/remove policy\n| where RecordType =~ \"ExchangeAdmin\"\n| where UserType in~ (\"Admin\",\"DcAdmin\")\n// Pass in interesting Operation list\n| where Operation in~ (opList)\n| extend ClientIPOnly = case( \nClientIP has \".\", tostring(split(ClientIP,\":\")[0]), \nClientIP has \"[\", tostring(trim_start(@'[[]',tostring(split(ClientIP,\"]\")[0]))),\nClientIP\n)  \n| extend Port = case(\nClientIP has \".\", (split(ClientIP,\":\")[1]),\nClientIP has \"[\", tostring(split(ClientIP,\"]:\")[1]),\nClientIP\n)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), OperationCount = count() by Operation, UserType, UserId, ClientIP = ClientIPOnly, Port, ResultStatus, Parameters\n| extend timestamp = StartTimeUtc, AccountCustomEntity = UserId, IPCustomEntity = ClientIP",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "DefenseEvasion"
                ],
                "techniques": [
                    "T1098",
                    "T1562"
                ],
                "alertRuleTemplateName": "fbd72eb8-087e-466b-bd54-1ca6ea08c6d3",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "2.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/ccb42773-0a9f-4822-a1d5-00ba03f9cd12')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/ccb42773-0a9f-4822-a1d5-00ba03f9cd12')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AD account with Don't Expire Password",
                "description": "Identifies whenever a user account has the setting \"Password Never Expires\" in the user account properties selected.\nThis is indicated in Security event 4738 in the EventData item labeled UserAccountControl with an included value of %%2089.\n%%2089 resolves to \"Don't Expire Password - Enabled\".",
                "severity": "Low",
                "enabled": true,
                "query": "union isfuzzy=true\n(\n SecurityEvent\n | where EventID == 4738\n // 2089 value indicates the Don't Expire Password value has been set\n | where UserAccountControl has \"%%2089\"\n | extend Value_2089 = iff(UserAccountControl has \"%%2089\",\"'Don't Expire Password' - Enabled\", \"Not Changed\")\n // 2050 indicates that the Password Not Required value is NOT set, this often shows up at the same time as a 2089 and is the recommended value.  This value may not be in the event.\n | extend Value_2050 = iff(UserAccountControl has \"%%2050\",\"'Password Not Required' - Disabled\", \"Not Changed\")\n // If value %%2082 is present in the 4738 event, this indicates the account has been configured to logon WITHOUT a password. Generally you should only see this value when an account is created and only in Event 4720: Account Creation Event.\n | extend Value_2082 = iff(UserAccountControl has \"%%2082\",\"'Password Not Required' - Enabled\", \"Not Changed\")\n | project StartTime = TimeGenerated, EventID, Activity, Computer, TargetAccount, TargetSid, AccountType, UserAccountControl, Value_2089, Value_2050, Value_2082, SubjectAccount\n | extend timestamp = StartTime, AccountCustomEntity = TargetAccount, HostCustomEntity = Computer\n ),\n (\n WindowsEvent\n | where EventID == 4738 and EventData has '2089'\n // 2089 value indicates the Don't Expire Password value has been set\n | extend UserAccountControl = tostring(EventData.UserAccountControl)\n | where UserAccountControl has \"%%2089\"\n | extend Value_2089 = iff(UserAccountControl has \"%%2089\",\"'Don't Expire Password' - Enabled\", \"Not Changed\")\n // 2050 indicates that the Password Not Required value is NOT set, this often shows up at the same time as a 2089 and is the recommended value.  This value may not be in the event.\n | extend Value_2050 = iff(UserAccountControl has \"%%2050\",\"'Password Not Required' - Disabled\", \"Not Changed\")\n // If value %%2082 is present in the 4738 event, this indicates the account has been configured to logon WITHOUT a password. Generally you should only see this value when an account is created and only in Event 4720: Account Creation Event.\n | extend Value_2082 = iff(UserAccountControl has \"%%2082\",\"'Password Not Required' - Enabled\", \"Not Changed\")\n | extend Activity=\"4738 - A user account was changed.\"\n | extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n | extend TargetSid = tostring(EventData.TargetSid)\n | extend SubjectAccount = strcat(EventData.SubjectDomainName,\"\\\\\", EventData.SubjectUserName)\n | extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n | extend AccountType=case(SubjectAccount endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n | project StartTime = TimeGenerated, EventID, Activity, Computer, TargetAccount, TargetSid, AccountType, UserAccountControl, Value_2089, Value_2050, Value_2082, SubjectAccount\n | extend timestamp = StartTime, AccountCustomEntity = TargetAccount, HostCustomEntity = Computer\n )",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "6c360107-f3ee-4b91-9f43-f4cfd90441cf",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            },
                            {
                                "identifier": "Sid",
                                "columnName": "TargetSid"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/f141a617-d841-431a-a356-7bcfb6cb4e9e')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/f141a617-d841-431a-a356-7bcfb6cb4e9e')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "User account created and deleted within 10 mins",
                "description": "Identifies when a user account is created and then deleted within 10 minutes. This can be an indication of compromise and\nan adversary attempting to hide in the noise.",
                "severity": "Medium",
                "enabled": true,
                "query": "let timeframe = 1d;\nlet spanoftime = 10m;\nlet threshold = 0;\n (union isfuzzy=true\n (SecurityEvent\n| where TimeGenerated > ago(timeframe+spanoftime)\n// A user account was created\n| where EventID == 4720\n| where AccountType =~ \"User\"\n| project creationTime = TimeGenerated, CreateEventID = EventID, CreateActivity = Activity, Computer, TargetUserName, UserPrincipalName, \nAccountUsedToCreate = SubjectAccount, SIDofAccountUsedToCreate = SubjectUserSid, TargetAccount = tolower(TargetAccount), TargetSid\n),\n(\nWindowsEvent\n| where TimeGenerated > ago(timeframe+spanoftime)\n// A user account was created\n| where EventID == 4720\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend AccountType=case(EventData.SubjectUserName endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| where AccountType =~ \"User\"\n| extend SubjectAccount = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| extend TargetSid = tostring(EventData.TargetSid)\n| extend UserPrincipalName = tostring(EventData.UserPrincipalName)\n| extend Activity = \"4720 - A user account was created.\"\n| extend TargetUserName = tostring(EventData.TargetUserName) \n| project creationTime = TimeGenerated, CreateEventID = EventID, CreateActivity = Activity, Computer, TargetUserName, UserPrincipalName, \nAccountUsedToCreate = SubjectAccount, SIDofAccountUsedToCreate = SubjectUserSid, TargetAccount = tolower(TargetAccount), TargetSid  \n))\n| join kind= inner (\n  (union isfuzzy=true\n  (SecurityEvent\n  | where TimeGenerated > ago(timeframe)\n  // A user account was deleted\n  | where EventID == 4726\n| where AccountType == \"User\"\n| project deletionTime = TimeGenerated, DeleteEventID = EventID, DeleteActivity = Activity, Computer, TargetUserName, UserPrincipalName, \nAccountUsedToDelete = SubjectAccount, SIDofAccountUsedToDelete = SubjectUserSid, TargetAccount = tolower(TargetAccount), TargetSid\n),\n(WindowsEvent\n| where TimeGenerated > ago(timeframe)\n  // A user account was deleted\n| where EventID == 4726\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend SubjectAccount = strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend AccountType=case(SubjectAccount endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| where AccountType == \"User\"\n| extend TargetSid = tostring(EventData.TargetSid)\n| extend UserPrincipalName = tostring(EventData.UserPrincipalName)\n| extend Activity = \"4726 - A user account was deleted.\"\n| extend TargetUserName = tostring(EventData.TargetUserName) \n| extend TargetAccount = strcat(EventData.TargetDomainName,\"\\\\\", EventData.TargetUserName)\n| project deletionTime = TimeGenerated, DeleteEventID = EventID, DeleteActivity = Activity, Computer, TargetUserName, UserPrincipalName, AccountUsedToDelete = SubjectAccount, SIDofAccountUsedToDelete = SubjectUserSid, TargetAccount = tolower(TargetAccount), TargetSid))\n) on Computer, TargetAccount\n| where deletionTime - creationTime < spanoftime\n| extend TimeDelta = deletionTime - creationTime\n| where tolong(TimeDelta) >= threshold\n| project TimeDelta, creationTime, CreateEventID, CreateActivity, Computer, TargetAccount, TargetSid, UserPrincipalName, AccountUsedToCreate, SIDofAccountUsedToCreate,\ndeletionTime, DeleteEventID, DeleteActivity, AccountUsedToDelete, SIDofAccountUsedToDelete\n| extend timestamp = creationTime, AccountCustomEntity = AccountUsedToCreate, HostCustomEntity = Computer",
                "queryFrequency": "P1D",
                "queryPeriod": "PT25H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "4b93c5af-d20b-4236-b696-a28b8c51407f",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            },
                            {
                                "identifier": "Sid",
                                "columnName": "SIDofAccountUsedToCreate"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/cc2e856f-55a1-4cc4-9162-3487f1335391')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/cc2e856f-55a1-4cc4-9162-3487f1335391')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Account added and removed from privileged groups",
                "description": "Identifies accounts that are added to privileged group and then quickly removed, which could be a sign of compromise.",
                "severity": "Low",
                "enabled": true,
                "query": "let WellKnownLocalSID = \"S-1-5-32-5[0-9][0-9]$\";\nlet WellKnownGroupSID = \"S-1-5-21-[0-9]*-[0-9]*-[0-9]*-5[0-9][0-9]$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1102$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1103$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-498$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1000$\";\nlet AC_Add =\n(union isfuzzy=true\n(SecurityEvent\n// Event ID related to member addition.\n| where EventID in (4728, 4732,4756)\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| parse EventData with * '\"MemberName\">' * '=' AccountAdded \",OU\" *\n| where isnotempty(AccountAdded)\n| extend GroupAddedTo = TargetUserName, AddingAccount = Account\n| extend  AccountAdded_GroupAddedTo_AddingAccount = strcat(AccountAdded, \"||\", GroupAddedTo, \"||\", AddingAccount )\n| project AccountAdded_GroupAddedTo_AddingAccount, AccountAddedTime = TimeGenerated\n),\n(WindowsEvent\n// Event ID related to member addition.\n| where EventID in (4728, 4732,4756)\n| extend TargetSid = tostring(EventData.TargetSid)\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| parse EventData.MemberName with * '\"MemberName\">' * '=' AccountAdded \",OU\" *\n| where isnotempty(AccountAdded)\n| extend TargetUserName = tostring(EventData.TargetUserName)\n| extend AddingAccount =  strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend GroupAddedTo = TargetUserName\n| extend  AccountAdded_GroupAddedTo_AddingAccount = strcat(AccountAdded, \"||\", GroupAddedTo, \"||\", AddingAccount )\n| project AccountAdded_GroupAddedTo_AddingAccount, AccountAddedTime = TimeGenerated\n)\n);\nlet AC_Remove =\n( union isfuzzy=true\n(SecurityEvent\n// Event IDs related to member removal.\n| where EventID in (4729,4733,4757)\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| parse EventData with * '\"MemberName\">' * '=' AccountRemoved \",OU\" *\n| where isnotempty(AccountRemoved)\n| extend GroupRemovedFrom = TargetUserName, RemovingAccount = Account\n| extend AccountRemoved_GroupRemovedFrom_RemovingAccount = strcat(AccountRemoved, \"||\", GroupRemovedFrom, \"||\", RemovingAccount)\n| project AccountRemoved_GroupRemovedFrom_RemovingAccount, AccountRemovedTime = TimeGenerated, Computer, RemovedAccountId = tolower(AccountRemoved),\nRemovedByUser = SubjectUserName, RemovedByUserLogonId = SubjectLogonId,  GroupRemovedFrom = TargetUserName, TargetDomainName\n),\n(WindowsEvent\n// Event IDs related to member removal.\n| where EventID in (4729,4733,4757)\n| extend TargetSid = tostring(EventData.TargetSid)\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n| parse EventData.MemberName with * '\"MemberName\">' * '=' AccountRemoved \",OU\" *\n| where isnotempty(AccountRemoved)\n| extend TargetUserName = tostring(EventData.TargetUserName)\n| extend RemovingAccount =  strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend GroupRemovedFrom = TargetUserName\n| extend AccountRemoved_GroupRemovedFrom_RemovingAccount = strcat(AccountRemoved, \"||\", GroupRemovedFrom, \"||\", RemovingAccount)\n| extend SubjectUserName = tostring(EventData.SubjectUserName)\n| extend SubjectLogonId = tostring(EventData.SubjectLogonId)\n| extend TargetDomainName = tostring(EventData.TargetDomainName)\n| project AccountRemoved_GroupRemovedFrom_RemovingAccount, AccountRemovedTime = TimeGenerated, Computer, RemovedAccountId = tolower(AccountRemoved),\nRemovedByUser = SubjectUserName, RemovedByUserLogonId = SubjectLogonId,  GroupRemovedFrom = TargetUserName, TargetDomainName\n));\nAC_Add\n| join kind= inner AC_Remove on $left.AccountAdded_GroupAddedTo_AddingAccount == $right.AccountRemoved_GroupRemovedFrom_RemovingAccount\n| extend DurationinSecondAfter_Removed = datetime_diff ('second', AccountRemovedTime, AccountAddedTime)\n| where DurationinSecondAfter_Removed > 0\n| project-away AccountRemoved_GroupRemovedFrom_RemovingAccount\n| extend timestamp = AccountAddedTime, AccountCustomEntity = RemovedAccountId, HostCustomEntity = Computer",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "7efc75ce-e2a4-400f-a8b1-283d3b0f2c60",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/5fea060f-0536-4768-90bc-364e4026189d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/5fea060f-0536-4768-90bc-364e4026189d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "User added to Azure Active Directory Privileged Groups",
                "description": "This will alert when a user is added to any of the Privileged Groups.\nFor further information on AuditLogs please see https://docs.microsoft.com/azure/active-directory/reports-monitoring/reference-audit-activities.\nFor Administrator role permissions in Azure Active Directory please see https://docs.microsoft.com/azure/active-directory/users-groups-roles/directory-assign-admin-roles",
                "severity": "Medium",
                "enabled": true,
                "query": "let OperationList = dynamic([\"Add member to role\",\"Add member to role in PIM requested (permanent)\"]);\nlet PrivilegedGroups = dynamic([\"UserAccountAdmins\",\"PrivilegedRoleAdmins\",\"TenantAdmins\"]);\nAuditLogs\n//| where LoggedByService =~ \"Core Directory\"\n| where Category =~ \"RoleManagement\"\n| where OperationName in~ (OperationList)\n| mv-expand TargetResources\n| extend modProps = parse_json(TargetResources).modifiedProperties\n| mv-expand bagexpansion=array modProps\n| evaluate bag_unpack(modProps)\n| extend displayName = column_ifexists(\"displayName\", \"NotAvailable\"), newValue = column_ifexists(\"newValue\", \"NotAvailable\")\n| where displayName =~ \"Role.WellKnownObjectName\"\n| extend DisplayName = displayName, GroupName = replace('\"','',newValue)\n| extend initByApp = parse_json(InitiatedBy).app, initByUser = parse_json(InitiatedBy).user\n| extend AppId = initByApp.appId, \nInitiatedByDisplayName = case(isnotempty(initByApp.displayName), initByApp.displayName, isnotempty(initByUser.displayName), initByUser.displayName, \"not available\"),\nServicePrincipalId = tostring(initByApp.servicePrincipalId),\nServicePrincipalName = tostring(initByApp.servicePrincipalName),\nUserId = initByUser.id,\nUserIPAddress = initByUser.ipAddress,\nUserRoles = initByUser.roles,\nUserPrincipalName = tostring(initByUser.userPrincipalName),\nTargetUserPrincipalName = tostring(TargetResources.userPrincipalName)\n| where GroupName in~ (PrivilegedGroups)\n// If you don't want to alert for operations from PIM, remove below filtering for MS-PIM.\n//| where InitiatedByDisplayName != \"MS-PIM\"\n| project TimeGenerated, AADOperationType, Category, OperationName, AADTenantId, AppId, InitiatedByDisplayName, ServicePrincipalId, ServicePrincipalName, DisplayName, GroupName, UserId, UserIPAddress, UserRoles, UserPrincipalName, TargetUserPrincipalName\n| extend timestamp = TimeGenerated, AccountCustomEntity = case(isnotempty(ServicePrincipalName), ServicePrincipalName, isnotempty(ServicePrincipalId), ServicePrincipalId, isnotempty(UserPrincipalName), UserPrincipalName, \"not available\")",
                "queryFrequency": "PT1H",
                "queryPeriod": "PT1H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "4d94d4a9-dc96-410a-8dea-4d4d4584188b",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "TargetUserPrincipalName"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/66cb59d0-f11e-4a42-b817-f6cb85af6f1c')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/66cb59d0-f11e-4a42-b817-f6cb85af6f1c')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Sign-ins from IPs that attempt sign-ins to disabled accounts",
                "description": "Identifies IPs with failed attempts to sign in to one or more disabled accounts and where that same IP has had successful signins from other accounts.\nThis could indicate an attacker who obtained credentials for a list of accounts and is attempting to login with those accounts, some of which may have already been disabled.\nReferences: https://docs.microsoft.com/azure/active-directory/reports-monitoring/reference-sign-ins-error-codes\n50057 - User account is disabled. The account has been disabled by an administrator.",
                "severity": "Medium",
                "enabled": true,
                "query": "let aadFunc = (tableName:string){\ntable(tableName)\n| where ResultType == \"50057\"\n| where ResultDescription == \"User account is disabled. The account has been disabled by an administrator.\"\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), disabledAccountLoginAttempts = count(),\ndisabledAccountsTargeted = dcount(UserPrincipalName), applicationsTargeted = dcount(AppDisplayName), disabledAccountSet = make_set(UserPrincipalName),\napplicationSet = make_set(AppDisplayName) by IPAddress, Type\n| order by disabledAccountLoginAttempts desc\n| join kind= leftouter (\n    // Consider these IPs suspicious - and alert any related  successful sign-ins\n    table(tableName)\n    | where ResultType == 0\n    | summarize successfulAccountSigninCount = dcount(UserPrincipalName), successfulAccountSigninSet = make_set(UserPrincipalName, 15) by IPAddress, Type\n    // Assume IPs associated with sign-ins from 100+ distinct user accounts are safe\n    | where successfulAccountSigninCount < 100\n) on IPAddress\n// IPs from which attempts to authenticate as disabled user accounts originated, and had a non-zero success rate for some other account\n| where isnotempty(successfulAccountSigninCount)\n| project StartTime, EndTime, IPAddress, disabledAccountLoginAttempts, disabledAccountsTargeted, disabledAccountSet, applicationSet,\nsuccessfulAccountSigninCount, successfulAccountSigninSet, Type\n| order by disabledAccountLoginAttempts\n| extend timestamp = StartTime, IPCustomEntity = IPAddress\n};\nlet aadSignin = aadFunc(\"SigninLogs\");\nlet aadNonInt = aadFunc(\"AADNonInteractiveUserSignInLogs\");\nunion isfuzzy=true aadSignin, aadNonInt",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "InitialAccess",
                    "Persistence"
                ],
                "techniques": [
                    "T1078",
                    "T1098"
                ],
                "alertRuleTemplateName": "500c103a-0319-4d56-8e99-3cec8d860757",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.1.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/7f672a64-7413-492d-9e1a-d1f58b265b1e')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/7f672a64-7413-492d-9e1a-d1f58b265b1e')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "User State changed from Guest to Member",
                "description": "Detects when a guest account in a tenant is converted to a member of the tenant.\n  Monitoring guest accounts and the access they are provided is important to detect potential account abuse.\n  Accounts converted to members should be investigated to ensure the activity was legitimate.\n  Ref: https://docs.microsoft.com/azure/active-directory/fundamentals/security-operations-user-accounts#monitoring-for-failed-unusual-sign-ins",
                "severity": "Medium",
                "enabled": true,
                "query": "AuditLogs\n  | where OperationName =~ \"Update user\"\n  | where Result =~ \"success\"\n  | mv-expand TargetResources\n  | mv-expand TargetResources.modifiedProperties\n  | where TargetResources_modifiedProperties.displayName =~ \"TargetId.UserType\"\n  | extend UpdatingServicePrincipal = tostring(parse_json(tostring(InitiatedBy.app)).servicePrincipalId)\n  | extend UpdatingUserPrincipal = tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName)\n  | extend UpdatingUser = iif(isnotempty(UpdatingServicePrincipal), UpdatingServicePrincipal, UpdatingUserPrincipal)\n  | extend UpdatedUserPrincipalName = tostring(TargetResources.userPrincipalName)\n  | project-reorder TimeGenerated, UpdatedUserPrincipalName, UpdatingUser\n  | where parse_json(tostring(TargetResources_modifiedProperties.newValue)) =~ \"\\\"Member\\\"\" and parse_json(tostring(TargetResources_modifiedProperties.oldValue)) =~ \"\\\"Guest\\\"\"",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "a09a0b8e-30fe-4ebf-94a0-cffe50f579cd",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "UpdatingUser"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "UpdatedUserPrincipalName"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/e5b416a1-0fa1-4031-8ffa-ea514b6ab36f')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/e5b416a1-0fa1-4031-8ffa-ea514b6ab36f')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Rare and potentially high-risk Office operations",
                "description": "Identifies Office operations that are typically rare and can provide capabilities useful to attackers.",
                "severity": "Low",
                "enabled": true,
                "query": "OfficeActivity\n| where Operation in~ ( \"Add-MailboxPermission\", \"Add-MailboxFolderPermission\", \"Set-Mailbox\", \"New-ManagementRoleAssignment\", \"New-InboxRule\", \"Set-InboxRule\", \"Set-TransportRule\")\nand not(UserId has_any ('NT AUTHORITY\\\\SYSTEM (Microsoft.Exchange.ServiceHost)', 'NT AUTHORITY\\\\SYSTEM (w3wp)', 'devilfish-applicationaccount') and Operation in~ ( \"Add-MailboxPermission\", \"Set-Mailbox\"))\n| extend ClientIPOnly = tostring(extract_all(@'\\[?(::ffff:)?(?P<IPAddress>(\\d+\\.\\d+\\.\\d+\\.\\d+)|[^\\]]+)\\]?', dynamic([\"IPAddress\"]), ClientIP)[0][0])\n| extend timestamp = TimeGenerated, AccountCustomEntity = UserId, IPCustomEntity = ClientIPOnly",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "Collection"
                ],
                "techniques": [
                    "T1098",
                    "T1114"
                ],
                "alertRuleTemplateName": "957cb240-f45d-4491-9ba5-93430a3c08be",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "2.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/318f6b21-7810-4145-842b-f210043fd3ad')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/318f6b21-7810-4145-842b-f210043fd3ad')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Admin promotion after Role Management Application Permission Grant",
                "description": "This rule looks for a service principal being granted the Microsoft Graph RoleManagement.ReadWrite.Directory (application) permission before being used to add an Azure AD object or user account to an Admin directory role (i.e. Global Administrators).\nThis is a known attack path that is usually abused when a service principal already has the AppRoleAssignment.ReadWrite.All permission granted. This permission Allows an app to manage permission grants for application permissions to any API.\nA service principal can promote itself or other service principals to admin roles (i.e. Global Administrators). This would be considered a privilege escalation technique.\nRef : https://docs.microsoft.com/graph/permissions-reference#role-management-permissions, https://docs.microsoft.com/graph/api/directoryrole-post-members?view=graph-rest-1.0&tabs=http",
                "severity": "High",
                "enabled": true,
                "query": "AuditLogs\n| where LoggedByService =~ \"Core Directory\"\n| where Category =~ \"ApplicationManagement\"\n| where AADOperationType =~ \"Assign\"\n| where ActivityDisplayName =~ \"Add app role assignment to service principal\"\n| mv-expand TargetResources\n| mv-expand TargetResources.modifiedProperties\n| extend displayName_ = tostring(TargetResources_modifiedProperties.displayName)\n| where displayName_ =~ \"AppRole.Value\"\n| extend AppRole = tostring(parse_json(tostring(TargetResources_modifiedProperties.newValue)))\n| where AppRole has \"RoleManagement.ReadWrite.Directory\"\n| extend InitiatingApp = tostring(parse_json(tostring(InitiatedBy.app)).displayName)\n| extend Initiator = iif(isnotempty(InitiatingApp), InitiatingApp, tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName))\n| extend Target = tostring(parse_json(tostring(TargetResources.modifiedProperties[4].newValue)))\n| extend TargetId = tostring(parse_json(tostring(TargetResources.modifiedProperties[3].newValue)))\n| project TimeGenerated, OperationName, Initiator, Target, TargetId, Result\n| join kind=innerunique (\n  AuditLogs\n  | where LoggedByService =~ \"Core Directory\"\n  | where Category =~ \"RoleManagement\"\n  | where AADOperationType in (\"Assign\", \"AssignEligibleRole\")\n  | where ActivityDisplayName has_any (\"Add eligible member to role\", \"Add member to role\")\n  | mv-expand TargetResources\n  | mv-expand TargetResources.modifiedProperties\n  | extend displayName_ = tostring(TargetResources_modifiedProperties.displayName)\n  | where displayName_ =~ \"Role.DisplayName\"\n  | extend RoleName = tostring(parse_json(tostring(TargetResources_modifiedProperties.newValue)))\n  | where RoleName contains \"Admin\"\n  | extend Initiator = tostring(parse_json(tostring(InitiatedBy.app)).displayName)\n  | extend InitiatorId = tostring(parse_json(tostring(InitiatedBy.app)).servicePrincipalId)\n  | extend TargetUser = tostring(TargetResources.userPrincipalName)\n  | extend Target = iif(isnotempty(TargetUser), TargetUser, tostring(TargetResources.displayName))\n  | extend TargetType = tostring(TargetResources.type)\n  | extend TargetId = tostring(TargetResources.id)\n  | project TimeGenerated, OperationName,  RoleName, Initiator, InitiatorId, Target, TargetId, TargetType, Result\n) on $left.TargetId == $right.InitiatorId\n| extend TimeRoleMgGrant = TimeGenerated, TimeAdminPromo = TimeGenerated1, ServicePrincipal = Initiator1, ServicePrincipalId = InitiatorId,\n  TargetObject = Target1, TargetObjectId = TargetId1, TargetObjectType = TargetType\n| where TimeRoleMgGrant < TimeAdminPromo\n| project TimeRoleMgGrant, TimeAdminPromo, RoleName, ServicePrincipal, ServicePrincipalId, TargetObject, TargetObjectId, TargetObjectType",
                "queryFrequency": "PT2H",
                "queryPeriod": "PT2H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "PrivilegeEscalation",
                    "Persistence"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "f80d951a-eddc-4171-b9d0-d616bb83efdc",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "ServicePrincipal"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "TargetObject"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/eeab2178-e234-4595-b145-e987a8155aa0')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/eeab2178-e234-4595-b145-e987a8155aa0')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Rare subscription-level operations in Azure",
                "description": "This query looks for a few sensitive subscription-level events based on Azure Activity Logs.\n For example this monitors for the operation name 'Create or Update Snapshot' which is used for creating backups but could be misused by attackers\n to dump hashes or extract sensitive information from the disk.",
                "severity": "Low",
                "enabled": true,
                "query": "let starttime = 14d;\nlet endtime = 1d;\n// The number of operations below which an IP address is considered an unusual source of role assignment operations\nlet alertOperationThreshold = 5;\nlet SensitiveOperationList =  dynamic([\"microsoft.compute/snapshots/write\", \"microsoft.network/networksecuritygroups/write\", \"microsoft.storage/storageaccounts/listkeys/action\"]);\nlet SensitiveActivity = AzureActivity\n| where OperationNameValue in~ (SensitiveOperationList) or OperationNameValue hassuffix \"listkeys/action\"\n| where ActivityStatusValue =~ \"Success\";\nSensitiveActivity\n| where TimeGenerated between (ago(starttime) .. ago(endtime))\n| summarize count() by CallerIpAddress, Caller, OperationNameValue\n| where count_ >= alertOperationThreshold\n| join kind = rightanti (\nSensitiveActivity\n| where TimeGenerated >= ago(endtime)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = makelist(TimeGenerated), ActivityStatusValue = makelist(ActivityStatusValue),\nOperationIds = makelist(OperationId), CorrelationIds = makelist(CorrelationId), Resources = makelist(Resource), ResourceGroups = makelist(ResourceGroup), ResourceIds = makelist(ResourceId), ActivityCountByCallerIPAddress = count()\nby CallerIpAddress, Caller, OperationNameValue\n) on CallerIpAddress, Caller, OperationNameValue\n| extend timestamp = StartTimeUtc, AccountCustomEntity = Caller, IPCustomEntity = CallerIpAddress",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "CredentialAccess",
                    "Persistence"
                ],
                "techniques": [
                    "T1003",
                    "T1098"
                ],
                "alertRuleTemplateName": "23de46ea-c425-4a77-b456-511ae4855d69",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "2.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/5cd926dd-32e5-4f21-a053-c5e4aadd1a3e')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/5cd926dd-32e5-4f21-a053-c5e4aadd1a3e')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Attempt to bypass conditional access rule in Azure AD",
                "description": "Identifies an attempt to Bypass conditional access rule(s) in Azure Active Directory.\nThe ConditionalAccessStatus column value details if there was an attempt to bypass Conditional Access\nor if the Conditional access rule was not satisfied (ConditionalAccessStatus == 1).\nReferences:\nhttps://docs.microsoft.com/azure/active-directory/conditional-access/overview\nhttps://docs.microsoft.com/azure/active-directory/reports-monitoring/concept-sign-ins\nhttps://docs.microsoft.com/azure/active-directory/reports-monitoring/reference-sign-ins-error-codes\nConditionalAccessStatus == 0 // Success\nConditionalAccessStatus == 1 // Failure\nConditionalAccessStatus == 2 // Not Applied\nConditionalAccessStatus == 3 // unknown",
                "severity": "Low",
                "enabled": true,
                "query": "let threshold = 1;\nlet aadFunc = (tableName:string){\ntable(tableName)\n| where ConditionalAccessStatus == 1 or ConditionalAccessStatus =~ \"failure\"\n| extend CAP = parse_json(ConditionalAccessPolicies)\n| mv-apply CAP on (\n  project ConditionalAccessPoliciesName = CAP.displayName, result = CAP.result\n  | where result =~ \"failure\"\n)\n| extend DeviceDetail = todynamic(DeviceDetail), Status = todynamic(Status), LocationDetails = todynamic(LocationDetails)\n| extend OS = DeviceDetail.operatingSystem, Browser = DeviceDetail.browser\n| extend State = tostring(LocationDetails.state), City = tostring(LocationDetails.city), Region = tostring(LocationDetails.countryOrRegion)\n| extend StatusCode = tostring(Status.errorCode), StatusDetails = tostring(Status.additionalDetails)\n| extend Status = strcat(StatusCode, \": \", ResultDescription)\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), Status = make_list(Status), StatusDetails = make_list(StatusDetails), IPAddresses = make_list(IPAddress), IPAddressCount = dcount(IPAddress), CorrelationIds = make_list(CorrelationId), ConditionalAccessPoliciesName = make_list(ConditionalAccessPoliciesName)\nby UserPrincipalName, AppDisplayName, tostring(Browser), tostring(OS), City, State, Region, Type\n| where IPAddressCount > threshold and StatusDetails !has \"MFA successfully completed\"\n| mvexpand IPAddresses, Status, StatusDetails, CorrelationIds\n| extend Status = strcat(Status, \" \", StatusDetails)\n| summarize IPAddresses = make_set(IPAddresses), Status = make_set(Status), CorrelationIds = make_set(CorrelationIds), ConditionalAccessPoliciesName = make_set(ConditionalAccessPoliciesName)\nby StartTime, EndTime, UserPrincipalName, AppDisplayName, tostring(Browser), tostring(OS), City, State, Region, IPAddressCount, Type\n| extend timestamp = StartTime, AccountCustomEntity = UserPrincipalName, IPCustomEntity = tostring(IPAddresses)\n};\nlet aadSignin = aadFunc(\"SigninLogs\");\nlet aadNonInt = aadFunc(\"AADNonInteractiveUserSignInLogs\");\nunion isfuzzy=true aadSignin, aadNonInt",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "InitialAccess",
                    "Persistence"
                ],
                "techniques": [
                    "T1078",
                    "T1098"
                ],
                "alertRuleTemplateName": "3af9285d-bb98-4a35-ad29-5ea39ba0c628",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/a32f5ab8-71a9-4852-979c-03fd95812f1e')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/a32f5ab8-71a9-4852-979c-03fd95812f1e')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "NRT",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "NRT User added to Azure Active Directory Privileged Groups",
                "description": "This will alert when a user is added to any of the Privileged Groups.\nFor further information on AuditLogs please see https://docs.microsoft.com/azure/active-directory/reports-monitoring/reference-audit-activities.\nFor Administrator role permissions in Azure Active Directory please see https://docs.microsoft.com/azure/active-directory/users-groups-roles/directory-assign-admin-roles",
                "severity": "Medium",
                "enabled": true,
                "query": "let OperationList = dynamic([\"Add member to role\",\"Add member to role in PIM requested (permanent)\"]);\nlet PrivilegedGroups = dynamic([\"UserAccountAdmins\",\"PrivilegedRoleAdmins\",\"TenantAdmins\"]);\nAuditLogs\n//| where LoggedByService =~ \"Core Directory\"\n| where Category =~ \"RoleManagement\"\n| where OperationName in~ (OperationList)\n| mv-expand TargetResources\n| extend modProps = parse_json(TargetResources).modifiedProperties\n| mv-expand bagexpansion=array modProps\n| evaluate bag_unpack(modProps)\n| extend displayName = column_ifexists(\"displayName\", \"NotAvailable\"), newValue = column_ifexists(\"newValue\", \"NotAvailable\")\n| where displayName =~ \"Role.WellKnownObjectName\"\n| extend DisplayName = displayName, GroupName = replace('\"','',newValue)\n| extend initByApp = parse_json(InitiatedBy).app, initByUser = parse_json(InitiatedBy).user\n| extend AppId = initByApp.appId,\nInitiatedByDisplayName = case(isnotempty(initByApp.displayName), initByApp.displayName, isnotempty(initByUser.displayName), initByUser.displayName, \"not available\"),\nServicePrincipalId = tostring(initByApp.servicePrincipalId),\nServicePrincipalName = tostring(initByApp.servicePrincipalName),\nUserId = initByUser.id,\nUserIPAddress = initByUser.ipAddress,\nUserRoles = initByUser.roles,\nUserPrincipalName = tostring(initByUser.userPrincipalName),\nTargetUserPrincipalName = tostring(TargetResources.userPrincipalName)\n| where GroupName in~ (PrivilegedGroups)\n// If you don't want to alert for operations from PIM, remove below filtering for MS-PIM.\n//| where InitiatedByDisplayName != \"MS-PIM\"\n| project TimeGenerated, AADOperationType, Category, OperationName, AADTenantId, AppId, InitiatedByDisplayName, ServicePrincipalId, ServicePrincipalName, DisplayName, GroupName, UserId, UserIPAddress, UserRoles, UserPrincipalName, TargetUserPrincipalName\n| extend AccountCustomEntity = case(isnotempty(ServicePrincipalName), ServicePrincipalName, isnotempty(ServicePrincipalId), ServicePrincipalId, isnotempty(UserPrincipalName), UserPrincipalName, \"not available\")",
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "70fc7201-f28e-4ba7-b9ea-c04b96701f13",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "TargetUserPrincipalName"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/a083f201-bf06-4149-8a96-5b588c5c9b7f')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/a083f201-bf06-4149-8a96-5b588c5c9b7f')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "New External User Granted Admin",
                "description": "This query will detect instances where a newly invited external user is granted an administrative role. By default this query\nwill alert on any granted administrative role, however this can be modified using the roles variable if false positives occur\nin your environment. The maximum delta between invite and escalation to admin is 60 minues, this can be configured using the \ndeltaBetweenInviteEscalation variable.",
                "severity": "Medium",
                "enabled": true,
                "query": "// Administrative roles to look for, default is all admin roles\nlet roles = dynamic([\"Administrator\", \"Admin\"]);\n// The maximum distances between and invite and acceptance\nlet maxTimeBetweenInviteAccept = 30min;\n// The delta (minutes) between the invite being sent and the account being escalated\nlet deltaBetweenInviteEscalation = 60;\n// Collect external user invitations\nlet invite = AuditLogs\n| where Category =~ \"UserManagement\"\n| where OperationName =~ \"Invite external user\"\n| extend Target = tostring(TargetResources[0].[\"userPrincipalName\"])\n| extend InviteInitiator = tostring(InitiatedBy.[\"user\"].[\"userPrincipalName\"])\n| where isnotempty(InviteInitiator);\n// Collect redeem events\nlet redeem = AuditLogs\n| where Category =~ \"UserManagement\"\n| where OperationName =~ \"Redeem external user invite\"\n| where Result =~ \"success\"\n| extend Target = tostring(TargetResources[0].[\"displayName\"]) | extend Target = tostring(extract(@\"UPN\\:\\s(.+)\\,\\sEmail\",1,Target))\n| where isnotempty(Target);\n// Union the inivtation and redeem data then run the sequence_detect kusto plugin\ninvite\n| union redeem\n| order by TimeGenerated\n| project TimeGenerated, Target, InviteInitiator, OperationName, TenantId\n| evaluate sequence_detect(TimeGenerated, maxTimeBetweenInviteAccept, maxTimeBetweenInviteAccept, invite=(OperationName has \"Invite external user\"), redeem=(OperationName has \"Redeem external user invite\"), Target)\n| join (\nAuditLogs\n| where Category =~ \"RoleManagement\"\n| where AADOperationType in (\"Assign\", \"AssignEligibleRole\")\n| where ActivityDisplayName has_any (\"Add eligible member to role\", \"Add member to role\")\n| mv-expand TargetResources\n// Limit to external accounts\n| where TargetResources.userPrincipalName has \"EXT\"\n| mv-expand TargetResources.modifiedProperties\n| extend displayName_ = tostring(TargetResources_modifiedProperties.displayName)\n| where displayName_ =~ \"Role.DisplayName\"\n| extend RoleName = tostring(parse_json(tostring(TargetResources_modifiedProperties.newValue)))\n// Perform check for admin roles\n| where RoleName has_any(roles)\n| extend InitiatingApp = tostring(parse_json(tostring(InitiatedBy.app)).displayName)\n| extend Initiator = iif(isnotempty(InitiatingApp), InitiatingApp, tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName))\n| where Initiator != \"MS-PIM\"\n| extend Target = tostring(TargetResources.userPrincipalName)\n| summarize by TimeGenerated, OperationName,  RoleName, Target, Initiator, Result\n) on Target\n// Calculate delta between the invite and the account escalation\n| extend delta = datetime_diff(\"minute\", TimeGenerated, invite_TimeGenerated)\n| where delta <= deltaBetweenInviteEscalation\n| project InvitationTime=invite_TimeGenerated, RedeemTime=redeem_TimeGenerated, GrantTime=TimeGenerated, ExternalUser=Target, RoleGranted=RoleName, AdminInitiator=Initiator, MinsBetweenInviteAndEscalation=delta",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "d7424fd9-abb3-4ded-a723-eebe023aaa0b",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "ExternalUser"
                            }
                        ]
                    },
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AdminInitiator"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/25fc7071-4cdf-45e0-b216-7beabbbea2b4')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/25fc7071-4cdf-45e0-b216-7beabbbea2b4')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Suspicious granting of permissions to an account",
                "description": "Identifies IPs from which users grant access to other users on azure resources and alerts when a previously unseen source IP address is used.",
                "severity": "Medium",
                "enabled": true,
                "query": "let starttime = 14d;\nlet endtime = 1d;\n// The number of operations below which an IP address is considered an unusual source of role assignment operations\nlet alertOperationThreshold = 5;\nlet AzureBuiltInRole = externaldata(Role:string,RoleDescription:string,ID:string) [@\"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/AzureBuiltInRole.csv\"] with (format=\"csv\", ignoreFirstRecord=True);\nlet createRoleAssignmentActivity = AzureActivity\n| where OperationNameValue =~ \"microsoft.authorization/roleassignments/write\";\nlet RoleAssignedActivity = createRoleAssignmentActivity \n| where TimeGenerated between (ago(starttime) .. ago(endtime))\n| summarize count() by CallerIpAddress, Caller\n| where count_ >= alertOperationThreshold\n| join kind = rightanti ( \ncreateRoleAssignmentActivity\n| where TimeGenerated > ago(endtime)\n| extend PrincipalId = tostring(parse_json(tostring(parse_json(tostring(Properties_d.requestbody)).Properties)).PrincipalId)\n| extend PrincipalType = tostring(parse_json(tostring(parse_json(tostring(Properties_d.requestbody)).Properties)).PrincipalType)\n| extend Scope = tostring(parse_json(tostring(parse_json(tostring(Properties_d.requestbody)).Properties)).Scope)\n| extend RoleAddedDetails = tostring(parse_json(tostring(parse_json(tostring(parse_json(Properties).requestbody)).Properties)).RoleDefinitionId) \n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = make_set(TimeGenerated), ActivityStatusValue = make_set(ActivityStatusValue), \nOperationIds = make_set(OperationId), CorrelationId = make_set(CorrelationId), ActivityCountByCallerIPAddress = count()  \nby ResourceId, CallerIpAddress, Caller, OperationNameValue, Resource, ResourceGroup, PrincipalId, PrincipalType, Scope, RoleAddedDetails\n) on CallerIpAddress, Caller\n| extend timestamp = StartTimeUtc, AccountCustomEntity = Caller, IPCustomEntity = CallerIpAddress;\nlet RoleAssignedActivitywithRoleDetails = RoleAssignedActivity\n| extend RoleAssignedID = tostring(split(RoleAddedDetails, \"/\")[-1])\n| join kind = inner (AzureBuiltInRole \n) on $left.RoleAssignedID == $right.ID;\nRoleAssignedActivitywithRoleDetails\n| summarize arg_max(StartTimeUtc, *) by PrincipalId, RoleAssignedID\n| join kind = leftouter( IdentityInfo\n| summarize arg_max(TimeGenerated, *) by AccountObjectId\n) on $left.PrincipalId == $right.AccountObjectId\n| project ActivityTimeStamp, OperationNameValue, Caller, CallerIpAddress, PrincipalId, RoleAssignedID, RoleAddedDetails, Role, RoleDescription, AccountUPN, AccountCreationTime, GroupMembership, UserType, ActivityStatusValue, \nResourceGroup, PrincipalType, Scope, CorrelationId, timestamp, AccountCustomEntity, IPCustomEntity",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1548"
                ],
                "alertRuleTemplateName": "b2c15736-b9eb-4dae-8b02-3016b6a45a32",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "2.0.0"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/6c335a69-3e7f-4383-ba35-ed74eb0b7fa6')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/6c335a69-3e7f-4383-ba35-ed74eb0b7fa6')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "User account added to built in domain local or global group",
                "description": "Identifies when a user account has been added to a privileged built in domain local group or global group\nsuch as the Enterprise Admins, Cert Publishers or DnsAdmins. Be sure to verify this is an expected addition.",
                "severity": "Low",
                "enabled": true,
                "query": "// For AD SID mappings - https://docs.microsoft.com/windows/security/identity-protection/access-control/active-directory-security-groups\nlet WellKnownLocalSID = \"S-1-5-32-5[0-9][0-9]$\";\nlet WellKnownGroupSID = \"S-1-5-21-[0-9]*-[0-9]*-[0-9]*-5[0-9][0-9]$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1102$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1103$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-498$|S-1-5-21-[0-9]*-[0-9]*-[0-9]*-1000$\";\nunion isfuzzy=true\n(\nSecurityEvent\n// 4728 - A member was added to a security-enabled global group\n// 4732 - A member was added to a security-enabled local group\n// 4756 - A member was added to a security-enabled universal group\n| where EventID in (4728, 4732, 4756)\n| where AccountType == \"User\"\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n// Exclude Remote Desktop Users group: S-1-5-32-555\n| where TargetSid !in (\"S-1-5-32-555\")\n| extend SimpleMemberName = substring(MemberName, 3, indexof_regex(MemberName, @\",OU|,CN\") - 3)\n| project TimeGenerated, EventID, Activity, Computer, SimpleMemberName, MemberName, MemberSid, TargetUserName, TargetDomainName, TargetSid, UserPrincipalName, SubjectUserName, SubjectUserSid\n),\n(\nWindowsEvent\n// 4728 - A member was added to a security-enabled global group\n// 4732 - A member was added to a security-enabled local group\n// 4756 - A member was added to a security-enabled universal group\n| where EventID in (4728, 4732, 4756) and not(EventData has \"S-1-5-32-555\")\n| extend SubjectUserSid = tostring(EventData.SubjectUserSid)\n| extend Account =  strcat(tostring(EventData.SubjectDomainName),\"\\\\\", tostring(EventData.SubjectUserName))\n| extend AccountType=case(Account endswith \"$\" or SubjectUserSid in (\"S-1-5-18\", \"S-1-5-19\", \"S-1-5-20\"), \"Machine\", isempty(SubjectUserSid), \"\", \"User\")\n| extend MemberName = tostring(EventData.MemberName)\n| where AccountType == \"User\"\n| extend TargetSid = tostring(EventData.TargetSid)\n| where TargetSid matches regex WellKnownLocalSID or TargetSid matches regex WellKnownGroupSID\n// Exclude Remote Desktop Users group: S-1-5-32-555\n| where TargetSid !in (\"S-1-5-32-555\")\n| extend SimpleMemberName = substring(MemberName, 3, indexof_regex(MemberName, @\",OU|,CN\") - 3)\n| extend MemberSid = tostring(EventData.MemberSid)\n| extend TargetUserName = tostring(EventData.TargetUserName)\n| extend TargetDomainName = tostring(EventData.TargetDomainName)\n| extend UserPrincipalName = tostring(EventData.UserPrincipalName)\n| extend SubjectUserName = tostring(EventData.SubjectUserName)\n| project TimeGenerated, EventID, Computer, SimpleMemberName, MemberName, MemberSid, TargetUserName, TargetDomainName, TargetSid, UserPrincipalName, SubjectUserName, SubjectUserSid\n)",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "a35f2c18-1b97-458f-ad26-e033af18eb99",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "SimpleMemberName"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.3.5"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/9789735c-dfc3-4eaa-bac3-2e07827e823e')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/9789735c-dfc3-4eaa-bac3-2e07827e823e')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Detect PIM Alert Disabling activity",
                "description": "Privileged Identity Management (PIM) generates alerts when there is suspicious or unsafe activity in Azure Active Directory (Azure AD) organization. \nThis query will help detect attackers attempts to disable in product PIM alerts which are associated with Azure MFA requirements and could indicate activation of privileged access",
                "severity": "Medium",
                "enabled": true,
                "query": "AuditLogs\n| where LoggedByService =~ \"PIM\"\n| where Category =~ \"RoleManagement\"\n| where ActivityDisplayName has \"Disable PIM Alert\"\n| extend IpAddress = case(\n  isnotempty(tostring(parse_json(tostring(InitiatedBy.user)).ipAddress)) and tostring(parse_json(tostring(InitiatedBy.user)).ipAddress) != 'null', tostring(parse_json(tostring(InitiatedBy.user)).ipAddress), \n  isnotempty(tostring(parse_json(tostring(InitiatedBy.app)).ipAddress)) and tostring(parse_json(tostring(InitiatedBy.app)).ipAddress) != 'null', tostring(parse_json(tostring(InitiatedBy.app)).ipAddress),\n  'Not Available')\n| extend InitiatedBy = iff(isnotempty(tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName)), \n  tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName), tostring(parse_json(tostring(InitiatedBy.app)).displayName)), UserRoles = tostring(parse_json(tostring(InitiatedBy.user)).ipAddress)\n| project InitiatedBy, ActivityDateTime, ActivityDisplayName, IpAddress, AADOperationType, AADTenantId, ResourceId, CorrelationId, Identity\n| extend timestamp = ActivityDateTime, IPCustomEntity = IpAddress, AccountCustomEntity = tolower(InitiatedBy), ResourceCustomEntity = ResourceId",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence",
                    "PrivilegeEscalation"
                ],
                "techniques": [
                    "T1098",
                    "T1078"
                ],
                "alertRuleTemplateName": "1f3b4dfd-21ff-4ed3-8e27-afc219e05c50",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "AzureResource",
                        "fieldMappings": [
                            {
                                "identifier": "ResourceId",
                                "columnName": "ResourceCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/25549daa-8208-4969-a71c-62a6d8189400')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/25549daa-8208-4969-a71c-62a6d8189400')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AD user enabled and password not set within 48 hours",
                "description": "Identifies when an account is enabled with a default password and the password is not set by the user within 48 hours.\nEffectively, there is an event 4722 indicating an account was enabled and within 48 hours, no event 4723 occurs which\nindicates there was no attempt by the user to set the password. This will show any attempts (success or fail) that occur\nafter 48 hours, which can indicate too long of a time period in setting the password to something that only the user knows.\nIt is recommended that this time period is adjusted per your internal company policy.",
                "severity": "Low",
                "enabled": true,
                "query": "let starttime = 3d;\nlet SecEvents = materialize ( SecurityEvent | where TimeGenerated >= ago(starttime)\n| where EventID in (4722,4723) | where TargetUserName !endswith \"$\"\n| project TimeGenerated, EventID, Activity, Computer, TargetAccount, TargetSid, SubjectAccount, SubjectUserSid);\nlet userEnable = SecEvents\n| extend EventID4722Time = TimeGenerated\n// 4722: User Account Enabled\n| where EventID == 4722\n| project Time_Event4722 = TimeGenerated, TargetAccount, TargetSid, SubjectAccount_Event4722 = SubjectAccount, SubjectUserSid_Event4722 = SubjectUserSid, Activity_4722 = Activity, Computer_4722 = Computer;\nlet userPwdSet = SecEvents\n// 4723: Attempt made by user to set password\n| where EventID == 4723\n| project Time_Event4723 = TimeGenerated, TargetAccount, TargetSid, SubjectAccount_Event4723 = SubjectAccount, SubjectUserSid_Event4723 = SubjectUserSid, Activity_4723 = Activity, Computer_4723 = Computer;\nuserEnable | join kind=leftouter userPwdSet on TargetAccount, TargetSid\n| extend PasswordSetAttemptDelta_Min = datetime_diff('minute', Time_Event4723, Time_Event4722)\n| where PasswordSetAttemptDelta_Min > 2880 or isempty(PasswordSetAttemptDelta_Min)\n| project-away TargetAccount1, TargetSid1\n| extend Reason = @\"User either has not yet attempted to set the initial password after account was enabled or it occurred after 48 hours\"\n| order by Time_Event4722 asc\n| extend timestamp = Time_Event4722, AccountCustomEntity = TargetAccount, HostCustomEntity = Computer_4722\n| project-reorder Time_Event4722, Time_Event4723, PasswordSetAttemptDelta_Min, TargetAccount, TargetSid",
                "queryFrequency": "P1D",
                "queryPeriod": "P3D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "62085097-d113-459f-9ea7-30216f2ee6af",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            },
                            {
                                "identifier": "Sid",
                                "columnName": "TargetSid"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/9b2266de-b262-4f8d-bb60-4728581352fe')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/9b2266de-b262-4f8d-bb60-4728581352fe')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "MFA disabled for a user",
                "description": "Multi-Factor Authentication (MFA) helps prevent credential compromise. This alert identifies when an attempt has been made to disable MFA for a user ",
                "severity": "Medium",
                "enabled": true,
                "query": "(union isfuzzy=true\n(AuditLogs\n| where OperationName =~ \"Disable Strong Authentication\"\n| extend IPAddress = tostring(parse_json(tostring(InitiatedBy.user)).ipAddress)\n| extend InitiatedByUser = iff(isnotempty(tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName)),\n tostring(parse_json(tostring(InitiatedBy.user)).userPrincipalName), tostring(parse_json(tostring(InitiatedBy.app)).displayName))\n| extend Targetprop = todynamic(TargetResources)\n| extend TargetUser = tostring(Targetprop[0].userPrincipalName)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by User = TargetUser, InitiatedByUser , Operation = OperationName , CorrelationId, IPAddress, Category, Source = SourceSystem , AADTenantId, Type\n),\n(AWSCloudTrail\n| where EventName in~ (\"DeactivateMFADevice\", \"DeleteVirtualMFADevice\")\n| extend InstanceProfileName = tostring(parse_json(RequestParameters).InstanceProfileName)\n| extend TargetUser = tostring(parse_json(RequestParameters).userName)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by User = TargetUser, Source = EventSource , Operation = EventName , TenantorInstance_Detail = InstanceProfileName, IPAddress = SourceIpAddress\n)\n)\n| extend timestamp = StartTimeUtc, AccountCustomEntity = User, IPCustomEntity = IPAddress",
                "queryFrequency": "PT1H",
                "queryPeriod": "PT1H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "CredentialAccess",
                    "Persistence"
                ],
                "techniques": [
                    "T1098",
                    "T1556"
                ],
                "alertRuleTemplateName": "65c78944-930b-4cae-bd79-c3664ae30ba7",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/2103e846-0b62-4fcf-84b3-547469f9fe51')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/2103e846-0b62-4fcf-84b3-547469f9fe51')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "DSRM Account Abuse",
                "description": "This query detects an abuse of the DSRM account in order to maintain persistence and access to the organization's Active Directory.\nRef: https://adsecurity.org/?p=1785",
                "severity": "High",
                "enabled": true,
                "query": "Event\n| where EventLog == \"Microsoft-Windows-Sysmon/Operational\" and EventID in (13)\n| parse EventData with * 'TargetObject\">' TargetObject \"<\" * 'Details\">' Details \"<\" * \n| where TargetObject has (\"HKLM\\\\System\\\\CurrentControlSet\\\\Control\\\\Lsa\\\\DsrmAdminLogonBehavior\") and Details == \"DWORD (0x00000002)\"\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by EventID, Computer,  TargetObject, Details",
                "queryFrequency": "PT1H",
                "queryPeriod": "PT1H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Persistence"
                ],
                "techniques": [
                    "T1098"
                ],
                "alertRuleTemplateName": "979c42dd-533e-4ede-b18b-31a84ba8b3d6",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "RegistryKey",
                        "fieldMappings": [
                            {
                                "identifier": "Key",
                                "columnName": "TargetObject"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/7a430355-b5fc-49f9-abc0-2267bdaccae6')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/7a430355-b5fc-49f9-abc0-2267bdaccae6')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Identify MERCURY powershell commands",
                "description": "The query below identifies powershell commands used by the threat actor Mercury.\nReference:  https://www.microsoft.com/security/blog/2022/08/25/mercury-leveraging-log4j-2-vulnerabilities-in-unpatched-systems-to-target-israeli-organizations/",
                "severity": "High",
                "enabled": true,
                "query": "(union isfuzzy=true\n(SecurityEvent\n| where EventID == 4688\n| where Process has_any (\"powershell.exe\",\"powershell_ise.exe\",\"pwsh.exe\") and CommandLine has_cs \"-exec bypass -w 1 -enc\"\n| where CommandLine  contains_cs \"UwB0AGEAcgB0AC0ASgBvAGIAIAAtAFMAYwByAGkAcAB0AEIAbABvAGMAawAgAHsAKABzAGEAcABzACAAKAAiAHAA\"\n| extend timestamp = TimeGenerated, AccountCustomEntity = Account, HostCustomEntity = Computer, ProcessCustomEntity = Process\n),\n(DeviceProcessEvents\n| where FileName =~ \"powershell.exe\" and ProcessCommandLine has_cs \"-exec bypass -w 1 -enc\"  \n| where ProcessCommandLine contains_cs \"UwB0AGEAcgB0AC0ASgBvAGIAIAAtAFMAYwByAGkAcAB0AEIAbABvAGMAawAgAHsAKABzAGEAcABzACAAKAAiAHAA\" \n| extend timestamp = TimeGenerated, AccountCustomEntity = AccountName, HostCustomEntity = DeviceName, ProcessCustomEntity = InitiatingProcessFileName\n),\n(imProcessCreate\n| where Process has_any (\"powershell.exe\",\"powershell_ise.exe\",\"pwsh.exe\") and CommandLine has_cs \"-exec bypass -w 1 -enc\"\n| where CommandLine  contains_cs \"UwB0AGEAcgB0AC0ASgBvAGIAIAAtAFMAYwByAGkAcAB0AEIAbABvAGMAawAgAHsAKABzAGEAcABzACAAKAAiAHAA\"\n| extend timestamp = TimeGenerated, AccountCustomEntity = ActorUsername, HostCustomEntity = DvcHostname, ProcessCustomEntity = Process\n)\n)",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "LateralMovement"
                ],
                "techniques": [
                    "T1570"
                ],
                "alertRuleTemplateName": "ce74dc9a-cb3c-4081-8c2f-7d39f6b7bae1",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "ProcessId",
                                "columnName": "ProcessCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/1ccfc482-cf5e-483f-a328-d12d93110b9a')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/1ccfc482-cf5e-483f-a328-d12d93110b9a')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "New EXE deployed via Default Domain or Default Domain Controller Policies (ASIM Version)",
                "description": "This detection highlights executables deployed to hosts via either the Default Domain or Default Domain Controller Policies. These policies apply to all hosts or Domain Controllers and best practice is that these policies should not be used for deployment of files.\n  A threat actor may use these policies to deploy files or scripts to all hosts in a domain.\n  This query uses the ASIM parsers and will need them deployed before usage - https://docs.microsoft.com/azure/sentinel/normalization",
                "severity": "High",
                "enabled": true,
                "query": "let known_processes = (\n  imProcess\n  // Change these values if adjusting Query Frequency or Query Period\n  | where TimeGenerated between(ago(14d)..ago(1d))\n  | where Process has_any (\"Policies\\\\{6AC1786C-016F-11D2-945F-00C04fB984F9}\", \"Policies\\\\{31B2F340-016D-11D2-945F-00C04FB984F9}\")\n  | summarize by Process);\n  imProcess\n  // Change these values if adjusting Query Frequency or Query Period\n  | where TimeGenerated > ago(1d)\n  | where Process has_any (\"Policies\\\\{6AC1786C-016F-11D2-945F-00C04fB984F9}\", \"Policies\\\\{31B2F340-016D-11D2-945F-00C04FB984F9}\")\n  | where Process !in (known_processes)\n  | summarize FirstSeen=min(TimeGenerated), LastSeen=max(TimeGenerated) by Process, CommandLine, DvcHostname",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Execution",
                    "LateralMovement"
                ],
                "techniques": [
                    "T1072",
                    "T1570"
                ],
                "alertRuleTemplateName": "0dd2a343-4bf9-4c93-a547-adf3658ddaec",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "HostName",
                                "columnName": "DvcHostname"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.3"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/42820ff1-4b08-4480-a7c8-64431d08f61d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/42820ff1-4b08-4480-a7c8-64431d08f61d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "New EXE deployed via Default Domain or Default Domain Controller Policies",
                "description": "This detection highlights executables deployed to hosts via either the Default Domain or Default Domain Controller Policies. These policies apply to all hosts or Domain Controllers and best practice is that these policies should not be used for deployment of files.\nA threat actor may use these policies to deploy files or scripts to all hosts in a domain.",
                "severity": "High",
                "enabled": true,
                "query": "let known_processes = (\n  SecurityEvent\n  // If adjusting Query Period or Frequency update these\n  | where TimeGenerated between(ago(14d)..ago(1d))\n  | where EventID == 4688\n  | where NewProcessName has_any (\"Policies\\\\{6AC1786C-016F-11D2-945F-00C04fB984F9}\", \"Policies\\\\{31B2F340-016D-11D2-945F-00C04FB984F9}\")\n  | summarize by Process);\n  SecurityEvent\n  // If adjusting Query Period or Frequency update these\n  | where TimeGenerated > ago(1d)\n  | where EventID == 4688\n  | where NewProcessName has_any (\"Policies\\\\{6AC1786C-016F-11D2-945F-00C04fB984F9}\", \"Policies\\\\{31B2F340-016D-11D2-945F-00C04FB984F9}\")\n  | where Process !in (known_processes)\n  // This will likely apply to multiple hosts so summarize these data\n  | summarize FirstSeen=min(TimeGenerated), LastSeen=max(TimeGenerated) by Process, NewProcessName, CommandLine, Computer",
                "queryFrequency": "P1D",
                "queryPeriod": "P14D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "Execution",
                    "LateralMovement"
                ],
                "techniques": [
                    "T1072",
                    "T1570"
                ],
                "alertRuleTemplateName": "05b4bccd-dd12-423d-8de4-5a6fb526bb4f",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/c3e8859a-5855-4d62-a509-a0a9edb92190')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/c3e8859a-5855-4d62-a509-a0a9edb92190')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Azure VM Run Command operations executing a unique PowerShell script",
                "description": "Identifies when Azure Run command is used to execute a PowerShell script on a VM that is unique.\nThe uniqueness of the PowerShell script is determined by taking a combined hash of the cmdLets it imports\nand the file size of the PowerShell script. Alerts from this detection indicate a unique PowerShell was executed\nin your environment.",
                "severity": "Medium",
                "enabled": true,
                "query": "let RunCommandData = materialize ( AzureActivity\n// Isolate run command actions\n| where OperationNameValue =~ \"Microsoft.Compute/virtualMachines/runCommand/action\"\n// Confirm that the operation impacted a virtual machine\n| where Authorization has \"virtualMachines\"\n// Each runcommand operation consists of three events when successful, StartTimeed, Accepted (or Rejected), Successful (or Failed).\n| summarize StartTime=min(TimeGenerated), EndTime=max(TimeGenerated), max(CallerIpAddress), make_list(ActivityStatusValue) by CorrelationId, Authorization, Caller\n// Limit to Run Command executions that Succeeded\n| where list_ActivityStatusValue has_any (\"Succeeded\", \"Success\")\n// Extract data from the Authorization field, allowing us to later extract the Caller (UPN) and CallerIpAddress\n| extend Authorization_d = parse_json(Authorization)\n| extend Scope = Authorization_d.scope\n| extend Scope_s = split(Scope, \"/\")\n| extend Subscription = tostring(Scope_s[2])\n| extend VirtualMachineName = tostring(Scope_s[-1])\n| project StartTime, EndTime, Subscription, VirtualMachineName, CorrelationId, Caller, CallerIpAddress=max_CallerIpAddress\n| join kind=leftouter (\n    DeviceFileEvents\n    | where InitiatingProcessFileName == \"RunCommandExtension.exe\"\n    | extend VirtualMachineName = tostring(split(DeviceName, \".\")[0])\n    | project VirtualMachineName, PowershellFileCreatedTimestamp=TimeGenerated, FileName, FileSize, InitiatingProcessAccountName, InitiatingProcessAccountDomain, InitiatingProcessFolderPath, InitiatingProcessId\n) on VirtualMachineName\n// We need to filter by time sadly, this is the only way to link events\n| where PowershellFileCreatedTimestamp between (StartTime .. EndTime)\n| project StartTime, EndTime, PowershellFileCreatedTimestamp, VirtualMachineName, Caller, CallerIpAddress, FileName, FileSize, InitiatingProcessId, InitiatingProcessAccountDomain, InitiatingProcessFolderPath\n| join kind=inner(\n    DeviceEvents\n    | extend VirtualMachineName = tostring(split(DeviceName, \".\")[0])\n    | where InitiatingProcessCommandLine has \"-File\"\n    // Extract the script name based on the structure used by the RunCommand extension\n    | extend PowershellFileName = extract(@\"\\-File\\s(script[0-9]{1,9}\\.ps1)\", 1, InitiatingProcessCommandLine)\n    // Discard results that didn't successfully extract, these are not run command related\n    | where isnotempty(PowershellFileName)\n    | extend PSCommand = tostring(parse_json(AdditionalFields).Command)\n    // The first execution of PowerShell will be the RunCommand script itself, we can discard this as it will break our hash later\n    | where PSCommand != PowershellFileName \n    // Now we normalise the cmdlets, we're aiming to hash them to find scripts using rare combinations\n    | extend PSCommand = toupper(PSCommand)\n    | order by PSCommand asc\n    | summarize PowershellExecStartTime=min(TimeGenerated), PowershellExecEnd=max(TimeGenerated), make_list(PSCommand) by PowershellFileName, InitiatingProcessCommandLine\n) on $left.FileName == $right.PowershellFileName\n| project StartTime, EndTime, PowershellFileCreatedTimestamp, PowershellExecStartTime, PowershellExecEnd, PowershellFileName, PowershellScriptCommands=list_PSCommand, Caller, CallerIpAddress, InitiatingProcessCommandLine, PowershellFileSize=FileSize, VirtualMachineName\n| order by StartTime asc \n// We generate the hash based on the cmdlets called and the size of the powershell script\n| extend TempFingerprintString = strcat(PowershellScriptCommands, PowershellFileSize)\n| extend ScriptFingerprintHash = hash_sha256(tostring(PowershellScriptCommands)));\nlet totals = toscalar (RunCommandData\n| summarize count());\nlet hashTotals = RunCommandData\n| summarize HashCount=count() by ScriptFingerprintHash;\nRunCommandData\n| join kind=leftouter (\nhashTotals\n) on ScriptFingerprintHash\n// Calculate prevalence, while we don't need this, it may be useful for responders to know how rare this script is in relation to normal activity\n| extend Prevalence = toreal(HashCount) / toreal(totals) * 100\n// Where the hash was only ever seen once.\n| where HashCount == 1\n| extend timestamp = StartTime, IPCustomEntity=CallerIpAddress, AccountCustomEntity=Caller, HostCustomEntity=VirtualMachineName\n| project timestamp, StartTime, EndTime, PowershellFileName, VirtualMachineName, Caller, CallerIpAddress, PowershellScriptCommands, PowershellFileSize, ScriptFingerprintHash, Prevalence, IPCustomEntity, AccountCustomEntity, HostCustomEntity",
                "queryFrequency": "P1D",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "LateralMovement",
                    "Execution"
                ],
                "techniques": [
                    "T1570",
                    "T1059"
                ],
                "alertRuleTemplateName": "5239248b-abfb-4c6a-8177-b104ade5db56",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Account",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "AccountCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "IP",
                        "fieldMappings": [
                            {
                                "identifier": "Address",
                                "columnName": "IPCustomEntity"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "HostName",
                                "columnName": "HostCustomEntity"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.5"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/10f76f9f-5890-4abc-8c40-95c9562249d3')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/10f76f9f-5890-4abc-8c40-95c9562249d3')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "AD FS Abnormal EKU object identifier attribute",
                "description": "This detection uses Security events from the \"AD FS Auditing\" provider to detect suspicious object identifiers (OIDs) as part EventID 501 and specifically part of the Enhanced Key Usage attributes.\nThis query checks to see if you have any new OIDs in the last hour that have not been seen in the previous day. New OIDs should be validated and OIDs that are very long, as indicated\nby the OID_Length field, could also be an indicator of malicious activity.\nIn order to use this query you need to enable AD FS auditing on the AD FS Server.\nReferences:\nhttps://www.microsoft.com/security/blog/2022/08/24/magicweb-nobeliums-post-compromise-trick-to-authenticate-as-anyone/\nhttps://docs.microsoft.com/windows-server/identity/ad-fs/troubleshooting/ad-fs-tshoot-logging\n",
                "severity": "High",
                "enabled": true,
                "query": "// change the starttime value for a longer period of known OIDs\nlet starttime = 1d;\n// change the lookback value for a longer period of lookback for suspicious/abnormal\nlet lookback = 1h;\nlet OIDList = SecurityEvent\n| where TimeGenerated >= ago(starttime)\n| where EventSourceName == 'AD FS Auditing'\n| where EventID == 501\n| where EventData has '/eku'\n| extend OIDs = extract_all(@\"<Data>([\\d+\\.]+)</Data>\", EventData)\n| mv-expand OIDs\n| extend OID = tostring(OIDs)\n| extend OID_Length = strlen(OID)\n| project TimeGenerated, Computer, EventSourceName, EventID, OID, OID_Length, EventData\n;\nOIDList\n| where TimeGenerated >= ago(lookback)\n| join kind=leftanti (\nOIDList\n| where TimeGenerated between (ago(starttime) .. ago(lookback))\n| summarize by OID\n) on OID",
                "queryFrequency": "PT1H",
                "queryPeriod": "P1D",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "CredentialAccess"
                ],
                "techniques": [
                    "T1552"
                ],
                "alertRuleTemplateName": "cfc1ae62-db63-4a3e-b88b-dc04030c2257",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.2"
            }
        },
        {
            "id": "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/6fa56059-2797-4fae-8e27-41fac8943f5d')]",
            "name": "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/6fa56059-2797-4fae-8e27-41fac8943f5d')]",
            "type": "Microsoft.OperationalInsights/workspaces/providers/alertRules",
            "kind": "Scheduled",
            "apiVersion": "2022-09-01-preview",
            "properties": {
                "displayName": "Credential Dumping Tools - File Artifacts",
                "description": "This query detects the creation of credential dumping tools files. Several credential dumping tools export files with hardcoded file names.\nRef: https://jpcertcc.github.io/ToolAnalysisResultSheet/",
                "severity": "High",
                "enabled": true,
                "query": "// Enter a reference list of malicious file artifacts\nlet MaliciousFileArtifacts = dynamic ([\"lsass.dmp\",\"test.pwd\",\"lsremora.dll\",\"lsremora64.dll\",\"fgexec.exe\",\"pwdump\",\"kirbi\",\"wce_ccache\",\"wce_krbtkts\",\"wceaux.dll\",\"PwHashes\",\"SAM.out\",\"SECURITY.out\",\"SYSTEM.out\",\"NTDS.out\" \"DumpExt.dll\",\"DumpSvc.exe\",\"cachedump64.exe\",\"cachedump.exe\",\"pstgdump.exe\",\"servpw64.exe\",\"servpw.exe\",\"pwdump.exe\",\"fgdump-log\"]);\nEvent\n| where EventLog == \"Microsoft-Windows-Sysmon/Operational\" and EventID==11\n| parse EventData with * 'TargetFilename\">' TargetFilename \"<\" *\n| where TargetFilename has_any (MaliciousFileArtifacts)\n| parse EventData with * 'ProcessGuid\">' ProcessGuid \"<\" * 'Image\">' Image \"<\" *\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by EventID, Computer, Image, ProcessGuid, TargetFilename",
                "queryFrequency": "PT1H",
                "queryPeriod": "PT1H",
                "triggerOperator": "GreaterThan",
                "triggerThreshold": 0,
                "suppressionDuration": "PT5H",
                "suppressionEnabled": false,
                "startTimeUtc": null,
                "tactics": [
                    "CredentialAccess"
                ],
                "techniques": [
                    "T1003"
                ],
                "alertRuleTemplateName": "32ffb19e-8ed8-40ed-87a0-1adb4746b7c4",
                "incidentConfiguration": {
                    "createIncident": true,
                    "groupingConfiguration": {
                        "enabled": false,
                        "reopenClosedIncident": false,
                        "lookbackDuration": "PT5H",
                        "matchingMethod": "AllEntities",
                        "groupByEntities": [],
                        "groupByAlertDetails": [],
                        "groupByCustomDetails": []
                    }
                },
                "eventGroupingSettings": {
                    "aggregationKind": "SingleAlert"
                },
                "alertDetailsOverride": null,
                "customDetails": null,
                "entityMappings": [
                    {
                        "entityType": "File",
                        "fieldMappings": [
                            {
                                "identifier": "Name",
                                "columnName": "TargetFilename"
                            }
                        ]
                    },
                    {
                        "entityType": "Host",
                        "fieldMappings": [
                            {
                                "identifier": "FullName",
                                "columnName": "Computer"
                            }
                        ]
                    },
                    {
                        "entityType": "Process",
                        "fieldMappings": [
                            {
                                "identifier": "CommandLine",
                                "columnName": "Image"
                            }
                        ]
                    }
                ],
                "sentinelEntitiesMappings": null,
                "templateVersion": "1.0.1"
            }
        }
    ]
}
  TEMPLATE
}