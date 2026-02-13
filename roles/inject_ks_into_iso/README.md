create_iso
=========

This role can be used to create a custom ISO with kickstart to perform unattended installation of RHEL

Requirements
------------

None

Role Variables
--------------

Below you will find description of the settable variables for this role. 

| Variable Name | Purpose |
| ------------- | ------- |
| builder_blueprint_name | Blue print name |
| compose_job_id | Compose job id from image installer job that was previously completed|
| builder_kickstart_options | kickstart options to be included in anaconda kickstart file that will be generated and injected into ISO |
| hostname | Host name to be used when provisioning the system with this ISO |


Dependencies
------------

None

Example Playbook
----------------

Example playbook demonstrates how to leverage this role.


License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
