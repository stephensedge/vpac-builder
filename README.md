# VPAC Builder

Ansible automation for building customized RHEL 9 images and deploying virtualized protection, automation, and control (VPAC) systems for digital electrical substations following IEC 61850.

## Credits

This project is forked from and built upon the work of **Ram Gopinathan** ([@rprakashg](https://github.com/rprakashg)) and his original [rprakashg/vpac](https://github.com/rprakashg/vpac) Ansible collection. His foundational work on the VPAC automation framework made this project possible. This fork adapts the collection for standalone use on a local RHEL 9 build host.

## Prerequisites

- **RHEL 9** (x86_64) — this project is RHEL-only. The Image Builder repo sources use Red Hat CDN URLs and packages (kernel-rt, NFV, HA) that are not available outside RHEL.
- **Active Red Hat subscription** — the host must be registered with `subscription-manager` and have content access. The `setup_imagebuilder` role adds repo sources that pull from the Red Hat CDN (`rhsm = true`).
- **Python 3.9+**
- **ansible-core >= 2.15.4** — RHEL 9 ships ansible-core 2.14.x via RPM, which is too old for the `infra.osbuild` collection. Install via pip:
  ```bash
  pip3 install --user 'ansible-core>=2.15.4,<2.16'
  ```
- **Disk space** — the build host needs at minimum 40 GB of free space. The Image Builder compose process caches data in `/var/lib/osbuild-composer/` and writes artifacts to `/tmp`. Running low on space causes silent compose failures.

### Required System Packages

These CLI tools are called directly by the Ansible roles and must be installed on the build host:

```bash
sudo dnf install -y jq lorax pykickstart genisoimage
```

| Package | Provides | Used By |
|---------|----------|---------|
| `jq` | `jq` | `create_image_installer` — parses JSON output from `composer-cli` |
| `lorax` | `mkksiso` | `inject_ks_into_iso` — injects kickstart into the composed ISO |
| `pykickstart` | `ksvalidator` | `inject_ks_into_iso` — validates generated kickstart syntax |
| `genisoimage` | `genisoimage` | `create_cloudinit_iso` — builds the cloud-init seed ISO |

> `uuidgen` (from `util-linux`) and `composer-cli` (from `osbuild-composer`) are also required but are typically already present — `util-linux` is part of the base OS and `osbuild-composer` is installed by the `setup_imagebuilder` role.

### Required Ansible Collections

```bash
ansible-galaxy collection install infra.osbuild fedora.linux_system_roles community.general community.libvirt ansible.posix containers.podman
```

The `infra.osbuild` collection is critical — the `setup_imagebuilder` role directly imports `infra.osbuild.setup_server` and will fail without it.

## Setting Up a Build Host

The build host is the machine where you run the playbooks to compose RHEL ISOs. It does **not** need to be the same machine you deploy to — it just needs RHEL 9 with a subscription and enough disk space. There are two ways to set one up.

### Option A: Using an Existing RHEL 9 Machine

If you already have a RHEL 9 system (physical or virtual) with an active subscription:

1. Verify the system is registered:
   ```bash
   sudo subscription-manager status
   ```
   If not registered:
   ```bash
   sudo subscription-manager register
   ```

2. Clone the repo:
   ```bash
   git clone https://github.com/stephensedge/vpac-builder.git
   cd vpac-builder
   ```

3. Install system dependencies:
   ```bash
   sudo dnf install -y jq lorax pykickstart genisoimage
   pip3 install --user 'ansible-core>=2.15.4,<2.16'
   ansible-galaxy collection install infra.osbuild fedora.linux_system_roles community.general community.libvirt ansible.posix containers.podman
   ```

4. Continue to [Building the ISOs](#building-the-isos) below.

### Option B: Creating a New RHEL 9 VM as a Build Host

If you don't have a RHEL machine available, create a dedicated build VM. The VM only builds ISOs — it does not need nested virtualization or special hardware.

**Minimum VM specs:**

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 vCPUs | 4 vCPUs |
| RAM | 4 GB | 8 GB |
| Disk | 60 GB | 100 GB |

The extra disk space matters — Image Builder caches composed images under `/var/lib/osbuild-composer/` and writes artifacts to `/tmp`.

1. **Create the VM** using your preferred hypervisor (KVM/virt-manager, VirtualBox, VMware, Hyper-V, or a cloud provider). Install RHEL 9 from the standard RHEL 9 ISO. A minimal or server install is fine.

2. **Register the system** with your Red Hat subscription:
   ```bash
   sudo subscription-manager register
   sudo subscription-manager attach --auto
   ```

3. **Generate an SSH keypair** (used for cloud-init seed ISOs to allow SSH access to deployed hosts):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   ```

4. **Clone the repo and install dependencies:**
   ```bash
   git clone https://github.com/stephensedge/vpac-builder.git
   cd vpac-builder
   sudo dnf install -y jq lorax pykickstart genisoimage
   pip3 install --user 'ansible-core>=2.15.4,<2.16'
   ansible-galaxy collection install infra.osbuild fedora.linux_system_roles community.general community.libvirt ansible.posix containers.podman
   ```

5. Continue to [Building the ISOs](#building-the-isos) below.

## Building the ISOs

All playbooks run against localhost on the build host:

```bash
ansible-playbook playbooks/<playbook>.yml -i localhost, --connection=local --become --ask-become-pass
```

### Step 1: Set Up Image Builder

Installs and configures `osbuild-composer`, Cockpit, and adds package sources for RT (real-time), NFV, HA (high availability), EPEL, and CodeReady Builder repos. This only needs to be run once.

```bash
ansible-playbook playbooks/setup_imagebuilder.yml -i localhost, --connection=local --become --ask-become-pass
```

### Step 2: Create Secrets File

Create `playbooks/vars/secrets.yml` with your credentials:

```yaml
---
root_password: your_password_here
admin_user_password: your_password_here
admin_user_ssh_pubkey: "ssh-ed25519 AAAA... user@host"
```

- `root_password` — root password baked into the kickstart ISO
- `admin_user_password` — password for the `admin` user created by cloud-init
- `admin_user_ssh_pubkey` — public key added to the `admin` user's `authorized_keys` (e.g. contents of `~/.ssh/id_ed25519.pub`)

This file is gitignored. Optionally encrypt it with Ansible Vault:

```bash
ansible-vault encrypt playbooks/vars/secrets.yml
```

If encrypted, add `--ask-vault-pass` to all playbook commands.

### Step 3: Build the RHEL ISO

Creates a blueprint in Image Builder, composes an `image-installer` ISO, then injects a custom kickstart with partitioning, networking, and package configuration.

```bash
ansible-playbook playbooks/create_iso.yml -i localhost, --connection=local --become --ask-become-pass
```

The compose takes 30+ minutes. The playbook polls every 20 seconds until complete.

**Finding the output:** When the playbook finishes, it prints the ISO path in the debug output:

```
"Download ISO with custom kickstart from: /tmp/ansible.XXXXX.vpac-rhel9-base/vpac-rhel9-base_0.0.X-ks.iso"
```

The artifact is **root-owned** in a temp directory. Copy it somewhere accessible:

```bash
sudo cp /tmp/ansible.*/vpac-rhel9-base_*-ks.iso /home/$USER/
sudo chown $USER:$USER /home/$USER/vpac-rhel9-base_*-ks.iso
```

> **Important:** Always use the `-ks.iso` file (the one with the injected kickstart). The plain `.iso` without `-ks` is the raw compose artifact and will show the Anaconda GUI installer instead of running unattended.

### Step 4: Create Cloud-Init Seed ISO

Generates a per-host cloud-init seed ISO that configures hostname, admin user, SSH keys, and networking on first boot. The `iso_name` is automatically derived from the hostname.

```bash
ansible-playbook playbooks/create_cloudinit_iso.yml -i localhost, --connection=local -e hostname=vpac-host1
```

This does not require `--become` — the seed ISO is created in a temp directory owned by your user.

**Finding the output:** The playbook prints the seed ISO path:

```
"Download CloudInit ISO from -> /tmp/ansible.XXXXXiso/vpac-host1-seed.iso"
```

To provision multiple hosts, run it once per host with a different hostname:

```bash
ansible-playbook playbooks/create_cloudinit_iso.yml -i localhost, --connection=local -e hostname=vpac-host2
ansible-playbook playbooks/create_cloudinit_iso.yml -i localhost, --connection=local -e hostname=vpac-host3
```

Each seed ISO gets a unique instance ID so cloud-init treats every host as a new machine.

### Step 5: Write ISOs to USB and Deploy

Copy the ISOs to a machine with USB access (if your build host doesn't have it):

```bash
scp /home/$USER/vpac-rhel9-base_*-ks.iso user@workstation:/tmp/
scp /tmp/ansible.*iso/vpac-host1-seed.iso user@workstation:/tmp/
```

Write both ISOs to separate USB drives:

```bash
# Kickstart installer ISO — one per fleet, reuse for all hosts
sudo dd if=vpac-rhel9-base_0.0.X-ks.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Cloud-init seed ISO — unique per host
sudo dd if=vpac-host1-seed.iso of=/dev/sdY bs=4M status=progress conv=fsync
```

> **Caution:** Double-check the `/dev/sdX` device names with `lsblk` before running `dd` — writing to the wrong device will destroy data.

Plug both USBs into the target bare-metal host and boot from the kickstart USB. The installer runs fully unattended — no manual input needed. On first reboot, cloud-init automatically detects the seed USB (labeled `cidata`) and applies hostname, user, SSH key, and password configuration.

The kickstart `%post` section pre-configures the NoCloud datasource so cloud-init works out of the box on bare metal (RHEL 9 normally disables cloud-init when no recognized datasource is found).

**Reuse the kickstart USB** across all machines — just swap the seed USB for each host.

## Maintenance

### Cleaning Up Old Composes

Image Builder composes consume significant disk space. List and delete old ones regularly:

```bash
sudo composer-cli compose list
sudo composer-cli compose delete <job-id>
```

### Cleaning Up Temp Files

Ansible creates temp directories in `/tmp` during playbook runs:

```bash
sudo rm -rf /tmp/ansible.*
```

### Disk Space

Monitor free space before starting a new compose:

```bash
df -h / /tmp /var
```

If `/` or `/var` is above 80%, clean old composes and temp files first. A compose that runs out of disk space may fail silently or produce a corrupt artifact.

### Rebuilding

The kickstart ISO only needs to be rebuilt when you change packages, partitioning, or kickstart options in `create_iso.yml`. Seed ISOs are quick to regenerate per host.

## Playbooks

| Playbook | Description |
|----------|-------------|
| `setup_imagebuilder.yml` | Configure Image Builder host with required repos and services |
| `create_iso.yml` | Build custom RHEL 9 ISO with kickstart for unattended install |
| `create_cloudinit_iso.yml` | Generate cloud-init seed ISO for first-boot host configuration |
| `enable_virtualization.yml` | Enable KVM virtualization on the host |
| `prepare_system_for_rt.yml` | Configure host for real-time workloads (kernel-rt, hugepages, CPU tuning) |
| `prepare_system_for_ssc600sw.yml` | Prepare host for SSC600 SW deployment |
| `deploy_ssc600sw.yml` | Deploy ABB SSC600 VM with RT CPU pinning and FIFO scheduling |
| `create_windows_vm.yml` | Deploy Windows 11 Pro VM for HMI/SCADA |

## Roles

| Role | Purpose |
|------|---------|
| `setup_imagebuilder` | Install osbuild-composer, cockpit, add RT/NFV/HA/EPEL/CRB repo sources |
| `create_image_installer` | Create Image Builder blueprint and compose an image-installer ISO |
| `inject_ks_into_iso` | Download compose artifact and inject custom kickstart into ISO |
| `create_cloudinit_iso` | Generate cloud-init seed ISO for first-boot host configuration |
| `register_system` | Register RHEL with Red Hat subscription manager |
| `prepare_system_for_rt` | Install kernel-rt, configure hugepages, CPU isolation, PTP, IOMMU |
| `prepare_system_for_ssc600_vm` | Configure dual networking (station-bus/process-bus) for SSC600 |
| `deploy_linux_vm` | Deploy generic Linux VMs on KVM with cloud-init |
| `deploy_ssc600_vm` | Deploy ABB SSC600 VM with real-time optimizations |
| `deploy_windows_vm` | Deploy Windows 11 Pro VMs with unattended install |
| `deploy_otelcollector` | Deploy OpenTelemetry collector (InfluxDB metrics, Loki logs) |
| `setup_centralized_management_system` | Deploy Gitea, AAP, InfluxDB, Loki, Grafana management stack |
| `configure_centralized_management_system` | Configure webhooks and management services |
| `configure_ha` | High availability configuration (placeholder) |
| `configure_windows` | Post-deploy Windows configuration (placeholder) |

## ISO Blueprint Packages

The default `create_iso.yml` blueprint (`vpac-rhel9-base`) includes:

- **Virtualization**: qemu-kvm, libvirt, virt-install, virt-viewer, swtpm, edk2-ovmf
- **Real-time**: kernel-rt, kernel-rt-kvm, tuned-profiles-nfv-host, realtime-tests
- **Management**: ansible-core, cockpit, cockpit-machines, cockpit-podman
- **Cloud-init**: cloud-init, cloud-utils-growpart
- **Utilities**: wget, unzip, bzip2, zstd, mkisofs, dnf-plugins-core, python3-dnf-plugin-versionlock

## Kickstart Partitioning

The default kickstart layout (designed for bare-metal hosts with large disks):

| Mount Point | Type | Size |
|-------------|------|------|
| `/boot` | ext4 | 4 GB |
| `/boot/efi` | EFI | 600 MB |
| `/` | xfs (LVM) | 150 GB |
| `/home` | xfs (LVM) | 200 GB |
| `/vms` | xfs (LVM) | 500 GB |
| `swap` | LVM | recommended |

These sizes are defined in `playbooks/create_iso.yml` under `builder_kickstart_options` and can be adjusted for your hardware. The total requires approximately 860 GB minimum disk on the target host.

## Project Structure

```
vpac-builder/
├── ansible.cfg              # roles_path = ./roles
├── playbooks/
│   ├── setup_imagebuilder.yml
│   ├── create_iso.yml
│   ├── create_cloudinit_iso.yml
│   ├── enable_virtualization.yml
│   ├── prepare_system_for_rt.yml
│   ├── prepare_system_for_ssc600sw.yml
│   ├── deploy_ssc600sw.yml
│   ├── create_windows_vm.yml
│   └── vars/
│       ├── secrets.yml      # gitignored — root_password, admin_user_password, admin_user_ssh_pubkey
│       └── .gitignore
└── roles/
    ├── setup_imagebuilder/
    ├── create_image_installer/
    ├── inject_ks_into_iso/
    ├── create_cloudinit_iso/
    ├── register_system/
    ├── prepare_system_for_rt/
    ├── prepare_system_for_ssc600_vm/
    ├── deploy_linux_vm/
    ├── deploy_ssc600_vm/
    ├── deploy_windows_vm/
    ├── deploy_otelcollector/
    ├── setup_centralized_management_system/
    ├── configure_centralized_management_system/
    ├── configure_ha/
    └── configure_windows/
```

## Changes from Upstream

Forked from [rprakashg/vpac](https://github.com/rprakashg/vpac). Key adaptations:

- Playbook `hosts:` changed from inventory groups to `all` for standalone localhost use
- Role references changed from fully-qualified collection names (`rprakashg.vpac.*`) to local names
- Added `ansible.cfg` with `roles_path` for standalone execution
- Added `create_cloudinit_iso.yml` playbook for generating cloud-init seed ISOs
- Added NoCloud datasource config to kickstart `%post` for automatic cloud-init on bare metal
- Fixed cloud-init user-data schema (`ssh_pwauth` and `chpasswd` moved to top-level)
- Fixed `lock_passwd: false` on all users — cloud-init locks passwords by default
- Enabled root SSH login (`PermitRootLogin yes`) via cloud-init runcmd
- Added `additional_users` template support for provisioning extra users
- Fixed depsolve assertion logic in `create_image_installer` compose task
