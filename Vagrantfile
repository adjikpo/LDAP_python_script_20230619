# -*- mode: ruby -*-
# vi: set ft=ruby sw=2 st=2 et :
# frozen_string_literal: true

Vagrant.configure("2") do |config|
  config.vm.box = 'debian/buster64'
    config.vm.box_check_update = false

    config.vm.provider 'virtualbox' do |vb|
        vb.memory = '2000'
        vb.cpus = 2
        vb.gui = false
    end

    # s1.ldap server (x1)
    config.vm.define 'control' do |server|
        server.vm.hostname = 'control'
        server.vm.network 'private_network', ip: '192.168.50.250', name: 'VboxLdap1'
    end
    config.vm.provision 'shell', path: 'provision.sh'
end
