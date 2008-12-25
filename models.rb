class TreeEncoding < ActiveRecord::Base
end

class HierarchicalObject < ActiveRecord::Base
  before_save lambda {
    |record|
    
    # if root object(sortkey "/00") doesn't already exist
    if record.parent_id.nil?
      unless exists?( :sortkey => "/00" )
        record.sortkey = "/00"
        return true
      else
        return false
      end
    end
    
    begin
      parent_rec = find( record.parent_id )
      yngst_sibling_sortkey = maximum( :sortkey, :conditions => ['parent_id = ?', record.parent_id] )
      prev_sortkey = record.sortkey
      
      if ( yngst_sibling_sortkey.nil? )
        skey = toBase159( 0 )
      else
        skey = mvgid_base159_incr( yngst_sibling_sortkey.match( /[^\/]+$/ ).to_s )
      end
      record.sortkey = parent_rec.sortkey + "/" + tomvgID( skey )
      
      unless ( prev_sortkey.nil? )
        # currently, we don't allow moving a object in such a way that it becomes
        # a child object within the subtree rooted under it
        unless ( record.sortkey.match( "^#{prev_sortkey}/.+" ).nil? )
          record.sortkey = prev_sortkey
          return false
        end
        
        # update the subtree under record, not including record, based on recalculate sortkey of record
        transaction do
          if ( count(:conditions => ["sortkey like ?", prev_sortkey+"/%"]) > 0 )
            update_all("sortkey=replace(sortkey, '" + prev_sortkey + "'," + "'" + record.sortkey + "')", ["sortkey like ?", prev_sortkey+"/%"])
          end
        end
      end
      return true
    rescue ActiveRecord::RecordNotFound
      return false
    end
  }
  
  # disallow object deletion if it has child objects
  before_destroy lambda {
    |record|
    if ( count(:conditions => ["parent_id = ?", record.id] ) > 0 )
      return false
    end
    return true
  }
  
  def self.root
    find( :first, :conditions => { :sortkey => "/00" } )
  end
  
  # depth with respect to root object
  def absdepth
    sortkey.count("/")-1 unless sortkey.nil?
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
      :conditions => ["locate(sortkey, ?) = 1", sortkey],
      :order => "sortkey"
    )
  end
  
  def siblings
    self.class.base_class.find(
      :all,
      :conditions => [
        "sortkey like ? and sortkey not like ?",
        sortkey.gsub( /[^\/]+$/, '%' ),
        sortkey.gsub( /[^\/]+$/, '%/%' )
      ],
      :order => "sortkey"
    )
  end
  
  @@enc_map = {}
  @@enc_revmap = {}
  
  def self.toBase159(base10)
    if ( @@enc_map.keys.length == 0 )
      @@enc_map = TreeEncoding.find( :all ).inject({}) {
        |kvp, obj| kvp.merge! obj.deci => obj.code
      }
    end
    
    base10 ||= 0
    base159 = ""
    loop do
      base159 = (@@enc_map[base10 % 159]).to_s + base159.to_s
      base10 = base10 / 159
      break if( base10 == 0 )
    end
    base159
  end
  
  def self.mvgid_base159_incr(base159)
    if ( @@enc_revmap.keys.length == 0 )
      @@enc_revmap = TreeEncoding.find( :all ).inject({}) {
        |kvp, obj| kvp.merge! obj.code => obj.deci
      }
    end
    
    base159 ||= "0"
    b159_num = base159.split( // )
    result = []
    carry = 1
    # starting at with unit's position
    (b159_num.length-1).downto(1) {
      |pos|
      # get decimal value for base159 digit at this position
      deci = @@enc_revmap[b159_num[pos]]
      # add carry (or 1 if unit's digit of b159_num) to decimal value, convert to base159
      accum = toBase159(deci + carry).split( // )
      # get unit's digit in accum and assign at current positional place of result
      result.unshift( accum.last ) 
      # assign the decimal value of the next digit of accum as carry
      if( accum.length > 1 )
        carry = @@enc_revmap[accum[0]]
      else
        carry = 0
      end
    }
    if ( carry != 0 )
      result.unshift( carry ) 
    end
    result.to_s
  end
  
  def self.tomvgID(base159)
    base159 ||= "0"
    mvgid = (toBase159(base159.to_s.length - 1)).to_s
    mvgid += base159.to_s
    mvgid
  end
end
