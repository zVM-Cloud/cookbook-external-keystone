# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2015, 2016 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
#
# Cookbook Name:: ibm-openstack-zvm-appliance-external-keystone
# Recipe:: external_keystone
#

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

# Make Openstack object available in Chef::Resource::RubyBlock
class ::Chef::Resource::RubyBlock
  include ::Openstack
end

include_recipe 'openstack-common::logging'

# generate openrc file
mnadmin = node['ibm-openstack']['zvm-appliance']['unchangeable-confs']['mnadmin_user']
node.force_override['openstack']['openrc']['path'] = "/home/#{mnadmin}" # :pragma-foodcritic: ~FC019
node.force_override['openstack']['openrc']['file'] = 'openrc' # :pragma-foodcritic: ~FC019
node.force_override['openstack']['openrc']['user'] = mnadmin # :pragma-foodcritic: ~FC019
node.force_override['openstack']['openrc']['group'] = 'root' # :pragma-foodcritic: ~FC019
node.force_override['openstack']['openrc']['file_mode'] = '0600' # :pragma-foodcritic: ~FC019
node.force_override['openstack']['openrc']['path_mode'] = '0755' # :pragma-foodcritic: ~FC019
include_recipe 'openstack-common::openrc'

cma_role = node['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_system_role']
identity_admin_endpoint = endpoint 'identity-admin'
identity_endpoint = endpoint 'identity-api'

# create endpoint
if cma_role == 'controller'
  cma_controller_addr = node['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_controller_address']
  node.force_override['openstack']['compute']['network']['service_type'] = 'neutron' # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['compute']['enabled_apis'] = 'osapi_compute,metadata' # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['compute-api']['uri'] = "http://#{cma_controller_addr}:8774/v2/%(tenant_id)s" # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['network-api']['uri'] = "http://#{cma_controller_addr}:9696" # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['block-storage-api']['uri'] = "http://#{cma_controller_addr}:8776/v2/%(tenant_id)s" # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['image-api']['uri'] = "http://#{cma_controller_addr}:9292" # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['orchestration-api-cfn']['uri'] = "http://#{cma_controller_addr}:8000/v1" # :pragma-foodcritic: ~FC019
  # for openstack.endpoints.orchestration-api, we cann't override endpoints by setting uri to "http://#{cma_controller_addr}:8004/v1/%(tenant_id)s"
  # because of openstack-orchestration::identity_registration.rb didn't use URI.decode to decode the uri when creating endpoints
  # so, it would recognize the /v1/%(tenant_id)s as /v1/%25(tenant_id)s.
  node.force_override['openstack']['endpoints']['orchestration-api']['host'] = cma_controller_addr # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['orchestration-api']['scheme'] = 'http' # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['orchestration-api']['port'] = '8004' # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['orchestration-api']['path'] = '/v1/%(tenant_id)s' # :pragma-foodcritic: ~FC019
  node.force_override['openstack']['endpoints']['telemetry-api']['uri'] = "http://#{cma_controller_addr}:8777" # :pragma-foodcritic: ~FC019
  include_recipe 'openstack-identity::registration'
  include_recipe 'openstack-compute::identity_registration'
  include_recipe 'openstack-network::identity_registration'
  include_recipe 'openstack-block-storage::identity_registration'
  include_recipe 'openstack-image::identity_registration'
  include_recipe 'openstack-orchestration::identity_registration'
  include_recipe 'openstack-telemetry::identity_registration'

# register the cinderv1 service and endpoint
  bootstrap_token = get_password 'token', 'openstack_identity_bootstrap_token'
  auth_uri = ::URI.decode identity_admin_endpoint.to_s
  cinder_api_endpoint = endpoint 'block-storage-api'
  v1_endpoint_path = cinder_api_endpoint.to_s.gsub('/v2/', '/v1/')
  region = node['openstack']['block-storage']['region']

  openstack_identity_register 'Register Cinder Volume Service' do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_name 'cinder'
    service_type 'volume'
    service_description 'Cinder Volume Service'
    endpoint_region region
    endpoint_adminurl ::URI.decode v1_endpoint_path
    endpoint_internalurl ::URI.decode v1_endpoint_path
    endpoint_publicurl ::URI.decode v1_endpoint_path
    action :create_service
  end

  openstack_identity_register 'Register Cinder Volume Endpoint' do
    auth_uri auth_uri
    bootstrap_token bootstrap_token
    service_name 'cinder'
    service_type 'volume'
    service_description 'Cinder Volume Service'
    endpoint_region region
    endpoint_adminurl ::URI.decode v1_endpoint_path
    endpoint_internalurl ::URI.decode v1_endpoint_path
    endpoint_publicurl ::URI.decode v1_endpoint_path
    action :create_endpoint
  end
