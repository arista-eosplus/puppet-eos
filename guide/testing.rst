Testing Modules
===============

.. contents:: :local:

Introduction
------------

Testing infrastructure manifests and modules is, generally, the same as for any other Puppet manifest or module.  The use of tooling such as puppet-lint, rspec-puppet, puppet apply with noop, and deploying canary nodes with Arista vEOS are strongly encouraged.  Be aware that some tools are not immediately available on Arista EOS such as integration with beaker or server-spec.

We recommend using pre-commit hooks and Continuous Integration (CI) systems to encourage good development and testing practices on your Puppet modules.
