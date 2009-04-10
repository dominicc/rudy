#!/usr/bin/ruby

# Tryout - New Rudy::MetaData::Disk API
#

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
%w{drydock caesars rye}.each { |dir| $: << File.join(File.dirname(__FILE__), '..', '..', dir, 'lib') }

require 'rudy'
require 'tryouts'
include Tryouts


disk1 = Rudy::Disk.new
disk1.zone = 'poop'
disk1.save
disk2 = Rudy::Disks.get("disk-poop-stage-app-01-")

p disk1
p disk2
puts disk2 == disk1
puts disk2.destroy

#puts disk1.to_select
#p disk1.to_query(nil, [:path])
#p Rudy::Disks.query( "['rtype'='disk']")

__END__
group = Rudy::Groups.new
inst = Rudy::Instances.new
