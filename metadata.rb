name             'openstack-zvm-external-keystone'
maintainer       'IBM Corp.'
maintainer_email 'https://github.com/zVM-Cloud'
license          'Apache 2.0'
description      'Installs/Configures external-keystone'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '12.0.1'

recipe           'openstack-zvm-external-keystone::external_keystone', 'Configure z/VM CMA to use external keystone'

supports 'redhat'

depends 'openstack-common', '>= 12.0.0'
depends 'openstack-identity', '>= 12.0.0'
depends 'openstack-compute', '>= 12.0.0'
depends 'openstack-network', '>= 12.0.0'
depends 'openstack-block-storage', '>= 12.0.0'
depends 'openstack-image', '>= 12.0.0'
depends 'openstack-orchestration', '>= 12.0.0'
depends 'openstack-telemetry', '>= 12.0.0'
