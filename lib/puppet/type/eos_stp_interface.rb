#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# encoding: utf-8

Puppet::Type.newtype(:eos_stp_interface) do
  @doc = <<-EOS
    Manage Spanning Tree Protocol interface configuration.
  EOS

  # Parameters

  newparam(:name) do
    @doc = <<-EOS
      The name for the STP interface.
    EOS
  end

  # Properties (state management)

  newproperty(:portfast) do
    @doc = <<-EOS
      The portfast property programs an STP port to immediately enter
      forwarding state when they establish a link. PortFast ports
      are included in spanning tree topology calculations and can
      enter blocking state. Valid portfast values:

      * true - Enable portfast for the interface
      * false - Disable portfast for the interface (default value)
    EOS
    newvalues(:true, :false)
  end

  newproperty(:portfast_type) do
    @doc = <<-EOS
      Specifies the STP portfast mode type for the interface. A port
      with edge type connect to hosts and transition to the forwarding
      state when the link is established. An edge port that receives a
      BPDU becomes a normal port. A port with network type connect only
      to switches or bridges and support bridge assurance. Network ports
      that connect to hosts or other edge devices transition ot the
      blocking state. Valid portfast mode types:

      * edge - Set STP port mode type to edge.
      * network - Set STP port mode type to network.
      * normal - Set STP port mode type to normal (default value)
    EOS
    newvalues(:edge, :network, :normal)
  end

  newproperty(:bpduguard) do
    @doc = <<-EOS
      Enable or disable the BPDU guard on a port. A BPDU guard-enabled
      port is disabled when it receives a BPDU packet. Disabled ports
      differ from blocked ports in that they are re-enabled only
      through manual intervention. Valid BPDU guard values:

      * true - Enable the BPDU guard for the interface
      * false - Disable the BPDU guard for the interface (default value)
    EOS
    newvalues(:true, :false)
  end
end
