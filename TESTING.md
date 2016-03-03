Testing the Cookbook

This cookbook uses chefdk and berkshelf to isolate dependencies. Make sure you have chefdk and the header files for gecode installed before continuing. Make sure that you're using gecode version 3.
More info: https://github.com/openstack/cookbook-openstack-common/blob/master/TESTING.md
For more detailed information on what needs to be installed, you can have a quick look into the https://raw.githubusercontent.com/openstack/cookbook-openstack-common/master/bootstrap.sh, which does install all the needed things to get going on ubuntu trusty. The tests defined in the Rakefile include lint, style and unit. For integration testing please refere to the openstack-chef-repo.

We have three test suites which you can run either, individually (there are three rake tasks):

$ chef exec rake lint
$ chef exec rake style
$ chef exec rake unit

or altogether:

$ chef exec rake

The rake tasks will take care of installing the needed cookbooks with berkshelf.
Rubocop

Rubocop is a static Ruby code analyzer, based on the community Ruby style guide. We are attempting to adhere to this where applicable, slowly cleaning up the cookbooks until we can turn on Rubocop for gating the commits.
Foodcritic

Foodcritic is a lint tool for Chef cookbooks. We ignore the following rules:

    FC003 These cookbooks are not intended for Chef Solo.
    FC023 Prefer conditional attributes.

Chefspec

ChefSpec is a unit testing framework for testing Chef cookbooks. ChefSpec makes it easy to write examples and get fast feedback on cookbook changes without the need for virtual machines or cloud servers.
