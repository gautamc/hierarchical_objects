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
  
  it "should have sortkey of /00 for root object" do
    root = HierarchicalObject.new
    root.id = 1999
    saved_p = root.save
    root.sortkey.should eql( "/00" )
    root.parent_id.should be_nil
  end
  
  it "should not save subsequent root objects" do
    dead_root = HierarchicalObject.new
    dead_root.id = 2
    saved_p = dead_root.save
    saved_p.should be_false
  end
  
  it "should have a parent_id and sortkey for a non root object" do
    node2 = HierarchicalObject.new
    node2.id = 2876
    node2.parent_id = 1999
    node2.save
    node2.sortkey.should_not be_empty
  end
  
  it "should not allow parent_id that is not an id of an existing object" do
    node3 = HierarchicalObject.new
    node3.id = 3543
    node3.parent_id = 420
    saved_p = node3.save
    saved_p.should be_false
  end
  
  it "should not allow of moving of an object into its own subtree" do
    node4 = HierarchicalObject.new
    node4.id = 4396
    node4.parent_id = 2876
    node4.save
    node4.sortkey.should eql( "/00/00/00" )
    
    node2 = HierarchicalObject.find( 2876 )
    node2.parent_id = 4396
    saved_p = node2.save
    
    saved_p.should be_false
    node2.sortkey.should eql( "/00/00" )
  end
  
  it "should allow of moving of an object" do
    node3 = HierarchicalObject.new
    node3.id = 3543
    node3.parent_id = 1999
    node3.save
    
    node5 = HierarchicalObject.new
    node5.id = 5296
    node5.parent_id = 1999
    node5.save
    
    node4 = HierarchicalObject.find( 4396 )
    node4.parent_id = 1999
    saved_p = node4.save
    
    saved_p.should be_true
    node4.sortkey.should eql( "/00/03" )
    
    node4.reload
    node4.parent_id = 3543
    saved_p = node4.save
    
    saved_p.should be_true
    node4.sortkey.should eql( "/00/01/00" )
  end
  
  it "should update child objects when of moving of a parent object" do
    node6 = HierarchicalObject.new
    node6.id = 6
    node6.parent_id = 4396
    node6.save
    
    node7 = HierarchicalObject.new
    node7.id = 7
    node7.parent_id = 4396
    node7.save
    
    node8 = HierarchicalObject.new
    node8.id = 8
    node8.parent_id = 6
    node8.save
    
    node4 = HierarchicalObject.find( 4396 )
    node4.parent_id = 1999
    saved_p = node4.save
    
    saved_p.should be_true
    node4.sortkey.should eql( "/00/03" )
    
    node6.reload
    node6.sortkey.should eql( "/00/03/00" )
    
    node7.reload
    node7.sortkey.should eql( "/00/03/01" )
    
    node8.reload
    node8.sortkey.should eql( "/00/03/00/00" )
  end
  
  it "should not allow deletion of an object with descendant objects" do
    node4 = HierarchicalObject.find( 4396 )
    node4.sortkey.should eql( "/00/03" )
    destroyed_p = HierarchicalObject.destroy( 4396 )
    destroyed_p.should be_false
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
    HierarchicalObject.find( 21 ).ancestors.length.should eql( 11 )
  end
  
  it "should have sibilings" do
    HierarchicalObject.find( 3 ).siblings.length.should eql( 2 )
  end

  it "should convert decimal to base159" do
    HierarchicalObject.toBase159( 420 ).should eql( "2x" )
    HierarchicalObject.toBase159( 421 ).should eql( "2X" )
    HierarchicalObject.toBase159( 422 ).should eql( "2Y" )
  end
  
  it "should increment a mvgid coded base159 number" do
    HierarchicalObject.mvgid_base159_incr( "12x" ).should eql( HierarchicalObject.toBase159( 421 ) )
    HierarchicalObject.mvgid_base159_incr( "12X" ).should eql( HierarchicalObject.toBase159( 422 ) )
    HierarchicalObject.mvgid_base159_incr( "12Y" ).should eql( HierarchicalObject.toBase159( 423 ) )
    
    HierarchicalObject.mvgid_base159_incr(
      HierarchicalObject.tomvgID( HierarchicalObject.toBase159( 400159 ) )
    ).should eql( HierarchicalObject.toBase159( 400160 ) )
  end
  
  after(:each) do
  end
  
  after(:all) do
  end
  
  def treemaker_helper
    # delete the older objects
    HierarchicalObject.find( 1999 ).subtree.reverse.each {
      |obj|
      obj.destroy
    }
    # add the tree
    root = HierarchicalObject.new
    root.id = 1
    saved_p = root.save
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
