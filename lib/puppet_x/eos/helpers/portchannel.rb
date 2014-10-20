#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
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
require 'puppet_x/eos/eapi'

##
# PuppetX namespace
module PuppetX
  ##
  # Eos namesapece
  module Eos
    ##
    # PortChannelMixin module
    module PortChannelMixin

      def conf
        YAML.load_file('/mnt/flash/eapi.conf')
      end

      def eapi
        @eapi ||= PuppetX::Eos::Eapi.new(conf)
      end

      def flowcontrol_to_value(name)
        return { flowcontrol_send: 'off', flowcontrol_receive: 'off' } if /^[Loop|Port|Vlan]/.match(name)
        resp = eapi.enable("show interfaces #{name} flowcontrol")
        tx = resp.first['interfaceFlowControls'][name]['txAdminState']
        rx = resp.first['interfaceFlowControls'][name]['rxAdminState']
        { flowcontrol_send: tx, flowcontrol_receive: rx }
      end

      def switchport_enabled(config)
        enabled_re = Regexp.new('(?<=Switchport:\s)(?<enabled>\w+)')
        m = enabled_re.match(config)
        m['enabled'] == 'Enabled'
      end

      def switchport_mode_to_value(config)
        mode_re = Regexp.new('(?<=Operational Mode:\s)(?<mode>[[:alnum:]|\s]+)\n')
        m = mode_re.match(config)
        m['mode'] == 'static access' ? 'access' : 'trunk'
      end

      def switchport_trunk_vlans_to_value(config)
        trunk_vlans_re = Regexp.new('(?<=Trunking VLANs Enabled:\s)(?<trunking_vlans>[[:alnum:]]+)')
        m = trunk_vlans_re.match(config)
        return m['trunking_vlans'] if !m.nil?
      end

      def portchannel_members_to_value(name)
        id = /\d+(\/\d+)*/.match(name)
        resp = eapi.enable("show port-channel #{id} all-ports", format: 'text')
        resp.first['output'].scan(/Ethernet\d+/)
      end

      def portchannel_lacp_mode_to_value(name)
        resp = eapi.enable("show running-config interfaces #{name}", format: 'text')
        result = resp.first['output']
        match = resp.first['output'].match(/channel-group\s\d+\smode\s(?<lacp>.*)/)
        match['lacp']
      end
    end
  end
end
