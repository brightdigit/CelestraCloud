# Enabling CommandLineArgumentsProvider in Swift Configuration

## Overview

This document outlines how to migrate from our current manual CLI argument parsing to Swift Configuration's built-in `CommandLineArgumentsProvider`. This would eliminate ~45 lines of manual parsing code in UpdateCommand and provide automatic type conversion and validation.

## Current Implementation

Currently, we manually parse command-line arguments in UpdateCommand:

```swift
// Parse command-line arguments
var cliOverrides: [String: Any] = [:]
var i = 0
while i < args.count {
  let arg = args[i]
  switch arg {
  case "--update-delay":
    guard i + 1 < args.count, let value = Double(args[i + 1]) else {
      print("Error: --update-delay requires a numeric value")
      throw ExitError()
    }
    cliOverrides["update.delay"] = value
    i += 2
  // ... more cases
}
```

## Package Trait Requirement

According to Swift Configuration documentation, `CommandLineArgumentsProvider` is **guarded by a package trait** called `CommandLineArgumentsSupport`.

### What are Package Traits?

Package traits are opt-in features in Swift packages that allow you to enable additional functionality without including it by default. This keeps the base package lightweight.

### Available Swift Configuration Traits

- **`JSON`** (default) - JSONSnapshot support
- **`Logging`** (opt-in) - AccessLogger for Swift Log integration
- **`Reloading`** (opt-in) - ReloadingFileProvider for auto-reloading config files
- **`CommandLineArgumentsSupport`** (opt-in) - CommandLineArgumentsProvider
- **`YAML`** (opt-in) - YAMLSnapshot support

## Migration Steps

### Step 1: Enable the Package Trait

Update `Package.swift` to enable the `CommandLineArgumentsSupport` trait:

```swift
dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-alpha.3"),
    .package(url: "https://github.com/brightdigit/CelestraKit.git", branch: "v0.0.1"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(
        url: "https://github.com/apple/swift-configuration.git",
        from: "1.0.0",
        traits: [.defaults, "CommandLineArgumentsSupport"]  // Add this
    )
],
```

**Note**: `.defaults` includes the `JSON` trait which we already use implicitly.

### Step 2: Update ConfigurationLoader

Modify `ConfigurationLoader.swift` to add `CommandLineArgumentsProvider`:

```swift
public actor ConfigurationLoader {
  private let configReader: ConfigReader

  public init(cliOverrides: [String: Any] = [:]) {
    var providers: [any ConfigProvider] = []

    // Priority 1: CLI overrides via InMemoryProvider (for explicit overrides)
    if !cliOverrides.isEmpty {
      let configValues = Self.convertToConfigValues(cliOverrides)
      providers.append(InMemoryProvider(name: "CLI", values: configValues))
    }

    // Priority 2: Command-line arguments (automatic parsing)
    providers.append(CommandLineArgumentsProvider())

    // Priority 3: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }
}
```

**Alternative**: Replace manual parsing entirely:

```swift
public init() {
  var providers: [any ConfigProvider] = []

  // Priority 1: Command-line arguments
  providers.append(CommandLineArgumentsProvider())

  // Priority 2: Environment variables
  providers.append(EnvironmentVariablesProvider())

  self.configReader = ConfigReader(providers: providers)
}
```

### Step 3: Update UpdateCommand

Remove manual parsing and simplify:

```swift
enum UpdateCommand {
  @available(macOS 13.0, *)
  static func run(args: [String]) async throws {
    // No manual parsing needed! CommandLineArgumentsProvider handles it automatically
    let loader = ConfigurationLoader()
    let config = try await loader.loadConfiguration()

    print("🔄 Starting feed update...")
    print("   ⏱️  Rate limit: \(config.update.delay) seconds between feeds")
    // ... rest of implementation
  }
}
```

### Step 4: Update Celestra.swift Entry Point

The main entry point remains the same - pass raw arguments to commands:

```swift
@main
struct Celestra {
  static func main() async {
    let args = Array(CommandLine.arguments.dropFirst())

    guard let command = args.first else {
      printUsage()
      exit(1)
    }

    do {
      switch command {
      case "update":
        try await UpdateCommand.run(args: Array(args.dropFirst()))
      // ... other commands
      }
    } catch {
      print("Error: \(error)")
      exit(1)
    }
  }
}
```

## Key Formats Supported

