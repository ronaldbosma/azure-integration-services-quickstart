# Azure Integration Services Quickstart

A Bicep template for quickly deploying Azure Integration Services such as **Azure API Management**, **Function App**, and **Logic App**, along with supporting resources like **Application Insights**, **Key Vault**, and **Storage Account**. This template is ideal for demos, testing, or getting started with Azure Integration Services.

## Features

- **Integration Services**:
  - Azure API Management (APIM)
  - Azure Function App
  - Azure Logic App (Standard)
- **Shared Resources**:
  - Application Insights for centralized logging and monitoring
  - Azure Key Vault for secure storage of secrets
  - Azure Storage Account for persistent storage
- **Managed Identities**:
  - Each integration service has both a **user-assigned** and **system-assigned managed identity**.
  - These identities are assigned the following roles:
    - Key Vault Secrets User
    - Storage Blob Data Contributor
    - Storage File Data SMB Share Contributor
    - Storage Queue Data Contributor
    - Storage Table Data Contributor
- **Naming Convention**:
  - All resources are deployed using a naming convention based on the [Azure Resource Naming Best Practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). 
  - The naming convention is implemented using user-defined functions in Bicep, which I blogged about in [Apply Azure naming convention using Bicep functions](https://ronaldbosma.github.io/blog/2024/06/05/apply-azure-naming-convention-using-bicep-functions/).


## Purpose

This template is designed to simplify and accelerate the deployment of Azure Integration Services for:
- Demonstrations
- Testing configurations
- Quick setups for experimentation

To minimize cost, the cheapest possible SKUs are used for each service, and virtual networks, application gateways and other security measures typically implemented in production scenarios are not included.

**Note:** This template does not deploy any APIs, functions, or workflows. Users can add these after deployment based on their requirements.
