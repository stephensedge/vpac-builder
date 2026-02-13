deploy_ssc600sw
=========

This role automates deployment of ssc600 SW virtual machine on RHEL KVM hypervisor.

Requirements
------------

This role requires virtualization capabilities enabled on the target host. Additionally target host machines must be configured for running realtime workloads and also for running SSC600 SW. Below two roles can be leveraged to configure system for realtime and also for SSC600 SW
* [prepare_system_for_rt](../prepare_system_for_rt/)
* [prepare_system_for_ssc600sw](../prepare_system_for_ssc600sw/)


Role Variables
--------------
Below are the variables that can be overriden 

| Variable Name | Purpose |
| ------------- | ------- |
| ssc600_vm.name | Name of Virtual machine, must prefix *ssc600 |
| ssc600_vm.path | Path where libvirt images for virtual machine will be stored |
| ssc600_vm.core0 | Core0 to be assigned to VM |
| ssc600_vm.core1 | Core1 to be assigned to VM |
| ssc600_vm.core2 | Core2 to be assigned to VM |
| ssc600_vm.core3 | Core4 to be assigned to VM |
| ssc600_vm.core_qemu | core assigned for qemu |
| ssc600_vm.pb_nic | Process bus networking interface |
| ptp.status_dir | PTP status directory to mount as filesystem for SSC600 VM |
| ssc600_bundle.path | Directory where SSC600 bundle is stored on the host |
| ssc600_bundle.extracted_path | Directory where ssc600 bundle is extracted files are stored. VM disk image is copied from here |


Dependencies
------------

None

Example Playbook
----------------

Including an example of how to use this role (for instance, with variables passed in as parameters):

```yaml
- name: Execute role
  ansible.builtin.import_role:
    name: rprakashg.vpac.deploy_ssc600sw.yml
  vars:
    ssc600_vm:
      name: ssc600-1
      path: /vms/ssc600-1
      core0: 15
      core1: 14
      core2: 13
      core3: 12
      core_qemu: 16-17
      pb_nic: "ens3f0"
    ptp:
      status_dir: /home/libvirt-local/ptp/
    ssc600_bundle:
      path: /home/software
      extracted_path: /home/software/abb
```

You can find the full example playbook [here](../../playbooks/deploy_ssc600sw.yml)

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
