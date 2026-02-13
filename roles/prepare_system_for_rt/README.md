prepare_system_for_rt
=========

This role configures the virtualization hosts for deploying realtime workloads. 
* Registers the system with Red Hat if not already registered
* Leverages linux system roles to configure bootloader, kernel settings and timesync.
* Configures Intel Cache Allocation
* Install and Configure real time kernel
* Enables virtualization capabilities.
* Configures performance and power profiles with tuned

Requirements
------------

None

Role Variables
--------------
Below are settable variables for this role. 

| Variable Name | Purpose |
| ------------- | ------- |
| tuned.profile | Tuned profile name |
| tuned.rt_cores | Dedicated cores for realtime workload |


Dependencies
------------
Following are the dependencies for this role.

* [linux-system-roles.bootloader](https://galaxy.ansible.com/ui/standalone/roles/linux-system-roles/bootloader/)
* [linux-system-roles.kernel_settings](https://galaxy.ansible.com/ui/standalone/roles/linux-system-roles/kernel_settings/)
* [linux-system-roles.timesync](https://galaxy.ansible.com/ui/standalone/roles/linux-system-roles/timesync)
* [linux-system-roles.tuned](https://galaxy.ansible.com/ui/standalone/roles/linux-system-roles/tuned)


Example Playbook
----------------

Including an example of how to use this role (for instance, with variables passed in as parameters):

```yaml
- name: Import role
  ansible.builtin.import_role:
    name: rprakashg.vpac.prepare_system_for_rt
  vars:
    tuned:
      profile: realtime-virtual-host
      rt_cores: 11-21
```

Full example playbook can be found [here](../../playbooks/prepare_system_for_rt.yml)

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
