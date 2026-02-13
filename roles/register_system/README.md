register_system
=========

This role uses rhc cli to connect the system with Redhat using redhat credentials read from ansible vault and leverages subscription manager cli to register the system. Role also performs an dnf update to update all the packages and reboots the system and waits for the system to be available online.

Requirements
------------


Role Variables
--------------



Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
