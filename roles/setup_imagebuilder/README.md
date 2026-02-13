setup_imagebuilder
=========

This role setsup image builder server for building customized RHEL images for deployment of VPAC systems

Requirements
------------

Image Builder Host machine running the latest version of Red Hat Enterprise Linux

Role Variables
--------------

None

Dependencies
------------

This role depends on following collections

* [infra.osbuild](https://galaxy.ansible.com/ui/repo/published/infra/osbuild/)

Example Playbook
----------------

Example playbook demonstrates how to use this role.

```yaml
tasks:
  - name: Import role
    ansible.builtin.import_role:
      name: rprakashg.vpac.setup_imagebuilder
```

You can find the full example playbook [here](../../playbooks/setup_imagebuilder.yml)

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
