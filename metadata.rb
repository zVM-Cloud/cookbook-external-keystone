# encoding: UTF-8
# =================================================================
# Licensed Materials - Property of IBM
#
# (c) Copyright IBM Corp. 2015, 2016 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
# =================================================================
name             'ibm-openstack-external-keystone'
maintainer       'IBM Corp.'
maintainer_email 'www.ibm.com'
license          'All rights reserved'
description      'Installs/Configures external-keystone'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '12.0.1'

recipe           'ibm-openstack-external-keystone::external_keystone', 'Configure z/VM CMA to use external keystone'

supports 'redhat'

depends 'openstack-common', '>= 12.0.0'
depends 'openstack-identity', '>= 12.0.0'
depends 'openstack-compute', '>= 12.0.0'
depends 'openstack-network', '>= 12.0.0'
depends 'openstack-block-storage', '>= 12.0.0'
depends 'openstack-image', '>= 12.0.0'
depends 'openstack-orchestration', '>= 12.0.0'
depends 'openstack-telemetry', '>= 12.0.0'
