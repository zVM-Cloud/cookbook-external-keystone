# encoding: UTF-8
#
# Cookbook Name:: openstack-zvm-external-keystone
# Spec:: spec_helper
#
# Copyright 2015, 2016 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-zvm-external-keystone' }

require 'chef/application'

LOG_LEVEL = :fatal
REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.5',
  log_level: LOG_LEVEL
}

shared_context 'attribute file' do
  before do
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_controller_address'] = 'CMAcontroller'
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['cmo_admin_password'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_system_role'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['mnadmin_user'] = 'mnadmin'
    node.set['ibm-openstack']['zvm-appliance']['nova-conf']['default']['log_dir'] = 'nova_dir'
    node.set['ibm-openstack']['zvm-appliance']['nova-conf']['default']['state_path'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['database']['connection'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_user_profile'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_xcat_server'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_xcat_password'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_host'] = 'zvm_host'
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['host'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_xcat_master'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['default_publisher_id'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_diskpool_type'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_diskpool'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['instance_name_template'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['default']['zvm_image_default_password'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['nova-conf']['database']['connection'] = ''
    node.set["ibm-openstack"]["zvm-appliance"]["unchangeable-confs"]["ceilometer-conf"]["database"]["connection"] = 'database_connection'


    node.set['ibm-openstack']['zvm-appliance']['cinder-conf']['default']['log_dir'] = 'cinder_dir'
    node.set['ibm-openstack']['zvm-appliance']['cinder-conf']['default']['state_path'] = ''
    node.set['ibm-openstack']['zvm-appliance']['cinder-conf']['default']['volumes_dir'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['cinder-conf']['default']['volume_driver'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['cinder-conf']['default']['storwize_svc_connection_protocol'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['cinder-conf']['database']['connection'] = ''

    node.set['ibm-openstack']['zvm-appliance']['keystone-conf']['default']['log_file'] = 'keystone_file'
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['keystone-conf']['default']['admin_token'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['keystone-conf']['database']['connection'] = ''
    node.set['ibm-openstack']['zvm-appliance']['keystone-conf']['token']['expiration'] = 0
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['keystone-conf']['authentication']['simple_token_secret'] = ''

    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['neutron-conf']['default']['nova_admin_tenant_id'] = ''
    node.set['ibm-openstack']['zvm-appliance']['neutron-conf']['default']['send_events_interval'] = 5
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['neutron-conf']['database']['connection'] = ''
  end
end

shared_context 'external-keystone-stubs' do
  before do
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['heat-conf']['database']['connection'] = ''
    node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['glance-conf']['database']['connection'] = ''
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-compute')
      .and_return('nova-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-network')
      .and_return('neutron-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-block-storage')
      .and_return('cinder-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-image')
      .and_return('glance-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-orchestration')
      .and_return('heat-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-ceilometer')
      .and_return('ceilometer-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin')
    allow_any_instance_of(Chef::Resource::RubyBlock).to receive(:openstack_command_env)
      .with('admin', 'admin')
      .and_return({})
    allow_any_instance_of(Chef::Resource::RubyBlock).to receive(:identity_uuid)
      .with('tenant', 'name', 'service', {}, {})
      .and_return('000-UUID-FROM-CLI')
  end
end
