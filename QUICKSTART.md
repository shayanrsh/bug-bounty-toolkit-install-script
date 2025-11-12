# Quick Reference Guide

## Security Tools Installer v3.0.0

### 🚀 Common Commands

#### First Time Installation
```bash
chmod +x install.sh
./install.sh
```

#### Quick Installations
```bash
# Full installation (everything)
./install.sh --full

# Just ZSH environment
./install.sh --zsh-only

# Security tools only
./install.sh --tools-only

# Preview before installing
./install.sh --dry-run --full
```

#### Profile-Based
```bash
./install.sh --profile=minimal    # Fast, essential tools
./install.sh --profile=full       # Everything
./install.sh --profile=pentest    # Pentesting focus
./install.sh --profile=developer  # Dev environment
```

#### Maintenance
```bash
./install.sh --update      # Update all tools
./install.sh --uninstall   # Remove everything
```

---

### 📁 Important Locations

| Item             | Path                              |
| ---------------- | --------------------------------- |
| Installed Tools  | `~/tools/`                        |
| Wordlists        | `~/wordlists/`                    |
| Helper Scripts   | `~/tools/scripts/`                |
| Configuration    | `~/.security-tools/config`        |
| Logs             | `~/.security-tools/logs/`         |
| Manifest (JSON)  | `~/.security-tools/manifest.json` |
| ZSH Config       | `~/.zshrc`                        |
| Security Aliases | `~/.security_aliases`             |

---

### 🔧 Post-Installation

#### Reload Shell
```bash
source ~/.zshrc
# OR restart terminal
```

#### Configure Powerlevel10k
```bash
p10k configure
```

#### Set ZSH as Default
```bash
chsh -s /bin/zsh
```

#### Activate Python Tool Environment
```bash
source ~/tools/scripts/activate_python_tools.sh ghauri
# OR
source ~/tools/ghauri/ghauriEnv/bin/activate
```

---

### 🛠️ Tool Quick Reference

#### Go Tools
```bash
nuclei -h              # Vulnerability scanner
subfinder -h           # Subdomain finder
httpx -h              # HTTP probe
ffuf -h               # Web fuzzer
gobuster -h           # Directory brute force
dnsx -h               # DNS toolkit
gau -h                # Get all URLs
waybackurls -h        # Wayback URLs
```

#### Python Tools (activate environment first)
```bash
cd ~/tools/sqlmap && python3 sqlmap.py -h
cd ~/tools/ghauri && source ghauriEnv/bin/activate && python3 ghauri.py -h
cd ~/tools/XSStrike && source xsstrikeEnv/bin/activate && python3 xsstrike.py -h
cd ~/tools/commix && python3 commix.py -h
```

#### Other Tools
```bash
uro -h                # URL filter (pipx)
arjun -h              # Parameter discovery (pipx)
crunch -h             # Wordlist generator
dalfox -h             # XSS scanner (snap)
```

---

### 📚 Wordlist Locations

```bash
ls ~/wordlists/SecLists/          # Comprehensive lists
ls ~/wordlists/Bo0oM/             # Fuzzing lists
ls ~/wordlists/wordlist/          # Additional lists
ls ~/wordlists/jwt-secrets/       # JWT secrets
ls ~/wordlists/yassineaboukir-gist/  # Custom lists
```

---

### 🐛 Troubleshooting

#### Check Logs
```bash
tail -f ~/.security-tools/logs/install-*.log
```

#### Enable Debug Mode
```bash
./install.sh --debug --full
```

#### Force Reinstall
```bash
./install.sh --force --full
```

#### Test Internet Connectivity
```bash
ping -c 3 google.com
```

#### Verify Tool Installation
```bash
# Check Go tools
ls -la $(go env GOPATH)/bin/

# Check Python tools
ls -la ~/tools/

# Check wordlists
ls -la ~/wordlists/
```

#### Fix Permissions
```bash
chmod +x ~/tools/scripts/*.sh
```

---

### 🎯 Common Use Cases

#### Pentesting Setup
```bash
./install.sh --profile=pentest
```

#### Development Environment
```bash
./install.sh --profile=developer
```

