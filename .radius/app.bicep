extension radius

param environment string
param application string

@secure()
param dbPassword string

param appImage string = 'node:22-alpine'

resource app 'Radius.Core/applications@2025-08-01-preview' = {
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
            value: 'mysql'
          }
          MYSQL_USER: {
            value: 'root'
          }
          MYSQL_PASSWORD: {
            value: dbPassword
          }
          MYSQL_DB: {
            value: 'todos'
          }
          REDIS_HOST: {
            value: 'redis'
          }
          REDIS_PORT: {
            value: '6379'
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
