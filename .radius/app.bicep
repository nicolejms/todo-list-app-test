extension radius
extension radiusCompute
extension radiusData
extension radiusSecurity

@description('The Radius environment ID.')
param environment string

@description('The Radius application ID.')
param application string

@secure()
@description('The MySQL root password.')
param mysqlPassword string

@description('The container image for the todo app.')
param image string = 'node:22-alpine'

resource todoApp 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    application: application
    environment: environment
    container: {
      image: image
      ports: {
        http: {
          containerPort: 3000
          protocol: 'TCP'
        }
      }
      env: {
        MYSQL_HOST: mysqlDb.name
        MYSQL_USER: 'mysqladmin'
        MYSQL_PASSWORD: mysqlPassword
        MYSQL_DB: 'todos'
        REDIS_HOST: redisCache.name
        REDIS_PORT: '6379'
      }
    }
    connections: {
      mysql: {
        source: mysqlDb.id
      }
      redis: {
        source: redisCache.id
      }
    }
  }
}

resource mysqlSecret 'Radius.Security/secrets@2025-05-01-preview' = {
  name: 'mysql-secret'
  properties: {
    application: application
    environment: environment
    data: {
      USERNAME: 'mysqladmin'
      PASSWORD: mysqlPassword
    }
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'todo-mysql'
  properties: {
    application: application
    environment: environment
    database: 'todos'
    secretName: mysqlSecret.name
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'todo-redis'
  properties: {
    application: application
    environment: environment
  }
}

resource appRoute 'Radius.Compute/routes@2025-05-01-preview' = {
  name: 'todo-route'
  properties: {
    application: application
    environment: environment
    hostname: 'todo-app.example.com'
    port: 3000
    container: todoApp.id
  }
}
