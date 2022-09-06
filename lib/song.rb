require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song
##we want to be abstract the following: table name, the column names initially
  def self.table_name
    self.to_s.downcase.pluralize
  end
##Now we want to use the method that abstracted our table name to gain accesss to the table from which we will abstract the column names
  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{self.table_name}')" #here we are getting the output in the from of a hash that contains all of the column names

    table_info = DB[:conn].execute(sql) #storing our column names to iterate over and store our column names into some empty array
    column_names = [] #we want to store our abstracted column names here

    table_info.each do |column|
      column_names << column["name"]
    end
    column_names.compact #we are getting rid of any duplicate or nil column names
  end

##Now that we have all of our abstracted column names, we want to create the attr_accessor for each one of those column names
  self.column_names.each do |col|
    attr_accessor col.to_sym 
  end

##With the attr_accessor build out we can create our dynamic intialize method
  def initialize(option = {})
    option.each do |key, value|
      self.send("#{key}=", value)
    end
  end

##With our initializer done we can now write Dyanmic ORM methods lets build out a save method that will save each instances into the table
  #we want to build out our helper functions first. A save ORM method will require us to have table name, column names (keys), and values
  #since we want our ORM to be dyanmic all of these have to be abstracted out first with helpher functions that will accomplish this for us
  #more over our orm method is a instance method not a class method and some of these things like abstracting table name and column name falls
  #in the responsibilty of our class

  #we want to abstract the table name by creating an instance method that will:
    #1. get the instance's class 
    #2. then grab its table name (this method is already created above when we had to get column values)
  def table_name_for_insert
    self.class.table_name
  end

  #Now we want to abstract the values that will be inserted:
    #1. we need to find the column names of the class of the instance 
    #2. we need to store the abstracted values into some empty array
  def values_for_insert
    values = []
    self.class.column_names.each do |col_names|
      values << "'#{send(col_names)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  ##we also need to abstract the column names of the said instance's class. We also want to get rid of our id, and let SQL handle the assignment of the id value
  def col_names_for_insert
    self.class.column.names.delete_if{|col| col =="id"}.join(", ")
  end

  ##With all 3 helper function that abstracted the table name, values, as well as the column names, we can nnow build out our save method
  def save 
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES #{values_for_insert}"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end
  ##Since the core of all ORM are abstracted out we can build out other methods lets do find by name
  def self.findByName(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end
end



