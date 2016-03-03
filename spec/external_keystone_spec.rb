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
# Cookbook Name:: ibm-openstack-external-keystone
# Spec:: external_keystone_spec
#
require_relative 'spec_helper'

describe 'ibm-openstack-external-keystone::external_keystone' do
  let(:runner) { ChefSpec::ServerRunner.new(REDHAT_OPTS) }
  let(:node) { runner.node }
  let(:chef_run) do
    node.set['openstack']['region'] = 'ZController'
    node.set['openstack']['endpoints']['host'] = 'cmaip'
    node.set['openstack']['endpoints']['bind-host'] = 'cmaip'
    node.set['openstack']['endpoints']['identity-api']['host'] = 'keystoneip'
    node.set['openstack']['endpoints']['identity-admin']['host'] = 'keystoneip'
    node.set['openstack']['endpoints']['identity-internal']['host'] = 'keystoneip'
    runner.converge(described_recipe)
  end

  include_context 'attribute file'
  include_context 'external-keystone-stubs'

  context 'common test for controller and compute role' do
    # test includes_recipe
    it 'includes openstack-common::logging recipe' do
      expect(chef_run).to include_recipe('openstack-common::logging')
    end

    it 'openrc force_override attributes' do
      expect(chef_run.node['openstack']['openrc']['path']).to eq('/home/mnadmin')
      expect(chef_run.node['openstack']['openrc']['file']).to eq('openrc')
      expect(chef_run.node['openstack']['openrc']['user']).to eq('mnadmin')
      expect(chef_run.node['openstack']['openrc']['group']).to eq('root')
      expect(chef_run.node['openstack']['openrc']['file_mode']).to eq('0600')
      expect(chef_run.node['openstack']['openrc']['path_mode']).to eq('0755')
    end

    it 'includes openstack-common::openrc recipe' do
      expect(chef_run).to include_recipe('openstack-common::openrc')
    end

    # Stop and disable keystone services on CMA controller
    services_to_be_disabled = %w(openstack-keystone)
    services_to_be_disabled.each do |s|
      it "disables and stops service #{s}" do
        expect(chef_run).to disable_service("#{s}")
        expect(chef_run).to stop_service("#{s}")
      end
    end
  end

  context 'controller role' do
    before do
      node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_system_role'] = 'controller'
    end
    it 'endpoints force_override attributes' do
      expect(chef_run.node['openstack']['compute']['network']['service_type']).to eq('neutron')
      expect(chef_run.node['openstack']['compute']['enabled_apis']).to eq('osapi_compute,metadata')
      expect(chef_run.node['openstack']['endpoints']['compute-api']['uri']).to eq('http://CMAcontroller:8774/v2/%(tenant_id)s')
      expect(chef_run.node['openstack']['endpoints']['network-api']['uri']).to eq('http://CMAcontroller:9696')
      expect(chef_run.node['openstack']['endpoints']['block-storage-api']['uri']).to eq('http://CMAcontroller:8776/v2/%(tenant_id)s')
      expect(chef_run.node['openstack']['endpoints']['image-api']['uri']).to eq('http://CMAcontroller:9292')
      expect(chef_run.node['openstack']['endpoints']['orchestration-api-cfn']['uri']).to eq('http://CMAcontroller:8000/v1')
      expect(chef_run.node['openstack']['endpoints']['orchestration-api']['host']).to eq('CMAcontroller')
      expect(chef_run.node['openstack']['endpoints']['orchestration-api']['scheme']).to eq('http')
      expect(chef_run.node['openstack']['endpoints']['orchestration-api']['port']).to eq('8004')
      expect(chef_run.node['openstack']['endpoints']['orchestration-api']['path']).to eq('/v1/%(tenant_id)s')
    end

    it 'includes openstack-identity::registration recipe' do
      expect(chef_run).to include_recipe('openstack-identity::registration')
    end
    it 'includes openstack-compute::identity_registration recipe' do
      expect(chef_run).to include_recipe('openstack-compute::identity_registration')
    end
    it 'includes openstack-network::identity_registration recipe' do
      expect(chef_run).to include_recipe('openstack-network::identity_registration')
    end
    it 'includes openstack-block-storage::identity_registration recipe' do
      expect(chef_run).to include_recipe('openstack-block-storage::identity_registration')
    end
    it 'includes openstack-image::identity_registration recipe' do
      expect(chef_run).to include_recipe('openstack-image::identity_registration')
    end
    it 'includes openstack-orchestration::identity_registration recipe' do
      expect(chef_run).to include_recipe('openstack-orchestration::identity_registration')
    end

    # test cinder v1 service and endpoint create
    it 'registers cinder volume service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register Cinder Volume Service'
      ).with(
        auth_uri: 'http://keystoneip:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'cinder',
        service_type: 'volume',
        service_description: 'Cinder Volume Service',
        endpoint_region: 'ZController',
        endpoint_adminurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s',
        endpoint_internalurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s',
        endpoint_publicurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s'
      )
    end

    it 'registers volume endpoint' do
      expect(chef_run).to create_endpoint_openstack_identity_register(
        'Register Cinder Volume Endpoint'
      ).with(
        auth_uri: 'http://keystoneip:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'cinder',
        service_type: 'volume',
        service_description: 'Cinder Volume Service',
        endpoint_region: 'ZController',
        endpoint_adminurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s',
        endpoint_internalurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s',
        endpoint_publicurl: 'http://CMAcontroller:8776/v1/%(tenant_id)s'
      )
    end

    nova_services = %w(openstack-nova-api openstack-nova-compute openstack-nova-conductor openstack-nova-scheduler openstack-nova-cert openstack-nova-console openstack-nova-consoleauth openstack-nova-xvpvncproxy openstack-nova-novncproxy)
    neutron_services = %w(neutron-server neutron-zvm-agent)
    cinder_services = %w(openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume openstack-cinder-backup)
    glance_services = %w(openstack-glance-api openstack-glance-registry)
    heat_services = %w(openstack-heat-api openstack-heat-api-cfn openstack-heat-api-cloudwatch openstack-heat-engine)
    ceilometer_services = %w(openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-alarm-notifier openstack-ceilometer-alarm-evaluator openstack-ceilometer-polling)

    describe 'nova.conf' do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'nova',
          group: 'nova',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(/^password = neutron-pass$/)
        expect(chef_run).to render_file(file.name).with_content(/^project_name = service$/)
        expect(chef_run).to render_file(file.name).with_content(/^username = neutron$/)
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^password = nova-pass$/)
      end

      nova_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'neutron.conf' do
      let(:file) { chef_run.template('/etc/neutron/neutron.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'neutron',
          group: 'neutron',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(/^password = nova-pass$/)
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^region_name = ZController$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = neutron-pass$/)
      end

      neutron_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'cinder',
          group: 'cinder',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^username = cinder$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = cinder-pass$/)
      end

      cinder_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'glance-api.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-api.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'glance',
          group: 'glance',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^username = glance$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = glance-pass$/)
      end

      glance_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'glance-registry.conf' do
      let(:file) { chef_run.template('/etc/glance/glance-registry.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'glance',
          group: 'glance',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^username = glance$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = glance-pass$/)
      end

      glance_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'heat.conf' do
      let(:file) { chef_run.template('/etc/heat/heat.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'heat',
          group: 'heat',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(/^region_name_for_services = ZController$/)
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_uri = http://keystoneip:5000$))
        expect(chef_run).to render_file(file.name).with_content(/^username = heat$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = heat-pass$/)
      end

      heat_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'ceilometer.conf' do
      let(:file) { chef_run.template('/etc/ceilometer/ceilometer.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(%r(^connection = database_connection$))
        expect(chef_run).to render_file(file.name).with_content(%r(^password = ceilometer-pass$))
        expect(chef_run).to render_file(file.name).with_content(%r(^rabbit_host = CMAcontroller$))
        expect(chef_run).to render_file(file.name).with_content(%r(^zvm_host = zvm_host$))
        expect(chef_run).to render_file(file.name).with_content(%r(^polling_namespaces = compute, central$))
      end

      ceilometer_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end
  end

  context 'compute role' do
    before do
      node.set['ibm-openstack']['zvm-appliance']['unchangeable-confs']['openstack_system_role'] = 'compute'
    end
    nova_services = %w(openstack-nova-compute)
    neutron_services = %w(neutron-zvm-agent)
    ceilometer_services = %w(openstack-ceilometer-polling)

    describe 'nova.conf' do
      let(:file) { chef_run.template('/etc/nova/nova.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'nova',
          group: 'nova',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(/^password = neutron-pass$/)
        expect(chef_run).to render_file(file.name).with_content(/^project_name = service$/)
        expect(chef_run).to render_file(file.name).with_content(/^username = neutron$/)
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^password = nova-pass$/)
      end

      nova_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'neutron.conf' do
      let(:file) { chef_run.template('/etc/neutron/neutron.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'neutron',
          group: 'neutron',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(/^password = nova-pass$/)
        expect(chef_run).to render_file(file.name).with_content(%r(^auth_url = http://keystoneip:5000/v2.0$))
        expect(chef_run).to render_file(file.name).with_content(/^region_name = ZController$/)
        expect(chef_run).to render_file(file.name).with_content(/^password = neutron-pass$/)
      end

      neutron_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end

    describe 'ceilometer.conf' do
      let(:file) { chef_run.template('/etc/ceilometer/ceilometer.conf') }

      it 'creates the file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'ceilometer',
          group: 'ceilometer',
          mode: 0640
        )
      end

      it 'contains line' do
        expect(chef_run).to render_file(file.name).with_content(%r(^connection = database_connection$))
        expect(chef_run).to render_file(file.name).with_content(%r(^password = ceilometer-pass$))
        expect(chef_run).to render_file(file.name).with_content(%r(^rabbit_host = CMAcontroller$))
        expect(chef_run).to render_file(file.name).with_content(%r(^zvm_host = zvm_host$))
        expect(chef_run).to render_file(file.name).with_content(%r(^polling_namespaces = compute$))
      end

      ceilometer_services.each do |s|
        it "restart service #{s}" do
          expect(file).to notify("service[#{s}]").to(:restart).delayed
        end
      end
    end
  end
end
