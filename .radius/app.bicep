extension radius
extension radiusCompute
extension radiusSecurity
extension radiusData

param environment string
param application string

@secure()
param mysqlPassword string

param appImage string = 'node:22-alpine'

resource mysqlSecret 'Radius.Security/secrets@2025-05-01-preview' = {
  name: 'mysql-secret'
  properties: {
    environment: environment
    application: application
    data: {
      password: {
        value: mysqlPassword
      }
    }
  }
}

resource mysqlDatabase 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'todos-db'
  properties: {
    environment: environment
    application: application
    database: 'todos'
    username: 'root'
    secrets: {
      password: {
        source: mysqlSecret.id
        key: 'password'
      }
    }
  }
}

resource todoApp 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'todo-app'
  properties: {
    environment: environment
    application: application
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
          value: mysqlDatabase.properties.host
        }
        MYSQL_USER: {
          value: mysqlDatabase.properties.username
        }
        MYSQL_PASSWORD: {
          value: mysqlPassword
        }
        MYSQL_DB: {
          value: 'todos'
        }
      }
    }
    connections: {
      mysql: {
        source: mysqlDatabase.id
      }
    }
  }
}

resource route 'Radius.Compute/routes@2025-05-01-preview' = {
  name: 'todo-route'
  properties: {
    environment: environment
    application: application
    hostname: 'todo-app.example.com'
    port: 3000
    container: todoApp.id
  }
}
