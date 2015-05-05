Developing
==========

.. contents:: :local:

Overview
--------

This module can be configured to run directly from source and configured to do
local development, sending the commands to the node over HTTPS/HTTP.  The
following instructions explain how to configure your local development
environment.

Running from source
-------------------

This module requires one dependency in addition to Puppet that must be checked
out as a Git working copy in the context of ongoing development in addition to
running Puppet from source.

 * Ruby client for eAPI: `rbeapi <https://github.com/arista-eosplus/rbeapi>`_

The dependency is managed via the bundler Gemfile and the environment needs to
be configured to use local Git copies::

    cd /workspace
    git clone https://github.com/arista-eosplus/rbeapi.git
    export GEM_RBEAPI_VERSION=file:///workspace/rbeapi

Once the dependencies are installed and the environment configured, then
install all of the dependencies::

    git clone https://github.com/arista-eosplus/puppet-eos.git
    cd puppet-eos
    bundle install --path .bundle/gems

Once everything is installed, run the spec tests to make sure everything is
working properly::

    bundle exec rspec spec

Finally, configure the eapi.conf file for rbeapi `See rbeapi for
details <https://github.com/arista-eosplus/rbeapi#example-eapiconf-file>`_ and
set the connection environment variable to run sanity tests
using `puppet resource`::

    export RBEAPI_CONNECTION=veos01

Contributing
------------

Contributions to this project are gladly welcomed in the form of issues (bugs,
questions, enhancement proposals) and pull requests.  All pull requests must be
accompanied by spec unit tests and up-to-date inline docstrings otherwise the
pull request will be rejected.
