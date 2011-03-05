require 'active_record/associations'
require 'active_record/associations/has_many_association'
require 'active_record/associations/has_many_through_association'

ActiveRecord::Associations::HasManyAssociation.class_eval do
  def owner_id
    if @reflection.options[:primary_key]
      @owner.send(@reflection.options[:primary_key])
    else
      @owner.id
    end
  end

  def construct_sql
    case
    when @reflection.options[:finder_sql]
      @finder_sql = interpolate_sql(@reflection.options[:finder_sql])
    when @reflection.options[:as]
      @finder_sql = { ( @reflection.options[:as]+ "_id" ) => owner_id,
        ( @reflection.options[:as] + "_type" ) => @owner.class.quote_value(@owner.class.base_class.name.to_s) }
      @finder_sql.merge!( conditions ) if conditions
    else
      @finder_sql = { @reflection.primary_key_name => owner_id }
      @finder_sql.merge!( conditions ) if conditions
    end

    construct_counter_sql
  end
end

ActiveRecord::Associations::HasManyThroughAssociation.class_eval do

  def owner_id
    if @reflection.options[:primary_key]
      @owner.send(@reflection.options[:primary_key])
    else
      @owner.id
    end
  end


  def construct_conditions
    if @reflection.source_reflection.macro == :belongs_to
      source_primary_key = @reflection.source_reflection.primary_key_name
    else
      source_primary_key = @reflection.through_reflection.klass.primary_key
    end
    ids = @owner.send(@reflection.options[:through]).map{|t| t.send(source_primary_key) }
    conditions = { :id => ids }
  end


  def construct_scope
    { :create => construct_owner_attributes(@reflection),
      :find   => { :conditions  => construct_conditions,
#        :joins       => construct_joins,
        :include     => @reflection.options[:include] || @reflection.source_reflection.options[:include],
        :select      => construct_select,
        :order       => @reflection.options[:order],
        :limit       => @reflection.options[:limit],
        :readonly    => @reflection.options[:readonly],
    } }
  end

end
