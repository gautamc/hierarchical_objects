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

describe HierarchicalObject, "when building a tree of objects" do
  
  before(:all) do
  end
  
  before(:each) do
  end
  
  it "should have empty sortkey and parent_d for root object" do
    root = HierarchicalObject.new
    root.id = 1
    saved_p = root.save
    root.sortkey.should be_empty
  end
  
  it "should not save subsequent root objects" do
    dead_root = HierarchicalObject.new
    dead_root.id = 2
    saved_p = dead_root.save
    saved_p.should be_false
  end
  
  it "should have a parent_id and sortkey for a non root object" do
    node2 = HierarchicalObject.new
    node2.id = 2
    node2.parent_id = 1
    node2.save
    node2.sortkey.should eql( "/02" )
  end
  
  it "should not allow parent_id that is not an id of an existing object" do
    node3 = HierarchicalObject.new
    node3.id = 3
    node3.parent_id = 420
    saved_p = node3.save
    saved_p.should be_false
  end
  
  it "should not allow of moving of an object into its own subtree" do
    node4 = HierarchicalObject.new
    node4.id = 4
    node4.parent_id = 2
    node4.save
    node4.sortkey.should eql( "/02/04" )

    node2 = HierarchicalObject.find( 2 )
    node2.parent_id = 4
    saved_p = node2.save
    
    saved_p.should be_false
    node2.sortkey.should eql( "/02" )
  end
  
  it "should allow of moving of an object" do
    node3 = HierarchicalObject.new
    node3.id = 3
    node3.parent_id = 1
    node3.save
    
    node4 = HierarchicalObject.find( 4 )
    node4.parent_id = 3
    saved_p = node4.save
    
    saved_p.should be_true
    node4.sortkey.should eql( "/03/04" )
  end
  
  it "should update the all descendent objects when delete an ancestor object" do
    node4 = HierarchicalObject.find( 4 )
    node4.sortkey.should eql( "/03/04" )
    HierarchicalObject.destroy( 3 )
    node4.reload
    node4.sortkey.should eql( "/04" )
  end
  
  it "should have depth" do
    treemaker_helper
    HierarchicalObject.find( 1 ).absdepth.should eql( 0 )
    HierarchicalObject.find( 2 ).absdepth.should eql( 1 )
    HierarchicalObject.find( 3 ).absdepth.should eql( 1 )
    HierarchicalObject.find( 21 ).absdepth.should eql( 10 )
  end
  
  it "should have a subtree" do
    HierarchicalObject.find( 1 ).subtree.length.should eql( 22 )
  end
  
  it "should have ancestors" do
    puts HierarchicalObject.find( 21 ).ancestors.length.should eql( 11 )
  end
  
  after(:each) do
  end
  
  after(:all) do
  end
  
  def treemaker_helper
    # delete the older objects
    HierarchicalObject.destroy( 2 )
    HierarchicalObject.destroy( 4 )
    # add the tree
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
  end
  
end