end

# Stop and disable keystone services on CMA
services_to_be_disabled = %w(openstack-keystone)
services_to_be_disabled.each do |s|
  service s do
    provider Chef::Provider::Service::Init::Redhat
    action [:disable, :stop]
  end
end

# List the name of services to be notified
nova_services = %w(openstack-nova-api openstack-nova-compute openstack-nova-conductor openstack-nova-scheduler openstack-nova-cert openstack-nova-console openstack-nova-consoleauth openstack-nova-xvpvncproxy openstack-nova-novncproxy)
neutron_services = %w(neutron-server neutron-zvm-agent)
cinder_services = %w(openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume openstack-cinder-backup)
glance_services = %w(openstack-glance-api openstack-glance-registry)
heat_services = %w(openstack-heat-api openstack-heat-api-cfn openstack-heat-api-cloudwatch openstack-heat-engine)
ceilometer_services = %w(openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-alarm-notifier openstack-ceilometer-alarm-evaluator openstack-ceilometer-polling)

[*nova_services, *neutron_services, *cinder_services, *glance_services, *heat_services, *ceilometer_services].each do |s|
  service s do
    supports status: true, restart: true
    action :nothing
  end
end

# reconfigure the openstack conf
# Reconfigure nova.conf
compute_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['compute']['api']['auth']['version']
neutron_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['network']['api']['auth']['version']
compute_service_pass = get_password 'service', 'openstack-compute'
neutron_service_pass = get_password 'service', 'openstack-network'

template '/etc/nova/nova.conf' do
#  provider Chef::Provider::Template
  source 'nova-external-keystone.conf.erb'
  owner  'nova'
  group  'nova'
  mode   00640
  variables(
        identity_admin_endpoint: identity_admin_endpoint,
        neutron_auth_uri: neutron_auth_uri,
        compute_auth_uri: compute_auth_uri,
        neutron_service_pass: neutron_service_pass,
        compute_service_pass: compute_service_pass
      )
  if cma_role == 'controller'
    notifies :restart, 'service[openstack-nova-api]'
    notifies :restart, 'service[openstack-nova-conductor]'
    notifies :restart, 'service[openstack-nova-scheduler]'
    notifies :restart, 'service[openstack-nova-cert]'
    notifies :restart, 'service[openstack-nova-console]'
    notifies :restart, 'service[openstack-nova-consoleauth]'
    notifies :restart, 'service[openstack-nova-xvpvncproxy]'
    notifies :restart, 'service[openstack-nova-novncproxy]'
  end
  notifies :restart, 'service[openstack-nova-compute]'
end

# Begin to reconfigure neutron.conf
ruby_block 'query service tenant uuid' do
  # query keystone for the service tenant uuid
  block do
    begin
      admin_user = node['openstack']['identity']['admin_user']
      admin_tenant = node['openstack']['identity']['admin_tenant_name']
      is_insecure = node['openstack']['network']['api']['auth']['insecure']
      cafile = node['openstack']['network']['api']['auth']['cafile']
      args = {}
      is_insecure && args['insecure'] = ''
      cafile && args['os-cacert'] = cafile
      env = openstack_command_env admin_user, admin_tenant
      tenant_id = identity_uuid 'tenant', 'name', 'service', env, args
      Chef::Log.error('service tenant UUID for nova_admin_tenant_id not found.') if tenant_id.nil?
      Chef::Log.info 'nova_admin_tenant_id: tenant_id'
      node.set['openstack']['network']['nova']['admin_tenant_id'] = tenant_id
    rescue RuntimeError => e
      Chef::Log.error("Could not query service tenant UUID for nova_admin_tenant_id. Error was #{e.message}")
    end
  end
  action :run
  only_if do
    (node['openstack']['network']['nova']['notify_nova_on_port_status_changes'] == 'True' ||
    node['openstack']['network']['nova']['notify_nova_on_port_data_changes'] == 'True') &&
    node['openstack']['network']['nova']['admin_tenant_id'].nil?
  end
end

