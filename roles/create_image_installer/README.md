create_image_installer
=========

This role creates an image installer from a blueprint using osbuild toolset

Requirements
------------

Requires imagebuilder host setup and configured using [setup_imagebuilder](../setup_imagebuilder/) role

Role Variables
--------------

Below you will find description of the settable variables for this role. 

| Variable Name | Purpose |
| ------------- | ------- |
| retries | Number of retries for compose job status |
| delay | delay between retries for compose job status |
| skip_blueprint_creation | Flag to turn off blueprint creation. Useful when you haven't made any changes |
| builder_blueprint_name | osbuild blueprint name |
| builder_blueprint_description | osbuild blueprint description |
| builder_blueprint_distro | RHEL distro to use |
| builder_compose_pkgs | additional packages that need to be included |
| builder_compose_customizations | Customizations |

Dependencies
------------

None

Example Playbook
----------------

Below is a example playbook that demonstrates bulding custom iso images

```yaml
tasks:
  - name: Load secrets from ansible vault
    ansible.builtin.include_vars:
      file: "./vars/secrets.yml"

  - name: Import role
    ansible.builtin.import_role:
      name: rprakashg.vpac.create_image_installer
```

Full playbook can be found [here](../../playbooks/create_iso.yml)

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
