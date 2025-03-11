# Go mod vendor

## What is go mod vendor?

`go mod vendor` is a command in Go's module system that creates a `vendor` directory containing copies of all packages needed to support builds and tests of packages in the main module. It effectively snapshots your dependencies locally within your project.

## Why Use go mod vendor?

- **Reproducible builds**: Ensures everyone building your code uses identical dependency versions, even if the original repositories change or disappear.
- **Offline development**: Enables development without internet access once dependencies are vendored.
- **Corporate environments**: Useful in environments with limited external network access or strict security policies.
- **Build speed**: Can improve build performance in certain environments by eliminating network calls.
- **Dependency auditing**: Makes it easier to audit and review all code that will be compiled into your binary.
- **Legacy compatibility**: Supports workflows transitioning from pre-modules Go or systems expecting vendored dependencies.

## How to Use It

Basic usage is straightforward:

```shell
# Initialize a module if you haven't already
go mod init example.com/myproject

# Add dependencies through imports and builds
go get github.com/some/dependency
go build ./...

# Create or update the vendor directory
go mod vendor

# Build using vendored dependencies
go build -mod=vendor ./...
```

## Key Behaviors

- Copies dependencies into the `vendor/` directory at the root of your module
- Creates a `vendor/modules.txt` file listing module versions
- Only includes packages imported by your module's packages
- Ignores test dependencies from imported packages
- Preserves the module structure in the vendor directory

## Use Cases

1. **CI/CD pipelines**: Ensures consistent builds across different environments.
2. **Air-gapped environments**: Enables development in secure environments without external network access.
3. **Dependency control**: Provides a clear snapshot of exactly what code your application depends on.
4. **Deployment simplification**: Simplifies deployment by including all necessary code in one package.
5. **Legacy build systems**: Supports integration with systems expecting vendored dependencies.

## Best Practices

- **Version control**: Include `vendor/` in version control for complete reproducibility.
- **Document usage**: Specify in your README whether `-mod=vendor` should be used.
- **Regular updates**: Periodically run `go mod tidy` followed by `go mod vendor` to keep dependencies current.
- **Review changes**: Before committing vendor updates, review the changes to catch unexpected dependency shifts.
- **CI validation**: Validate in CI that the vendor directory is in sync with go.mod using `go mod vendor && git diff --exit-code`.

## Limitations

- **Size**: Can significantly increase repository size.
- **Maintenance overhead**: Requires explicit updates of the vendor directory.
- **Partial solution**: Other build-time dependencies (like C libraries) still need separate management.
- **Test dependencies**: Dependencies used only in tests of dependencies are not included.

## Alternatives

- **go.mod without vendor**: Relying on Go's standard module cache without vendoring.
- **Proxy servers**: Using Go module proxies like Athens or Google's proxy for caching.
- **Module replacement**: Using the `replace` directive in go.mod for specific module control.

## Real-world Example

A common workflow in enterprise environments:

```shell
# Initial setup
go mod init company.com/service
go get -u ./...
go mod tidy
go mod vendor

# When updating dependencies
go get -u github.com/dependency/to/update
go mod tidy
go mod vendor
git add vendor/ go.mod go.sum
git commit -m "Update dependencies, including github.com/dependency/to/update"
```

## Conclusion

`go mod vendor` remains a valuable tool in Go's module ecosystem, particularly for enterprise environments, CI/CD pipelines, and scenarios requiring complete reproducibility or offline development. While not always necessary for simple projects, understanding when and how to use vendoring effectively is an important skill for Go developers working on production systems.