CommandLineArgumentsProvider automatically parses these formats:

- `--key value` - Standard key-value pair
- `--key=value` - Equals-separated format
- `--key` - Boolean flag (presence = true)
- `--no-key` - Negative boolean (presence = false)

### Example Mappings

```bash
# Command line → Configuration key
--update-delay 3.0           → update.delay = 3.0
--update-skip-robots-check   → update.skip_robots_check = true
--update-max-failures 5      → update.max_failures = 5
```

**Note**: Keys are automatically converted:
- CLI: `--update-delay` (kebab-case with dashes)
- Config: `update.delay` (dot-notation)

## Array Handling

Multiple values for the same key create arrays:

```bash
--ports 8080 8443 9000  →  ports = [8080, 8443, 9000]
```

## Secrets Support

CommandLineArgumentsProvider supports marking values as secret:

```swift
let provider = CommandLineArgumentsProvider(
  secretsSpecifier: .specific(["--cloudkit-key-id", "--cloudkit-private-key-path"])
)
```

This prevents secrets from appearing in logs or debug output.

## Testing

To test all traits during development:

```bash
swift test --enable-all-traits
```

## Advantages

### ✅ Benefits of CommandLineArgumentsProvider

1. **Less Code**: Remove ~45 lines of manual parsing
2. **Automatic Type Conversion**: Handles String → Int, Double, Bool, etc.
3. **Better Error Messages**: Built-in validation and error reporting
4. **Array Support**: Automatically handles multiple values
5. **Secrets Handling**: Built-in support for sensitive values
6. **Consistent**: Same parsing logic used across all Apple tools
7. **Maintainable**: Adding new options requires no parsing code

### ⚠️ Potential Considerations

1. **Trait Dependency**: Requires enabling package trait (minimal overhead)
2. **Compatibility**: Requires Swift Configuration 1.0+ (already using)
3. **Key Format**: Must use `--kebab-case` format (current standard)

## Migration Checklist

- [ ] Update Package.swift with `CommandLineArgumentsSupport` trait
- [ ] Resolve dependencies: `swift package resolve`
- [ ] Update ConfigurationLoader to use CommandLineArgumentsProvider
- [ ] Remove manual parsing from UpdateCommand (~45 lines)
- [ ] Build and test: `swift build`
- [ ] Test CLI arguments: `swift run celestra-cloud update --update-delay 3.0`
- [ ] Test environment variables still work: `UPDATE_DELAY=2.0 swift run celestra-cloud update`
- [ ] Test priority: CLI should override environment variables
- [ ] Update CLAUDE.md with new approach

## Example: Before vs After

### Before (Current - Manual Parsing)

```swift
static func run(args: [String]) async throws {
  var cliOverrides: [String: Any] = [:]
  var i = 0
  while i < args.count {
    let arg = args[i]
    switch arg {
    case "--update-delay":
      guard i + 1 < args.count, let value = Double(args[i + 1]) else {
        print("Error: --update-delay requires a numeric value")
        throw ExitError()
      }
      cliOverrides["update.delay"] = value
      i += 2
    case "--update-skip-robots-check":
      cliOverrides["update.skip_robots_check"] = true
      i += 1
    // ... 5 more cases
    default:
      print("Unknown option: \(arg)")
      throw ExitError()
    }
  }

  let loader = ConfigurationLoader(cliOverrides: cliOverrides)
  let config = try await loader.loadConfiguration()
  // ...
}
```

### After (With CommandLineArgumentsProvider)

```swift
static func run(args: [String]) async throws {
  // CommandLineArgumentsProvider automatically parses all arguments
  let loader = ConfigurationLoader()
  let config = try await loader.loadConfiguration()
  // ...
}
```

**Lines of code reduced**: ~45 lines → 2 lines

## Verification from Documentation

Per the Swift Configuration 1.0.0 documentation:

> **CommandLineArgumentsProvider**
> A configuration provider that sources values from command-line arguments.
>
> **Package traits**
> This type is guarded by the `CommandLineArgumentsSupport` package trait.

Source: https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration/commandlineargumentsprovider

## Recommendation

**Recommended**: Enable `CommandLineArgumentsSupport` trait. The benefits significantly outweigh the minimal cost of adding a package trait. The code will be cleaner, more maintainable, and less error-prone.

The migration is straightforward and low-risk since we can test incrementally while keeping the current implementation as a fallback.
