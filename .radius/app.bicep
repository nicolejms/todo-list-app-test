extension radius
extension radiusCompute
extension radiusSecurity
extension radiusData

param environment string
param application string

@secure()
param mysqlPassword string

param appImage string = 'node:22-alpine'

resource todoApp 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    container: {
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
          value: mysqlPassword
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
    connections: {
      mysql: {
        source: mysqlDb.id
      }
      redis: {
        source: redisCache.id
      }
    }
    application: application
    environment: environment
  }
}

resource appRoute 'Radius.Compute/routes@2025-05-01-preview' = {
  name: 'todo-app-route'
  properties: {
    application: application
    environment: environment
    container: todoApp.id
    port: 3000
    hostname: '127.0.0.1'
  }
}

resource mysqlSecret 'Radius.Security/secrets@2025-05-01-preview' = {
  name: 'mysql-secret'
  properties: {
    application: application
    environment: environment
    data: {
      password: {
        value: mysqlPassword
      }
    }
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'todo-mysql'
  properties: {
    application: application
    environment: environment
    database: 'todos'
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'todo-redis'
  properties: {
    application: application
    environment: environment
  }
}
