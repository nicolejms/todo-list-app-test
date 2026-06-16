extension radius
// redisCaches is a custom resource type generated on the fly (no recipe exists
// for it in resource-types-contrib). Its Bicep types are published from
// .radius/resource-types/data/redisCaches/redisCaches.yaml into a local
// extension during deploy, so Bicep can route it to the Radius control plane
// instead of falling back to the Azure ARM provider.
extension redisCaches

param environment string
param application string

@secure()
param dbPassword string

param appImage string = 'node:22-alpine'

resource todoApp 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    environment: environment
    application: application
    connections: {
      mysql: {
        source: mysqlDb.id
      }
      redis: {
        source: redisCache.id
      }
    }
    containers: {
      app: {
        image: appImage
        ports: {
          http: {
            containerPort: 3000
            protocol: 'TCP'
          }
        }
        env: {
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_USER: {
            value: 'mysqladmin'
          }
          MYSQL_PASSWORD: {
            value: dbPassword
          }
          MYSQL_DB: {
            value: 'todos'
          }
          REDIS_HOST: {
            value: redisCache.properties.host
          }
          REDIS_PORT: {
            value: string(redisCache.properties.port)
          }
        }
      }
    }
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'todo-mysql'
  properties: {
    environment: environment
    application: application
    database: 'todos'
    secretName: mysqlSecret.name
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'todo-redis'
  properties: {
    environment: environment
    application: application
  }
}

resource mysqlSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'mysql-secret'
  properties: {
    environment: environment
    application: application
    data: {
      USERNAME: {
        value: 'mysqladmin'
      }
      PASSWORD: {
        value: dbPassword
      }
    }
  }
}