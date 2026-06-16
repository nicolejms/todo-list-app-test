extension radius

param environment string
param application string

@secure()
param dbPassword string

param appImage string = 'node:22-alpine'

// The application is declared under Applications.Core because the deployment
// engine's recipe-context builder resolves the `application` reference under
// the Applications.Core/applications namespace. Declaring it as Radius.Core
// caused recipes (e.g. the mysql secret) to 404 when looking up the app. The
// single `radius` bicep extension provides both Applications.Core/* and
// Radius.* types, so mixing them in one file is valid.
resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'todo'
  properties: {
    environment: environment
  }
}

resource todoApp 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    environment: environment
    application: app.id
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
    application: app.id
    database: 'todos'
    secretName: mysqlSecret.name
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'todo-redis'
  properties: {
    environment: environment
    application: app.id
  }
}

resource mysqlSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'mysql-secret'
  properties: {
    environment: environment
    application: app.id
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
