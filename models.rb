class TreeEncoding < ActiveRecord::Base
end

class HierarchicalObject < ActiveRecord::Base
  before_save lambda {
    |record|
    
    # if root object(empty sortkey) doesn't already exist
    if record.parent_id.nil?
      record.sortkey = ""
      return true
    end
    
    begin
      parent_rec = find( record.parent_id )
      prev_sortkey = record.sortkey
      ## Note1: COMMENTING OUT BASE159 ENCODING UNTIL I ADDRESS ISSUE RELATED TO
      ## LEXICAL ORDERING OF THE CHARACTERS AND THE ORDERING OF THE NODES
      #base159_id = toBase159( tomvgID( record.id ) )
      base159_id = tomvgID( record.id )
      record.sortkey = parent_rec.sortkey + "/" + base159_id.to_s
      unless ( prev_sortkey.nil? )
        # currently, we don't allow moving a object in such a way that it becomes
        # a child object within the subtree rooted under it
        unless ( record.sortkey.match( "^#{prev_sortkey}/.+" ).nil? )
          return false
        end
        
        # find the subtree in record, not including record
        transaction do
          descendents = find(:all, :conditions => ["sortkey like ?", prev_sortkey+"/%"])
          if ( descendents.length > 0 )
            #update the sortkeys in the subtree
            update_all("sortkey=replace(sortkey, '" + prev_sortkey.gsub( /\/[^\/]+$/, '/') + "'," + "'" + parent_rec.sortkey+"/" + "')", ["sortkey like ?", prev_sortkey+"/%"])
          end
        end
      end
      return true
    rescue ActiveRecord::RecordNotFound
      return false
    end
  }
  
  # before deleteing an object, update sortkeys of all its child objects
  before_destroy lambda {
    |record|
    update_all("sortkey=replace(sortkey, '" + record.sortkey+"/" + "'," + "'" + record.sortkey.gsub( /\/[^\/]+$/, '/') + "')", ["sortkey like ?", record.sortkey+"/%"])
    return true
  }
  
  def self.root
    find( :first, :conditions => { :sortkey => "" } )
  end
  
  # depth with respect to root object
  def absdepth
    sortkey.count("/") unless sortkey.nil?
  end
  
  def subtree
    self.class.base_class.find(
      :all,
      :conditions => ["sortkey like ?", sortkey+"%"],
      :order => "sortkey"
    )
  end
  
  def ancestors
    self.class.base_class.find(
      :all,
      :conditions => ["locate(sortkey, ?) != 0", sortkey],
      :order => "sortkey"
    )
  end
  
  protected
  
  @@enc_map = {}
  
  def self.toBase159(base10)
    if ( @@enc_map.keys.length == 0 )
      @@enc_map = TreeEncoding.find( :all ).inject({}) {
        |kvp, obj| kvp.merge! obj.deci => obj.code
      }
    end
    
    base159 = ""
    while( base10 != 0 )
      base159 = (@@enc_map[base10 % 159]).to_s + base159.to_s
      base10 = base10 / 159
    end
    base159
  end
  
  def self.tomvgID(base10)
    base10 ||= 0
    mvgid = (base10.to_s.length - 1).to_s
    mvgid += base10.to_s
    # Refer to Note1
    #mvgid.to_i
    mvgid
  end
end
