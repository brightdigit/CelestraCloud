# CelestraCloud v1.0.0 Release PRD

## Overview
This document outlines the requirements for preparing CelestraCloud for its first production release (v1.0.0). CelestraCloud is a command-line RSS reader demonstrating MistKit's CloudKit integration capabilities.

## Release Checklist

### 1. Infrastructure Migration from MistKit

#### 1.1 CI Configuration
**Source**: MistKit repository
**Tasks**:
- Migrate GitHub Actions workflows
- Update workflow badge URLs to point to CelestraCloud repository
- Ensure all jobs (build, test, lint) pass

#### 1.2 Docker Container
**Source**: MistKit repository
**Tasks**:
- Migrate Dockerfile and docker-compose configuration
- Adapt for CelestraCloud-specific paths and structure
- Verify container can run `celestra` CLI commands
- Add Docker usage documentation to README

#### 1.3 Lint Configuration
**Source**: MistKit repository
**Tasks**:
- Migrate `.swiftlint.yml` or equivalent linting config
- Migrate SwiftFormat configuration if applicable
- Ensure linting passes on entire codebase
- Integrate lint checks into CI pipeline

#### 1.4 Scripts
**Source**: MistKit repository Scripts/ directory
**Tasks**:
- Copy relevant build/deployment scripts to Scripts/
- Adapt scripts for CelestraCloud naming and paths
- Verify all scripts are executable and functional
- Document script usage in README or Scripts/README.md
- Note: CloudKit schema script already exists at `Scripts/setup-cloudkit-schema.sh`

#### 1.5 Xcodegen Project
**Source**: MistKit repository
**Tasks**:
- Migrate `project.yml` or equivalent Xcodegen configuration
- Adapt for CelestraCloud structure
- Verify `xcodegen generate` works correctly
- Ensure generated Xcode project builds successfully
- Update .gitignore to exclude generated files

#### 1.6 Mintfile
**Source**: MistKit repository
**Tasks**:
- Migrate Mintfile to repository root
- List all required development tools (SwiftLint, SwiftFormat, Xcodegen, etc.)
- Add `mint bootstrap` instructions to README

#### 1.7 README Badges
**Tasks**:
- Add CI/build status badge for CelestraCloud
- Add Swift 6.2 version badge
- Add platform badges (macOS, Linux if supported)
- Add license badge
- Add any coverage/quality badges if applicable

### 2. Build System

#### 2.1 Create Makefile
**Purpose**: Simplify common development tasks
**Required Targets**:
- `make build` - Build the project
- `make test` - Run unit tests
- `make lint` - Run linters
- `make run` - Run CLI with default args
- `make setup-cloudkit` - Deploy CloudKit schema
- `make clean` - Clean build artifacts
- `make help` - List all available commands
**Acceptance Criteria**:
- All targets work correctly
- Integrates with existing Scripts/ directory
- Documented in README

### 3. Documentation

#### 3.1 DocC Documentation
**Tasks**:
- Create DocC documentation bundle for public API
- Document key types: Feed, Article, CloudKitService extensions, services
- Include code examples for common operations:
  - Adding a feed
  - Updating feeds with filters
  - Batch operations
- Ensure documentation builds without warnings
- Set up hosted documentation (GitHub Pages or alternatives)

#### 3.2 Reorganize Root Markdown Files
**Current Issue**: Multiple documentation files in repository root cluttering the main directory
**Philosophy**: Documentation belongs in either DocC (API docs), README (user guide), or `.claude/` (development context). No separate `Docs/` directory needed.
**Tasks**:
- **Keep in root**: `README.md`, `CLAUDE.md`, `LICENSE` (create if needed), `CHANGELOG.md` (create for v1.0.0), `CONTRIBUTING.md` (optional)
- **Move to `.claude/`**:
  - `AI_SCHEMA_WORKFLOW.md` - AI-specific workflow guide
  - `IMPLEMENTATION_NOTES.md` - Design decisions and technical context for AI agents
  - `CLOUDKIT_SCHEMA_SETUP.md` - Schema setup reference (automation details)
- **Remove**:
  - `BUSHEL_PATTERNS.md` - Comparison document not needed for v1.0.0 (content already summarized in CLAUDE.md, can be recovered from git history if needed)
- Consolidate essential setup info from `CLOUDKIT_SCHEMA_SETUP.md` into README before moving
- Update internal links in CLAUDE.md to reflect new `.claude/` paths

### 4. Package Configuration

#### 4.1 Verify Package Naming
**Current Status**: Need to ensure consistency
**Tasks**:
- Verify Package.swift has package name "CelestraCloud"
- Ensure CLI executable product is named "celestra-cloud"
- Verify library product "CelestraKit" is properly configured
- Check all target names follow Swift conventions
- Remove any placeholder or temporary names

#### 4.2 Fix SyndiKit Dependency
**Current Issue**: May be using branch reference instead of release tag
**Tasks**:
- Update Package.swift to use specific SyndiKit version tag
- Change from `.branch()` to `.upToNextMajor(from:)` or `.exact()`
- Verify dependency resolution succeeds
- Confirm build works with tagged dependency

### 5. Testing

#### 5.1 Add Unit Tests
**Current Coverage**: Minimal or none
**Required Test Coverage**:
- **RobotsTxtService**: Parsing logic, rule matching, wildcard handling
- **RateLimiter**: Delay calculation, per-domain tracking, concurrent access
- **Feed Model**: `toFieldsDict()` conversion, `init(from:)` parsing, field mapping correctness
- **Article Model**: `toFieldsDict()` conversion, `init(from:)` parsing, optional field handling
- **BatchOperationResult**: Success rate calculation, error aggregation
**Acceptance Criteria**:
- Test target properly configured in Package.swift
- Tests run successfully in CI
- Target minimum 60% code coverage for core logic (excluding CLI command execution)
- All tests pass locally and in CI

### 6. Code Organization

#### 6.1 Migrate Non-MistKit Code to CelestraKit
**Goal**: Proper separation between CLI (CelestraCloud) and shared library (CelestraKit)
**Tasks**:
- Review all code in `Sources/Celestra/`
- Identify reusable, non-CLI specific code
- Move to `../CelestraKit` package as appropriate:
  - Models: Feed and Article (already migrated ✓)
  - Services: Evaluate if any services should be shared
  - Extensions: Evaluate if CloudKit extensions should be shared
  - Utilities: Move any general-purpose utilities
- Ensure CelestraKit is properly referenced in Package.swift dependencies
- Verify no code duplication between packages
- Confirm both packages build independently

## Success Criteria

### Must Have (Blocking Release)
- ✓ All infrastructure migrated from MistKit
- ✓ Makefile created and functional
- ✓ DocC documentation published
- ✓ Documentation files organized in Docs/
- ✓ Package naming verified and consistent
- ✓ SyndiKit dependency uses release tag
- ✓ Unit tests added with ≥60% coverage
- ✓ Code properly separated between CelestraCloud and CelestraKit
- ✓ CI pipeline fully green
- ✓ All existing functionality still works

### Quality Gates
- No compiler warnings
- All linting rules pass
- Documentation builds without warnings
- All tests pass on macOS
- Docker container builds and runs successfully

## Out of Scope for v1.0.0
- iOS/macOS GUI client (future)
- Private database support (public database only)
- Multi-user authentication
- Feed recommendation system
- Advanced search beyond CloudKit queries
- Automatic feed discovery

## Post-Release
- Tag v1.0.0 release on GitHub
- Publish release notes
- Update main branch from v1.0.0-prepare
- Archive development environment if switching to production
