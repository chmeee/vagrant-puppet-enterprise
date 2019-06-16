# vagrant-puppet-enterprise

Launch a Puppet Enterprise vagrant environment for learning/testing

## Requirements

You need vagrant (self evident).

This Vagrantfile assumes the vagrant-libvirt plugin.

    vagrant plugin install vagrant-libvirt
    
But you can personalize the Vagrantfile for virtualbox as well if you want to use it.

You also need the vagrant-hostmanager plugin installed so that every `/etc/hosts` file is updated and each node can resolve the other's domain names.

    vagrant plugin install vagrant-hostmanager

## Usage

To use it, add your images to LINNODES and WINNODES and run:

    vagrant up --no-parallel --provider libvirt 

You can substitute the `--provider` option with the environment variable `$VAGRANT_DEFAULT_PROVIDER`.

For each image, a node will be spawn and the puppet agent will be installed.

Additionally, there are a Puppet server node and a util node with gitea.

## Notes

I couldn't find any libvirt windows vagrant image in the [Vagrant cloud](https://app.vagrantup.com/boxes/search) so I took the virtualbox image and convert it to libvirt using the vagrant-mutate plugin.

But I see that now there are a lot of them. You can use [one of these](https://app.vagrantup.com/boxes/search?provider=libvirt&q=windows&sort=downloads&utf8=✓).
