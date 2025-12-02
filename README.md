# simpledns-bootstrap
This repo contains ONLY the bootstrap installer and the README. It is safe, public, and designed for use with private SimpleDNS repo - during development.

# SimpleDNS Bootstrap Installer

This repository contains the **public bootstrap installer** used to install the private SimpleDNS server.

The actual SimpleDNS codebase is stored in a **private repo**, so authentication is required.  
This bootstrap process generates an SSH deploy key for the server, allows you to add it to GitHub,  
and then completes installation automatically.

---

## 🚀 Quick Start (Fresh Ubuntu Server)

### 1. Update the system (recommended)
```bash
sudo apt update
sudo apt upgrade -y
