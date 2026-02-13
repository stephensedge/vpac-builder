# VPAC Builder

Ansible automation for building customized RHEL 9 images and deploying virtualized protection, automation, and control (VPAC) systems for digital electrical substations following IEC 61850.

Based on the [rprakashg/vpac](https://github.com/rprakashg/vpac) Ansible collection, adapted for standalone use on a local build host.

## Prerequisites

- RHEL 9 host with active Red Hat subscription
- `ansible-core` >= 2.15.4 (RHEL 9 ships 2.14.x — install via `pip3 install --user 'ansible-core>=2.15.4,<2.16'`)
- Python 3.9+

### Required Ansible Collections

```bash
ansible-galaxy collection install infra.osbuild fedora.linux_system_roles community.general community.libvirt ansible.posix containers.podman
```

## Quick Start

All playbooks are designed to run against localhost on the build host:

```bash
cd /path/to/vpac-custom
ansible-playbook playbooks/<playbook>.yml -i localhost, --connection=local --become --ask-become-pass
```

### Step 1: Set Up Image Builder

Installs and configures `osbuild-composer`, Cockpit, and adds package sources for RT (real-time), NFV, HA (high availability), EPEL, and CodeReady Builder repos.

```bash
ansible-playbook playbooks/setup_imagebuilder.yml -i localhost, --connection=local --become --ask-become-pass
```

### Step 2: Create Secrets File

Create `playbooks/vars/secrets.yml` with your desired root password for the ISO:

```yaml
---
root_password: your_password_here
```

This file is gitignored. Optionally encrypt it:

```bash
ansible-vault encrypt playbooks/vars/secrets.yml
```

### Step 3: Build the RHEL ISO

Creates a blueprint in Image Builder, composes an `image-installer` ISO, then injects a custom kickstart with partitioning, networking, and package configuration.

```bash
ansible-playbook playbooks/create_iso.yml -i localhost, --connection=local --become --ask-become-pass
```

The compose can take a long time (30+ minutes). The playbook polls every 20 seconds until complete.

## Playbooks

| Playbook | Description |
|----------|-------------|
| `setup_imagebuilder.yml` | Configure Image Builder host with required repos and services |
| `create_iso.yml` | Build custom RHEL 9 ISO with kickstart for unattended install |
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
| `create_cloudinit_iso` | Generate cloud-init seed ISO for VM first-boot config |
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

The default kickstart layout:

| Mount Point | Type | Size |
|-------------|------|------|
| `/boot` | ext4 | 4 GB |
| `/boot/efi` | EFI | 600 MB |
| `/` | xfs (LVM) | 150 GB |
| `/home` | xfs (LVM) | 200 GB |
| `/vms` | xfs (LVM) | 500 GB |
| `swap` | LVM | recommended |

## Project Structure

```
vpac-custom/
├── ansible.cfg              # roles_path = ./roles
├── playbooks/
│   ├── setup_imagebuilder.yml
│   ├── create_iso.yml
│   ├── enable_virtualization.yml
│   ├── prepare_system_for_rt.yml
│   ├── prepare_system_for_ssc600sw.yml
│   ├── deploy_ssc600sw.yml
│   ├── create_windows_vm.yml
│   └── vars/
│       ├── secrets.yml      # gitignored — root_password, etc.
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

## Upstream

Forked from [rprakashg/vpac](https://github.com/rprakashg/vpac). Key adaptations:

- Playbook `hosts:` changed from inventory groups to `all` for standalone localhost use
- Role references changed from fully-qualified collection names (`rprakashg.vpac.*`) to local names
- Added `ansible.cfg` with `roles_path` for standalone execution
- Fixed depsolve assertion logic in `create_image_installer` compose task
