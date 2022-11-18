targetScope = 'subscription'

param location string
param env string
param appName string
@description('Tags retrieved from parameter file.')
param resourceTags object = {}

param frontendContainerImage string
param backendContainerImage string
param backendAPIEndpoint string
param aspEnvironment string
param containerPort int
param registry string
param registryUsername string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${env}-${appName}'
  location: location
  tags: resourceTags
}

module containerAppEnvironment 'container-environment.bicep' = {
  scope: rg
  name: 'container-app-environment'
  params: {
    location: location
    name: appName
  }
}

module backendContainerApp 'container-app.bicep' = {
  scope: rg
  name: '${appName}-backend'
  params: {
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: backendContainerImage
    containerPort: containerPort
    location: location
    name: '${appName}-backend'
    registry: registry
    registrypws: 'mybadpassword'
    registryUsername: registryUsername
    useExternalIngress: false

    envVars: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: aspEnvironment
      }
    ]
  }
}

module frontendContainerApp 'container-app.bicep' = {
  scope: rg
  name: '${appName}-frontend'
  params: {
    containerAppEnvironmentId: containerAppEnvironment.outputs.id
    containerImage: frontendContainerImage
    containerPort: containerPort
    location: location
    name: '${appName}-frontend'
    registry: registry
    registrypws: 'mybadpwd'
    registryUsername: registryUsername
    useExternalIngress: true
    envVars: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: aspEnvironment
      }
      {
        name: 'API__api_address'
        value: 'https://${backendContainerApp.outputs.fqdn}${backendAPIEndpoint}'
      }
      {
        name: 'UI_Texts__Greeting'
        value: 'Greetings from Azure Container Apps'
      }
    ]
  }
}

output fqdn string = frontendContainerApp.outputs.fqdn