#### Minimal Setup (Fast)
```bash
./install.sh --profile=minimal
```

#### Custom Installation
```bash
./install.sh --custom
# Then select components: 1 4 5 8
# (ZSH + Go Tools + Python Tools + Wordlists)
```

---

### 🔄 Update Workflow

```bash
# Update all tools
./install.sh --update

# Update specific tool manually
cd ~/tools/sqlmap && git pull
cd ~/tools/ghauri && git pull

# Update nuclei templates
nuclei -update-templates

# Update Go tools
go install -a github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

---

### 🗑️ Uninstall

#### Complete Removal
```bash
./install.sh --uninstall
```

#### Manual Cleanup
```bash
rm -rf ~/tools
rm -rf ~/wordlists
rm -rf ~/.security-tools
rm ~/.security_aliases
```

#### Remove ZSH (optional)
```bash
rm -rf ~/.oh-my-zsh
rm ~/.zshrc
rm ~/.p10k.zsh
chsh -s /bin/bash  # Switch back to bash
```

---

### 📊 View Installed Tools

```bash
# View manifest
cat ~/.security-tools/manifest.json | jq '.'

# List Go tools
ls $(go env GOPATH)/bin/

# List Python tools
ls ~/tools/

# Check tool versions
nuclei -version
subfinder -version
httpx -version
```

---

### ⚙️ Configuration

#### Edit Config
```bash
nano ~/.security-tools/config
```

#### View Config
```bash
cat ~/.security-tools/config
```

#### Reset Config
```bash
rm ~/.security-tools/config
./install.sh  # Will create new config
```

---

### 🎨 Aliases

Automatically added to `~/.security_aliases`:

```bash
nuclei-update          # Update nuclei templates
tools                  # cd ~/tools && ls -la
wordlists              # cd ~/wordlists && ls -la
activate-tool TOOL     # Activate Python tool environment
```

---

### 💡 Pro Tips

1. **Always use dry-run first**
   ```bash
   ./install.sh --dry-run --full
   ```

2. **Enable verbose mode for details**
   ```bash
   ./install.sh --verbose --full
   ```

3. **Non-interactive for automation**
   ```bash
   ./install.sh --no-interactive --full
   ```

4. **Check logs if something fails**
   ```bash
   tail -100 ~/.security-tools/logs/install-*.log
   ```

5. **Use profiles for common scenarios**
   ```bash
   ./install.sh --profile=pentest
   ```

---

### 🔍 Advanced Options

#### Environment Variables
```bash
DEBUG=true ./install.sh --full
DRY_RUN=true ./install.sh --full
VERBOSE=true ./install.sh --full
```

#### Skip Checks (Dangerous)
```bash
./install.sh --skip-checks --full
```

#### Force Mode
```bash
./install.sh --force --full
```

---

### 📖 Help

```bash
./install.sh --help
./install.sh --version
```

---

### 🌐 WSL2 Specific

#### Check WSL Version
```bash
wsl.exe -l -v  # Run in PowerShell
```

#### WSL2 Notes
- Snap packages may not work (expected)
- Use Windows drives: `/mnt/c/`
- Disk space checked on both Linux and Windows

---

### 🚨 Emergency Rollback

If installation fails mid-way:

```bash
# The script will prompt you to rollback
# Answer 'y' to undo changes

# Manual rollback:
rm -rf ~/tools
rm -rf ~/wordlists
sudo rm -rf /usr/local/go
rustup self uninstall -y
```

---

### 📝 Checklist After Installation

- [ ] Reload shell: `source ~/.zshrc`
- [ ] Configure theme: `p10k configure`
- [ ] Set default shell: `chsh -s /bin/zsh`
- [ ] Test a tool: `nuclei -h`
- [ ] Check wordlists: `ls ~/wordlists`
- [ ] Review aliases: `cat ~/.security_aliases`
- [ ] Check manifest: `cat ~/.security-tools/manifest.json`

---

**Quick Reference Version**: 3.0.0
**Last Updated**: 2024-11-12

*For detailed documentation, see [README.md](README.md) and [ARCHITECTURE.md](ARCHITECTURE.md)*
