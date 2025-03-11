# Viper Guide

## What is Viper?

Viper is a complete configuration solution for Go applications, designed by Steve Francia (spf13). It's built to handle all types of configuration needs, supporting numerous configuration formats, configuration hierarchies, and live watching of configuration changes.

## Why Use Viper?

- **Format flexibility**: Supports YAML, JSON, TOML, HCL, INI, env files, and more
- **Hierarchical configuration**: Establishes clear precedence for configuration sources
- **Environment variable binding**: Easily maps environment variables to configuration keys
- **Flag binding**: Seamlessly integrates with command-line flags
- **Live watching**: Detects and applies configuration changes without restarting
- **Remote configuration**: Can read from remote config systems (etcd, Consul)
- **Default values**: Provides sane defaults with explicit overrides
- **Unmarshaling**: Populates Go structs directly from configuration

## Core Features

### Configuration Precedence

Viper establishes a clear hierarchy for overriding configurations (from highest to lowest precedence):

1. Explicit call to `Set`
2. Flag (command-line flag)
3. Environment variable
4. Configuration file
5. Key/value store
6. Default value

### Case Insensitivity

All Viper configuration keys are case insensitive, which simplifies configuration management and reduces errors.

## How to Use Viper

### Installation

```shell
go get github.com/spf13/viper
```

### Basic Setup

A typical approach is to create a dedicated configuration package:

```go
package config

import (
    "github.com/spf13/viper"
)

// Config holds all application configuration
type Config struct {
    Server struct {
        Port    int    `mapstructure:"port"`
        Host    string `mapstructure:"host"`
        TLS     bool   `mapstructure:"tls"`
    } `mapstructure:"server"`
    
    Database struct {
        DSN      string `mapstructure:"dsn"`
        MaxConns int    `mapstructure:"max_conns"`
    } `mapstructure:"database"`
    
    LogLevel string `mapstructure:"log_level"`
}

// LoadConfig reads configuration from files or environment variables
func LoadConfig(path string) (config Config, err error) {
    viper.AddConfigPath(path)
    viper.SetConfigName("config")  // name of config file (without extension)
    viper.SetConfigType("yaml")    // YAML as default config type
    
    // Set reasonable defaults
    viper.SetDefault("server.port", 8080)
    viper.SetDefault("server.host", "0.0.0.0")
    viper.SetDefault("log_level", "info")
    
    // Read the config file
    if err = viper.ReadInConfig(); err != nil {
        // It's okay if config file doesn't exist
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return
        }
    }
    
    // Enable reading from environment variables
    viper.AutomaticEnv()
    
    // Unmarshal the configuration into struct
    err = viper.Unmarshal(&config)
    return
}
```

## Advanced Usage

### Working with Nested Structures

Viper handles nested configurations well through struct tags:

```go
type Config struct {
    Database struct {
        Primary struct {
            Host     string `mapstructure:"host"`
            Port     int    `mapstructure:"port"`
            Username string `mapstructure:"username"`
            Password string `mapstructure:"password"`
            Name     string `mapstructure:"name"`
        } `mapstructure:"primary"`
        Replica struct {
            Host     string `mapstructure:"host"`
            Port     int    `mapstructure:"port"`
            Username string `mapstructure:"username"`
            Password string `mapstructure:"password"`
            Name     string `mapstructure:"name"`
        } `mapstructure:"replica"`
    } `mapstructure:"database"`
}
```

### Environment Variables Binding

Explicitly bind environment variables to specific configuration paths:

```go
// Bind DATABASE_PASSWORD to database.primary.password
viper.BindEnv("database.primary.password", "DATABASE_PASSWORD")

// Automatic binding by using an environment variable prefix
viper.SetEnvPrefix("APP")  // Will look for APP_* environment variables
viper.AutomaticEnv()       // Automatically bind environment variables
```

### Command Line Flags Integration

Integrate with `pflag` for command-line arguments:

```go
import "github.com/spf13/pflag"

func init() {
    pflag.String("host", "localhost", "Database host")
    pflag.Int("port", 5432, "Database port")
    pflag.Parse()
    
    viper.BindPFlag("database.primary.host", pflag.Lookup("host"))
    viper.BindPFlag("database.primary.port", pflag.Lookup("port"))
}
```

### Configuration Watching

Watch for configuration changes and reload automatically:

```go
viper.WatchConfig()
viper.OnConfigChange(func(e fsnotify.Event) {
    fmt.Printf("Config file changed: %s\n", e.Name)
    // Re-read the configuration
    if err := viper.Unmarshal(&config); err != nil {
        fmt.Printf("Error unmarshaling config: %s\n", err)
    }
})
```

## Real-world Example

Here's a complete example with a typical directory structure:

```
myapp/
├── cmd/
│   └── server/
│       └── main.go
├── config/
│   ├── config.go
│   └── config.yaml
└── internal/
    └── app/
        └── app.go
```

### config/config.go

