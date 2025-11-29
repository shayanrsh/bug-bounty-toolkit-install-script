# Plugin System for Security Tools Installer

This directory contains plugins for the Security Tools Installer. Each plugin is a self-contained bash script that follows a standardized interface for installing, verifying, updating, and uninstalling a specific tool.

## Plugin Interface

Each plugin must implement the following functions:

### Required Functions

#### `plugin_install()`
Installs the tool. Must return 0 on success, 1 on failure.

#### `plugin_verify()`
Verifies that the tool is correctly installed and functional. Must return 0 if verified, 1 if not.

### Optional Functions

#### `plugin_info()`
Returns metadata about the plugin (description, version, author, etc.)

#### `plugin_update()`
Updates the tool to the latest version.

#### `plugin_uninstall()`
Removes the tool from the system.

#### `plugin_get_version()`
Returns the currently installed version of the tool.

#### `plugin_health_check()`
Performs a comprehensive health check on the tool.

## Creating a New Plugin

1. Copy `_template.sh` to a new file named after your tool (e.g., `mytool.sh`)
2. Implement the required functions
3. Test your plugin with `./install.sh --plugin mytool`

## Plugin Discovery

Plugins are automatically discovered from:
- `./plugins/` (project directory)
- `~/.security-tools/plugins/` (user plugins)

## Example Usage

```bash
# List available plugins
./install.sh --list-plugins

# Install specific plugin
./install.sh --plugin nuclei

# Verify plugin installation
./install.sh --verify-plugin nuclei
```

## Best Practices

1. **Idempotent**: Plugin should be safe to run multiple times
2. **Error Handling**: Always check command exit codes
3. **Logging**: Use `log_info`, `log_success`, `log_error`, `log_warning`
4. **Progress**: Use `ui_progress_bar` for long operations
5. **Cleanup**: Register rollback actions if modifying system state
6. **Verification**: Always verify installation was successful
