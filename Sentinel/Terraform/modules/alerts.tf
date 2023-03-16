// Create Sentinel Fusion Alert Rule
resource "azurerm_sentinel_alert_rule_fusion" "fusion_alert_rule" {
  name                       = "fusion_alert_rule_fusion"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  alert_rule_template_guid   = "f71aba3d-28fb-450b-b192-4e76a83015c8"
  enabled                    = true
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule
resource "azurerm_sentinel_alert_rule_ms_security_incident" "AAD_IP_alerts" {
  name                       = "ms_security_incident_alert_rule_aad_ip"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Azure Active Directory Identity Protection"
  severity_filter            = ["High"]
  display_name               = "MS Security Incident Alert Rule - AAD IP"
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule for Defender for Cloud
resource "azurerm_sentinel_alert_rule_ms_security_incident" "DFC_alerts" {
  name                       = "ms_security_incident_alert_rule_dfc"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Azure Security Center"
  severity_filter            = ["High"]
  display_name               = "MS Security Incident Alert Rule - DFC"
  alert_rule_template_guid   = "90586451-7ba8-4c1e-9904-7d1b7c3cc4d6"
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule for Azure Advanced Threat Protection
resource "azurerm_sentinel_alert_rule_ms_security_incident" "AATP" {
  name                       = "ms_security_incident_alert_rule_aatp"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Azure Advanced Threat Protection"
  display_name               = "MS Security Incident Alert Rule"
  severity_filter            = ["High"]
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule for Cloud App Security
resource "azurerm_sentinel_alert_rule_ms_security_incident" "CAS" {
  name                       = "ms_security_incident_alert_rule_cas"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Microsoft Cloud App Security"
  display_name               = "MS Security Incident Alert Rule - CAS"
  severity_filter            = ["High"]
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule for Office 365 Advanced Threat Protection
resource "azurerm_sentinel_alert_rule_ms_security_incident" "O365_ATP" {
  name                       = "ms_security_incident_alert_rule"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Office 365 Advanced Threat Protection"
  display_name               = "MS Security Incident Alert Rule - o365"
  severity_filter            = ["High"]
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel MS Security Incident Alert Rule for Defender Advanced Threat Protection
resource "azurerm_sentinel_alert_rule_ms_security_incident" "DATP" {
  name                       = "ms_security_incident_alert_rule_datp"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  product_filter             = "Microsoft Defender Advanced Threat Protection"
  display_name               = "MS Security Incident Alert Rule - DATP"
  severity_filter            = ["High"]
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel Machine Learning Behavior Analytics Alert Rule
resource "azurerm_sentinel_alert_rule_machine_learning_behavior_analytics" "mlba_alert_rule" {
  name                       = "mlbeavior_analytics_alert_rule_mlba"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  alert_rule_template_guid   = "737a2ce1-70a3-4968-9e90-3e6aca836abf"
  enabled                    = true
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Sentinel Machine Learning Anomalous SSH Login Detection ALert Rule
resource "azurerm_sentinel_alert_rule_machine_learning_behavior_analytics" "mlad_alert_rule" {
  name                       = "mlanomalous_ssh_login_detection_alert_rule_mlad"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  alert_rule_template_guid   = "fa118b98-de46-4e94-87f9-8e6d5060b60b"
  enabled                    = true
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}
/*
// Create Sentinel Scheduled Alert Rule
resource "azurerm_sentinel_alert_rule_scheduled" "scheduled_alert_rule" {
  name                       = "NOBELIUM_IOCs_related_to_FoggyWeb_backdoor"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name               = "NOBELIUM IOCs related to FoggyWeb backdoor"
  severity                   = "High"
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
  query = <<QUERY
  let iocs = externaldata(DateAdded:string,IoC:string,Type:string,TLP:string) [@"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/FoggyWebIOC.csv"] with (format="csv", ignoreFirstRecord=True);
let sha256Hashes = (iocs | where Type == "sha256" | project IoC);
let FilePaths = (iocs | where Type =~ "FilePath" | project IoC);
let POST_URI = (iocs | where Type =~ "URI1" | project IoC);
let GET_URI = (iocs | where Type =~ "URI2" | project IoC);
//Include in the list below, the ADFS servers you know about in your environment.  In the next part of the query, we will try to identify them for you if you have the telemetry.
let ADFS_Servers1 = datatable(Computer:string)
[ "<ADFS01>.<DOMAIN>.<COM>",
"<ADFS02>.<DOMAIN>.<COM>"
];
// Automatically identify potential ADFS services in your environment by searching process event telemetry for "Microsoft.IdentityServer.ServiceHost.exe".
let ADFS_Servers2 = 
(union isfuzzy=true
(SecurityEvent
| where EventID == 4688 and SubjectLogonId != "0x3e4"
| where ProcessName has "Microsoft.IdentityServer.ServiceHost.exe"
| distinct Computer
),
( WindowsEvent
| where EventID == 4688 and EventData has "Microsoft.IdentityServer.ServiceHost.exe" and EventData has "0x3e4"
| extend ProcessName = tostring(EventData.ProcessName)
| where ProcessName == "Microsoft.IdentityServer.ServiceHost.exe"
| extend SubjectLogonId = tostring(EventData.SubjectLogonId)
| where SubjectLogonId != "0x3e4"
| distinct Computer
),
(DeviceProcessEvents
| where InitiatingProcessFileName == 'Microsoft.IdentityServer.ServiceHost.exe'
| extend Computer = DeviceName
| distinct Computer
),
(Event
| where Source == "Microsoft-Windows-Sysmon"
| where EventID == 1
| extend EventData = parse_xml(EventData).DataItem.EventData.Data
| mv-expand bagexpansion=array EventData
| evaluate bag_unpack(EventData)
| extend Key=tostring(['@Name']), Value=['#text']
| evaluate pivot(Key, any(Value), TimeGenerated, Source, EventLog, Computer, EventLevel, EventLevelName, UserName, RenderedDescription, MG, ManagementGroupName, Type, _ResourceId)
| extend process = split(Image, '\\', -1)[-1]
| where process =~ "Microsoft.IdentityServer.ServiceHost.exe"
| distinct Computer
)
);
let ADFS_Servers =
ADFS_Servers1
| union  (ADFS_Servers2 | distinct Computer);
(union isfuzzy=true
(DeviceNetworkEvents
| where DeviceName in (ADFS_Servers)
| where isnotempty(InitiatingProcessSHA256) or isnotempty(InitiatingProcessFolderPath)
| where  InitiatingProcessSHA256 has_any (sha256Hashes) or InitiatingProcessFolderPath has_any (FilePaths)
| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId,  InitiatingProcessParentFileName, InitiatingProcessFileName, RemoteIP, RemoteUrl, RemotePort, LocalIP, Type
| extend timestamp = TimeGenerated, IPCustomEntity = RemoteIP, HostCustomEntity = DeviceName
),
(Event
| where Source == "Microsoft-Windows-Sysmon" and EventID == '7'
| where Computer in (ADFS_Servers)
| extend EvData = parse_xml(EventData)
| extend EventDetail = EvData.DataItem.EventData.Data
| extend ImageLoaded = EventDetail.[5].["#text"], Hashes = EventDetail.[11].["#text"]
| parse Hashes with * 'SHA256=' SHA256 '",' *
| where ImageLoaded has_any (FilePaths) or SHA256 has_any (sha256Hashes) 
| project TimeGenerated, EventDetail, UserName, Computer, Type, Source, SHA256, ImageLoaded, EventID
| extend Type = strcat(Type,":",EventID, ": ", Source), Account = UserName, FileHash = SHA256, Image = EventDetail.[4].["#text"] 
| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = tostring(split(Image, '\\', -1)[-1]), AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(CommonSecurityLog
| where FileHash in (sha256Hashes)
| project TimeGenerated,  Message, SourceUserID, FileHash, Type
| extend timestamp = TimeGenerated, AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(DeviceEvents
| where DeviceName in (ADFS_Servers)
| extend FilePath = strcat(FolderPath, '\\', FileName)
| where InitiatingProcessSHA256 has_any (sha256Hashes) or FilePath has_any (FilePaths)
| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type
| extend Account = InitiatingProcessAccountName, Computer = DeviceName, CommandLine = InitiatingProcessCommandLine, FileHash = InitiatingProcessSHA256, Image = InitiatingProcessFolderPath
| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(DeviceFileEvents
| where DeviceName in (ADFS_Servers)
| where FolderPath has_any (FilePaths) or SHA256 has_any (sha256Hashes)
| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type
| extend Account = InitiatingProcessAccountName, Computer = DeviceName, CommandLine = InitiatingProcessCommandLine, FileHash = InitiatingProcessSHA256, Image = InitiatingProcessFolderPath
| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(DeviceImageLoadEvents
| where DeviceName in (ADFS_Servers)
| where FolderPath has_any (FilePaths) or SHA256 has_any (sha256Hashes)
| project TimeGenerated, ActionType, DeviceId, DeviceName, InitiatingProcessAccountDomain, InitiatingProcessAccountName, InitiatingProcessCommandLine, InitiatingProcessFolderPath, InitiatingProcessId, InitiatingProcessParentFileName, InitiatingProcessFileName, InitiatingProcessSHA256, Type
| extend Account = InitiatingProcessAccountName, Computer = DeviceName, CommandLine = InitiatingProcessCommandLine, FileHash = InitiatingProcessSHA256, Image = InitiatingProcessFolderPath
| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = InitiatingProcessFileName, AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(Event
| where Source == "Microsoft-Windows-Sysmon"
| where Computer in (ADFS_Servers)
| extend EvData = parse_xml(EventData)
| extend EventDetail = EvData.DataItem.EventData.Data
| parse EventDetail with * 'SHA256=' SHA256 '",' *
| where EventDetail has_any (sha256Hashes) 
| project TimeGenerated, EventDetail, UserName, Computer, Type, Source, SHA256
| extend Type = strcat(Type, ": ", Source), Account = UserName, FileHash = SHA256, Image = EventDetail.[4].["#text"] 
| extend timestamp = TimeGenerated, HostCustomEntity = Computer , AccountCustomEntity = Account, ProcessCustomEntity = tostring(split(Image, '\\', -1)[-1]), AlgorithmCustomEntity = "SHA256", FileHashCustomEntity = FileHash
),
(W3CIISLog 
| where ( csMethod == 'GET' and csUriStem has_any (GET_URI)) or (csMethod == 'POST' and csUriStem has_any (POST_URI))
| summarize StartTime = max(TimeGenerated), EndTime = min(TimeGenerated), cIP_MethodCount = count() 
by cIP, cIP_MethodCountType = "Count of repeated entries, this is to reduce rowsets returned", csMethod, 
csHost, scStatus, sIP, csUriStem, csUriQuery, csUserName, csUserAgent, csCookie, csReferer
| extend timestamp = StartTime, IPCustomEntity = cIP, HostCustomEntity = csHost, AccountCustomEntity = csUserName
),
(imFileEvent
| where DvcHostname in (ADFS_Servers)
| where TargetFileSHA256 has_any (sha256Hashes) or FilePath has_any (FilePaths)
| extend Account = ActorUsername, Computer = DvcHostname, IPAddress = SrcIpAddr, CommandLine = ActingProcessCommandLine, FileHash = TargetFileSHA256
| project Type, TimeGenerated, Computer, Account, IPAddress, CommandLine, FileHash
)
)
QUERY
}
/*
// Create a new Sentinel Alert Rule for ransomware
resource "azurerm_sentinel_alert_rule_scheduled" "DNS_Domains_linked_to_WannaCry_ransomware_campaign" {
  name                       = "DNS Domains linked to WannaCry ransomware campaign"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name               = "DNS Domains linked to WannaCry ransomware campaign"
  severity                   = "High"
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
  query                      = <<QUERY
  let badDomains = dynamic(["agrdwrtj.us", "bctxawdt.us", "cokfqwjmferc.us", "cxbenjiikmhjcerbj.us", "depuisgef.us", "edoknehyvbl.us", 
  "enyeikruptiukjorq.com", "frullndjtkojlu.us", "gcidpiuvamynj.us", "gxrytjoclpvv.us", "hanoluexjqcf.us", "iarirjjrnuornts.us", 
  "ifbjoosjqhaeqjjwaerri.us", "iouenviwrc.us", "kuuelejkfwk.us", "lkbsxkitgxttgaobxu.us", "nnnlafqfnrbynwor.us", "ns768.com", 
  "ofdwcjnko.us", "peuwdchnvn.us", "pvbeqjbqrslnkmashlsxb.us", "pxyhybnyv.us", "qkkftmpy.us", "rkhlkmpfpoqxmlqmkf.us", 
  "ryitsfeogisr.us", "srwcjdfrtnhnjekjerl.us", "thstlufnunxaksr.us", "udrgtaxgdyv.us", "w5q7spejg96n.com", "xmqlcikldft.us", 
  "yobvyjmjbsgdfqnh.us", "yrwgugricfklb.us", "ywpvqhlqnssecpdemq.us"]);
  DnsEvents
  | where Name in~ (badDomains)
  | summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), count() by Computer, ClientIP, WannaCrypt_Related_Domain = Name
  | extend timestamp = StartTime, HostCustomEntity = Computer, IPCustomEntity = ClientIP, DomainCustomEntity = WannaCrypt_Related_Domain
  ) 
    )
    QUERY
}
*/