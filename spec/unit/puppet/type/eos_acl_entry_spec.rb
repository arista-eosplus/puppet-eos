#
# Copyright (c) 2015, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_acl_entry) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: 'test:10', catalog: catalog) }

  it_behaves_like 'an ensurable type', name: 'test:10'

  describe 'name' do
    let(:attribute) { :name }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', %w[eng:20]
    include_examples 'rejects values', [[1], { two: :three }]
  end

  describe 'acltype' do
    let(:attribute) { :acltype }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', %i[standard extended]
    include_examples 'rejects values', [[1], { two: :three }]
  end

  describe 'action' do
    let(:attribute) { :action }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', %i[permit deny remark]
    include_examples 'rejects values', [[1], { two: :three }]
  end

  describe 'remark' do
    let(:attribute) { :remark }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    # type[:action] = :permit
    # include_examples 'accepts values without munging',
    # ['this is a comment...', 'Testing']
    # include_examples 'rejects values', [[1], { two: :three }]
    it 'accepts a string' do
      type[:action] = :remark
      type[:remark] = 'somevalue'
    end

    it 'rejects non-strings' do
      type[:action] = :remark
      expect { type[:remark] = 1 }
        .to raise_error Puppet::ResourceError,
                        /is invalid, must be a String./
      expect { type[:remark] = %w[one two] }
        .to raise_error Puppet::ResourceError,
                        /is invalid, must be a String./
    end

    it 'fails when the action is not "remark"' do
      type[:action] = :permit
      expect { type[:remark] = 'somevalue' }
        .to raise_error Puppet::ResourceError,
                        /Remark property is only valid when 'action => remark'/
    end
  end

  describe 'srcaddr' do
    let(:attribute) { :srcaddr }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', ['1.2.3.0', 'any',
                                                        'host 9.8.7.6']
    include_examples 'rejects values', ['1.2', '255.255.255.256', 'bogus',
                                        'host', 'host 1.2.3']
  end

  describe 'srcprefixlen' do
    let(:attribute) { :srcprefixlen }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'numeric parameter', min: 0, max: 32
    include_examples 'rejects values', [-1, 33]
  end

  describe 'log' do
    let(:attribute) { :log }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
    include_examples 'rejected parameter values'
  end
end
