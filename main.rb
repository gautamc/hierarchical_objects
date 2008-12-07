#!/usr/local/bin/ruby
require 'rubygems'

require 'boilerplate'
require 'migrations'
require 'models'

# run the migrations
CreateTreeEncoding.down
CreateTreeEncoding.up

CreateHierarchicalObjects.down
CreateHierarchicalObjects.up
# done running the migrations

root = HierarchicalObject.new
root.id = 1
root.save

nid = 2
for i in 1 .. 1
  node = HierarchicalObject.new
  node.id = nid
  node.parent_id = 1
  node.save
  for j in 1 .. 20
    node = HierarchicalObject.new
    node.id = nid+j
    node.parent_id = (i+j)-1
    node.save
  end
  nid = nid+11
end

node = HierarchicalObject.new
node.id = 159
node.parent_id = 10
node.save

node = HierarchicalObject.find( 11 )
node.parent_id = 8
node.save

node = HierarchicalObject.new
node.id = 26
node.parent_id = 11
node.save

node = HierarchicalObject.new
node.id = 420
node.parent_id = 11
node.save

node = HierarchicalObject.new
node.id = 23
node.parent_id = 6
node.save

node = HierarchicalObject.new
node.id = 421
node.parent_id = 1000
node.save

#node = HierarchicalObject.find( 7 )
#node.parent_id = 6
#node.save

node = HierarchicalObject.find( 11 )
node.parent_id = 9
node.save

node.subtree.each {
  |obj|
  print obj.sortkey, " : ", obj.id, " : ", obj.parent_id, "\n"
}

root_node = HierarchicalObject.root
puts root_node.id
puts root_node.sortkey
puts root_node.parent_id

root_node.subtree.each {
  |obj|
  print obj.sortkey, " : ", obj.id, " : ", obj.parent_id, "\n"
}

#HierarchicalObject.destroy( 11 )

node = HierarchicalObject.find( 21 )
node.ancestors.each {
  |obj|
  print obj.sortkey, " : ", obj.id, " : ", obj.parent_id, "\n"
}
