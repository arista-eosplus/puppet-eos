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

require 'spec_helper'

describe Puppet::Type.type(:eos_ethernet) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: 'Ethernet42', catalog: catalog) }

  describe 'name' do
    let(:attribute) { :name }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
  end

  describe 'description' do
    let(:attribute) { :description }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', %w(B41.5)
    include_examples 'rejects values', [[1], { two: :three }]
  end

  describe 'enable' do
    let(:attribute) { :enable }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
    include_examples 'rejected parameter values'
  end

  describe 'flowcontrol_send' do
    let(:attribute) { :flowcontrol_send }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', [:on, :off]
    include_examples 'rejected parameter values'
  end

  describe 'flowcontrol_receive' do
    let(:attribute) { :flowcontrol_receive }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', [:on, :off]
    include_examples 'rejected parameter values'
  end

  describe 'speed' do
    let(:attribute) { :speed }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', ['default', '100full', '10full', 'auto',
      'auto 100full', 'auto 10full', 'auto 40gfull', 'forced 10000full',
      'forced 1000full', 'forced 1000half', 'forced 100full',
      'forced 100gfull', 'forced 100half', 'forced 10full', 'forced 10half',
      'forced 40gfull', 'sfp-1000baset auto 100full']
    include_examples 'rejects values', [0, 15, '0', '15', { two: :three },
      :'abc']
  end

  describe 'lacp_priority' do
    let(:attribute) { :lacp_priority }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 65535]
    include_examples 'rejects values', [[-1], -1, 65536, { two: :three }]
  end
end
