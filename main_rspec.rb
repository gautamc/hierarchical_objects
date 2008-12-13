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
  
  it "should have empty sortkey and parent_d for root object" do
  end
  
  it "should not save subsequent root objects" do
  end
  
  it "should have a parent_id and sortkey for a non root object" do
  end
  
  it "should not allow parent_id that is not an id of an existing object" do
  end
  
  it "should not allow of moving of an object into its own subtree" do
  end
  
  it "should allow of moving of an object" do
  end
  
  it "should update the all descendent objects when delete an ancestor object" do
  end
  
  it "should have depth" do
  end
  
  it "should have a subtree" do
  end
  
  it "should have ancestors" do
  end
  
end
