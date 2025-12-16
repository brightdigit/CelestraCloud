.PHONY: help test build lint format clean

help:
	@echo "CelestraKit Development Tasks"
	@echo "  test    - Run all tests"
	@echo "  build   - Build the package"
	@echo "  lint    - Run linting checks (strict mode)"
	@echo "  format  - Format code"
	@echo "  clean   - Clean build artifacts"

test:
	swift test

build:
	swift build

lint:
	./Scripts/lint.sh

format:
	LINT_MODE=NONE ./Scripts/lint.sh

clean:
	swift package clean
	rm -rf .build