```go
package config

import (
    "fmt"
    "github.com/fsnotify/fsnotify"
    "github.com/spf13/pflag"
    "github.com/spf13/viper"
    "strings"
)

type Config struct {
    MssqlDB struct {
        Host     string `mapstructure:"host"`
        Port     string `mapstructure:"port"`
        User     string `mapstructure:"user"`
        Password string `mapstructure:"password"`
        Name     string `mapstructure:"name"`
    } `mapstructure:"mssql_db"`
    
    Auth struct {
        AdminPassword string `mapstructure:"admin_password"`
        AdminUser     string `mapstructure:"admin_user"`
    } `mapstructure:"auth"`
    
    Alarm struct {
        SendEmail  bool     `mapstructure:"send_email"`
        Recipients []string `mapstructure:"recipients"`
    } `mapstructure:"alarm"`
    
    Environment  string `mapstructure:"environment"`
    SqliteDBName string `mapstructure:"sqlite_db_name"`
}

func LoadConfig(path string) (config Config, err error) {
    // Set configuration path
    viper.AddConfigPath(path)
    viper.SetConfigName("config")
    viper.SetConfigType("yaml")
    
    // Set default values
    viper.SetDefault("alarm.send_email", false)
    viper.SetDefault("environment", "dev")
    viper.SetDefault("sqlite_db_name", "auth.db")
    
    // Bind environment variables
    viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    err = viper.BindEnv("mssql_db.password", "MSSQLDB_PASSWORD")
    if err != nil {
        return
    }
    
    err = viper.BindEnv("auth.admin_password", "ADMIN_PASSWORD")
    if err != nil {
        return
    }
    
    // Bind command-line flags
    err = viper.BindPFlag("mssql_db.host", pflag.Lookup("host"))
    if err != nil {
        return
    }
    
    // Enable automatic environment variable binding
    viper.AutomaticEnv()
    
    // Read the configuration file
    err = viper.ReadInConfig()
    if err != nil {
        // It's ok if config file doesn't exist
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return
        }
    }
    
    // Set up configuration watching
    viper.WatchConfig()
    viper.OnConfigChange(func(e fsnotify.Event) {
        fmt.Printf("Config file changed: %s\n", e.Name)
    })
    
    // Unmarshal configuration into struct
    err = viper.Unmarshal(&config)
    if err != nil {
        return
    }
    
    // Handle special cases like slice parsing
    recipients := viper.GetString("alarm.recipients")
    if recipients != "" {
        config.Alarm.Recipients = strings.Split(recipients, ",")
    }
    
    return
}
```

### config/config.yaml

```yaml
mssql_db:
  host: "localhost"
  port: "1433"
  user: "user"
  password: "ModeratePassword"
  name: "DbName"

auth:
  admin_password: "SuperSecretPasswords"
  admin_user: "Admin"

alarm:
  send_email: true
  recipients: "user1@example.com,user2@example.com"

environment: "dev"
```

### cmd/server/main.go

```go
package main

import (
    "fmt"
    "github.com/gin-gonic/gin"
    "github.com/spf13/pflag"
    "myapp/config"
    "myapp/internal/db"
    "log"
)

func main() {
    // Define command-line flags
    pflag.String("host", "localhost", "MSSQL database host")
    pflag.String("port", "1433", "MSSQL database port")
    pflag.Parse()
    
    // Load configuration
    cfg, err := config.LoadConfig(".")
    if err != nil {
        log.Fatal("Cannot load config:", err)
    }
    
    // Print current configuration (for debugging)
    fmt.Printf("Running with config: %+v\n", cfg)
    
    // Initialize database
    if err := db.Initialize(cfg); err != nil {
        log.Fatal("Cannot initialize database:", err)
    }
    
    // Set up HTTP server
    server := gin.Default()
    
    // Start server
    server.Run(fmt.Sprintf(":%s", cfg.Server.Port))
}
```

## Best Practices

1. **Centralize configuration**: Create a dedicated `config` package that other packages import.
2. **Use hierarchical structure**: Organize configuration logically with nesting.
3. **Set sensible defaults**: Always provide reasonable defaults for all configuration values.
4. **Document configuration options**: Comment your config struct and provide example files.
5. **Separate sensitive information**: Use environment variables for secrets, not config files.
6. **Validate configuration**: Add validation to ensure the loaded configuration is valid.
7. **Handle graceful failure**: Application should fail fast if critical configuration is missing.
8. **Use remote configs sparingly**: Remote configuration is powerful but adds complexity.

## Limitations

- **Complexity**: Viper's flexibility can lead to overly complex configuration setups.
- **Performance**: Unmarshaling large configurations can impact startup time.
- **Remote storage**: Requires additional setup and maintenance.
- **Learning curve**: New developers may need time to understand the precedence rules.

## Alternatives

- **Env**: Simple environment variable loading with github.com/caarlos0/env
- **Godotenv**: For .env file loading with github.com/joho/godotenv
- **Konfig**: Configuration management library with live reloading
- **Koanf**: Lightweight configurator framework with minimal dependencies
- **Custom solution**: For simple applications, a custom config package might be sufficient

## Conclusion

Viper provides a comprehensive configuration solution that covers nearly all use cases for Go applications. It particularly shines in environments with multiple configuration sources and dynamic requirements. While it may seem like overkill for simple applications, its flexibility becomes invaluable as applications grow in complexity and operational requirements evolve.

For projects that need to manage configurations across development, testing, and production environments with different overrides and priorities, Viper represents the gold standard in the Go ecosystem.
