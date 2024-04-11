---
layout: post
title: Navigating the Shift ☁️ Exploring Azure after GCP

tags: ["tech"]
mathjax: true
---

Embarking on a journey from GCP (Google Cloud Platform) to the Microsoft Azure, I find myself at the crossroads of technological transition. Having honed my skills within the realms of GCP, I will soon be working in a company where Microsoft Azure is used. As I embark on this transformative journey, I invite you to join me through this blog, where I document my experiences, insights, and challenges encountered along the way. Whether you're a seasoned GCP enthusiast looking to explore Azure's vast horizons or a curious newcomer eager to delve into the world of cloud computing, there's something here for everyone.

## How to Decide?
Azure and GCP boast numerous AI tools, with Azure excelling in Microsoft products and GCP in Google products like Google Sheets and Analytics.

## Why Azure
Beyond its robust security, Azure offers a secure environment for leveraging OpenAI services, making it ideal for innovation while protecting proprietary data.

Notable users of Microsoft Azure:
- Bosch
- Audi
- ASOS
- HSBC
- Starbucks
- FedEx
- Walmart
- HP
- Mitsubishi Electric
- Renault

## Why GCP
GCP is tailored for data processing and AI development, offering seamless integration with Google's suite of services like Google Workspace, making it the go-to platform for navigating Google's digital realm.

Notable users of Google Cloud Platform:
- Toyota
- Equifax
- Nintendo
- Spotify
- Target
- Twitter
- Paypal
- UPS
- Grap

## Entities

| Type | Description  | GCP  | Azure  |
| :---: | :---: | :---: | :---: |
| Entity | Org | Organization | Management Group, Tenant |
| Entity | Org| Folder | Subscription |
| Entity | Org | Project | Resource Group |
| Entity | Org | Service Account | Service Principal |
| Entity | Org | User | User |
| Entity | Org | Service | Resource |

## Services

| Type | Description  | GCP  | Azure  |
| :---: | :---: | :---: | :---: |
| Compute | IaaS | Compute Engine | Virtual Machines |
| Compute | PaaS | App Engine | App Service |
| Compute | FaaS | Cloud Functions | Azure Function |
| Compute | CaaS | GKE | AKS |
| Compute | CaaS | Cloud Run | Container Apps |
| Networking | Cloud Network | Cloud Virtual Network | VNet |
| Networking | Load Balancer | Cloud LB | Load balancing |
| Networking | CDN | Cloud CDN | Azure CDN |
| Storage | Object Storage | GCS | Storage Account |
| Storage | NOSQL DB | Datastore | Cosmos DB |
| Storage | NOSQL DB (High Performance) | BigTable | Cosmos DB |
| Storage | SQL DB | SQL | SQL Database |
| Storage | Disk | Persistent Disk | Azure Disk |
| BigData | DWH | BigQuery | SQL Warehouse |
| BigData | Butch Data Processing | Dataproc | Data Factory |
| BigData | Stream Data Processing | Dataflow | Stream Analytics |
| BigData | Event Data Processing | PubSub | IoT Hub |
| Developer | Deployment | Deployment Manager | Resource Manager |
| Developer | Git Repo | Source Repositries | Azure Repos |
| Developer | Artifact Repo | Artifact Registry | Container Registry |
| Developer | DevOps | Cloud Build | Azure DevOps |
| Observability | Tracing | Cloud Trace | Service Bus |
| Observability | Logging | Cloud Logging | Log Analysis |
| Observability | Debugfing | Cloud Debugger | Visual Studio |
| Security | Key Management | KMS | Key Vault |
| Security | Identity Access Management | IAM | Active Directory |
| Security | Security Check | Security Scanner | Azure Security Center |

## Cloud CLI

### Create a Project 
```bash
# GCP
gcloud projects create $PROJECT_ID --name="Happy project"

# Azure
az group create -l $LOCATION -n $RESOURCE_NAME
```

### Set a Project 
```bash
# GCP
gcloud config set project $PROJECT_ID

# Azure
az account set --subscription $SUBSCRIPTION_NAME
```

### Check the Currently Active Configuration
```bash
# GCP
gcloud config list

# Azure
az account show
```