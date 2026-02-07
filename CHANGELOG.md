# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-02-07

### Added
- **Import JSON Feature**: New entry point in Home Screen to import recipes from JSON.
- **Smart JSON Parser**: `RecipeJsonParser` utility handles markdown blocks, function call wrappers, and auto-generates UUIDs.
- **Paste Dialog**: dedicated UI for pasting and formatting recipe JSON.

### Fixed
- **Theme**: Corrected `CardThemeData` usage in `lib/utils/theme.dart`.
