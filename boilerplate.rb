require 'rubygems'

dep = Gem::Dependency.new('activerecord', "=2.1.2")
activerecord_gem = Gem::SourceIndex.from_installed_gems.search(dep).first
gem 'activerecord', '=2.1.2'
require activerecord_gem.full_gem_path + '/lib/activerecord.rb'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :host     => "localhost",
  :username => "root",
  :password => "azriroot",
  :database => "test",
  :charset => "latin1"
)

# I like to have primary keys to be unsigned ints if possible (in mysql its possible)
class ActiveRecord::ConnectionAdapters::MysqlAdapter
  def native_database_types #:nodoc:
    {
      :primary_key => "int unsigned PRIMARY KEY NOT NULL",
      :int64_pk    => "bigint DEFAULT NULL auto_increment PRIMARY KEY",
      :int64       => { :name => "bigint" },
      :uint64_pk   => "bigint unsigned DEFAULT NULL auto_increment PRIMARY KEY",
      :uint64      => { :name => "bigint unsigned" },
      :uint	   => "integer unsigned",
      :usmallint   => "smallint unsigned",
      :ufloat	   => "float unsigned",
      :string      => { :name => "varchar", :limit => 255 },
      :text        => { :name => "text" },
      :integer     => { :name => "int", :limit => 11 },
      :float       => { :name => "float" },
      :decimal     => { :name => "decimal" },
      :datetime    => { :name => "datetime" },
      :timestamp   => { :name => "datetime" },
      :time        => { :name => "time" },
      :date        => { :name => "date" },
      :binary      => { :name => "blob" },
      :boolean     => { :name => "tinyint", :limit => 1 },
      :char        => "char(1)"
    }
  end
end
