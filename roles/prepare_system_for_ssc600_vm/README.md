prepare_system_for_ssc600_vm
=========

This role configures the system for deploying SSC600 SW virtual machines. Performs all necessary steps on the host prior to deploying virtual machine using [role](../deploy_ssc600sw/). Role requires SSC600 SW cab file to be downloaded and copied over to the virtualization host.
* Configures networking stack
* Extracts SSC600 cab file using cab extract and then unzips the disk image and stores extracted contents in `ssc600_bundle.extracted_path` directory specified in variables.
* Deploys startup script and systemd service on the host that are required by SSC600.
* Deploys PTP status script and systemd service on the host and configures timemaster service.
* Configures modprob options and regenerates dracut

Requirements
------------

This role requires the virtualization host be configured for deploying realtime workloads using [role](../prepare_system_for_rt/).

Role Variables
--------------

| Variable Name | Purpose |
| ------------- | ------- |
| rt_config.non_rt_cores_cat | |
| rt_config.non_rt_cache_cat | |
| rt_config.rt_cache | |
| rt_config.rt_cores | |
| rt_config.cpumask | |
| networking.stationbus.nic | Station bus network interface |
| networking.stationbus.ip4 | Static IP v4 address for station bus|
| networking.stationbus.gw4 | Gateway address |
| networking.stationbus.dns4 | DNS |
| networking.processbus.nic | Network interface for process bus |
| ssc600_ptp.status_dir | Status directory for PTP |
| ssc600_ptp.socket | PTP Socket |
| ssc600_ptp.ptp4l_options | PTP options to be configured for SSC600 |
| ssc600_bundle.file | SSC600 SW Cab file name |
| ssc600_bundle.path | Directory where the file is stored |
| ssc600_bundle.extracted_path | Directory where extracted cab file artifacts should be stored |

Dependencies
------------

Following are the list of roles that are being leveraged in this role and need to make sure they are installed before.

* [community.general.nmcli](https://galaxy.ansible.com/ui/repo/published/community/general/content/module/nmcli/)
* [community.general.rhsm_repository](https://galaxy.ansible.com/ui/repo/published/community/general/content/module/rhsm_repository/)


Example Playbook
----------------

Including an example playbook to demonstrate how to leverage this role.

```yaml
- name: Import role
  ansible.builtin.import_role:
    name: rprakashg.vpac.prepare_system_for_ssc600sw
  vars:
    rt_config:
      non_rt_cores_cat: f
      non_rt_cache_cat: "0x1ff"
      rt_cache: "0xe00"
      rt_cores: 13-14
      cpumask: 400
    networking:
      stationbus:
        nic: ens3f3
        ip4: "172.16.20.1/24"
        gw4: 172.16.20.1
        dns4: 8.8.8.8
      processbus:
        nic: "ens3f0"
    ssc600_ptp:
      status_dir: /home/libvirt-local/ptp/
      socket: /var/run/timemaster/ptp4l.0.socket
      ptp4l_options: "-l 5 -A --clientOnly=1 --step_threshold=0.1"
    ssc600_bundle:
      file: SSC600_SW_KVM-1.5.1.cab
      path: /home/software
      extracted_path: /home/software/abb
```

Full playbook can be found [here](../../playbooks/prepare_system_for_ssc600sw.yml)
 
License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