# Reconfigure neutron.conf
template '/etc/neutron/neutron.conf' do
  source 'neutron-external-keystone.conf.erb'
  owner  'neutron'
  group  'neutron'
  mode   00640
  variables(
          identity_admin_endpoint: identity_admin_endpoint,
          neutron_auth_uri: neutron_auth_uri,
          neutron_service_pass: neutron_service_pass,
          compute_auth_uri: compute_auth_uri,
          compute_service_pass: compute_service_pass
        )
  if cma_role == 'controller'
    notifies :restart, 'service[neutron-server]'
  end
  notifies :restart, 'service[neutron-zvm-agent]'
end

if cma_role == 'controller'
  # Configure Cinder
  block_storage_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['block-storage']['api']['auth']['version']
  block_storage_service_pass = get_password 'service', 'openstack-block-storage'

  template '/etc/cinder/cinder.conf' do
    source 'cinder-external-keystone.conf.erb'
    owner  'cinder'
    group  'cinder'
    mode   00640
    variables(
            identity_admin_endpoint: identity_admin_endpoint,
            block_storage_auth_uri: block_storage_auth_uri,
            block_storage_service_pass: block_storage_service_pass
          )
    notifies :restart, 'service[openstack-cinder-api]'
    notifies :restart, 'service[openstack-cinder-scheduler]'
    notifies :restart, 'service[openstack-cinder-backup]'
    notifies :restart, 'service[openstack-cinder-volume]'
  end

  # Configure glance-api and glance-registry
  glance_api_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['image']['api']['auth']['version']
  glance_registry_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['image']['registry']['auth']['version']
  glance_service_pass = get_password 'service', 'openstack-image'

  template '/etc/glance/glance-api.conf' do
    source 'glance-api-external-keystone.conf.erb'
    owner  'glance'
    group  'glance'
    mode   00640
    variables(
            identity_admin_endpoint: identity_admin_endpoint,
            glance_api_auth_uri: glance_api_auth_uri,
            glance_service_pass: glance_service_pass
          )
    notifies :restart, 'service[openstack-glance-api]'
    notifies :restart, 'service[openstack-glance-registry]'
  end

  template '/etc/glance/glance-registry.conf' do
    source 'glance-registry-external-keystone.conf.erb'
    owner  'glance'
    group  'glance'
    mode   00640
    variables(
            identity_admin_endpoint: identity_admin_endpoint,
            glance_registry_auth_uri: glance_registry_auth_uri,
            glance_service_pass: glance_service_pass
          )
    notifies :restart, 'service[openstack-glance-api]'
    notifies :restart, 'service[openstack-glance-registry]'
  end

  # Configure Heat
  heat_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['orchestration']['api']['auth']['version']
  heat_service_pass = get_password 'service', 'openstack-orchestration'

  template '/etc/heat/heat.conf' do
    source 'heat-external-keystone.conf.erb'
    owner  'heat'
    group  'heat'
    mode   00640
    variables(
            identity_admin_endpoint: identity_admin_endpoint,
            heat_auth_uri: heat_auth_uri,
            identity_endpoint: identity_endpoint,
            heat_service_pass: heat_service_pass
          )
    notifies :restart, 'service[openstack-heat-api]'
    notifies :restart, 'service[openstack-heat-api-cfn]'
    notifies :restart, 'service[openstack-heat-api-cloudwatch]'
    notifies :restart, 'service[openstack-heat-engine]'
  end
end

# Reconfigure ceilometer.conf
telemetry_auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['telemetry']['api']['auth']['version']
telemetry_service_pass = get_password 'service', 'openstack-ceilometer'

template '/etc/ceilometer/ceilometer.conf' do
  source 'ceilometer-external-keystone.conf.erb'
  owner  'ceilometer'
  group  'ceilometer'
  mode   00640
  variables(
        identity_admin_endpoint: identity_admin_endpoint,
        telemetry_auth_uri: telemetry_auth_uri,
        telemetry_service_pass: telemetry_service_pass,
        cma_role: cma_role
      )
  if cma_role == 'controller'
    notifies :restart, 'service[openstack-ceilometer-api]'
    notifies :restart, 'service[openstack-ceilometer-collector]'
    notifies :restart, 'service[openstack-ceilometer-notification]'
    notifies :restart, 'service[openstack-ceilometer-alarm-notifier]'
    notifies :restart, 'service[openstack-ceilometer-alarm-evaluator]'
  end
  notifies :restart, 'service[openstack-ceilometer-polling]'
end
