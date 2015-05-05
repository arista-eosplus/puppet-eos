Types
=====

.. contents::
   :local:
   :depth: 2

Getting to know the Types
-------------------------

There are a number of ways to browse the available EOS types::

  $ puppet resource --types | grep eos
  $ puppet describe eos_vlan

Display the current state of a type:

.. code-block:: puppet

  Arista#bash sudo puppet resource eos_vlan
  eos_vlan { '1':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'default',
  }
  eos_vlan { '123':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'VLAN0123',
  }
  eos_vlan { '300':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'ztp_bootstrap',
  }

.. include:: typedoc.rst
