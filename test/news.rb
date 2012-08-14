require 'data_mapper'
require 'dm-translatable'

class Author
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
end

class TranslatableNews
  include DataMapper::Resource

  property :id, Serial

end

class News
  include DataMapper::Resource
  
  # property <name>, <type>
  property :id,         Serial
  property :author_id,  Integer
  timestamps :created_at

  belongs_to  :author

  is :translatable do
    translatable_property  :title,    String,   required: true, unique: true
    translatable_property  :content,  Text,     required: true
  end
end

DataMapper.auto_migrate!