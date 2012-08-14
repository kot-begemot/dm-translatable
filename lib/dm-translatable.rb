require 'dm-core'
require 'i18n'

class String
  def constantize
    self.split("::").tap do |s|
      s.shift if s.first.empty?
    end.inject(Module) {|acc, val| acc.const_get(val)}
  end
end

module DataMapper
  module Is
    ###
    # In order to made the model Translatable, an additional fields should
    # should be added first to it. Here is an example of it might be implemented:
    #
    # Examples:
    #
    #   class TranslatedNews
    #     include DataMapper::Resource
    #
    #     property :id,         Serial
    #
    #     attr_accessible :title, :content
    #   end
    #
    #   class News
    #     include DataMapper::Resource
    #
    #     property :id,         Serial
    #     property :author_id,  Integer,  required: true
    #
    #     is :translatable do
    #       translatable_property  :title,    String,   required: true, unique: true
    #       translatable_property  :content,  Text,     required: true
    #       translatable_model TranslatedNews
    #       translatable_origin :origin_id
    #     end
    #
    #   end
    #
    # An example of application:
    #
    #   news = News.create :translations => [{title: "Resent News", content: "That is where the text goes", locale: "en"}]
    #   news.translations.create title: "Заголовок", content: "Содержание",locale: "ru"
    #
    #   news.content
    #   # => "That is where the text goes"
    #
    #   ::I18n.locale = "ru"
    #   news.content
    #   # => "Сюди идет текст"
    #
    #   ::I18n.locale = "de"
    #   news.content
    #   # => nil
    #
    #   ::I18n.locale = ::I18n.default_locale
    #   news.content
    #   # => "That is where the text goes"
    #
    module Translatable

      def is_translatable
        extend DataMapper::Is::Translatable::ClassMethods
        include DataMapper::Is::Translatable::InstanceMethods

        translatable_define_hash
        yield
        translatable_register
      end

      module ClassMethods

        protected

        ###
        # Fields that are translatable.
        # Those fields should be defined in the original model including all the related params.
        # Examples:
        #
        #   translatable_property  :title,    String,   required: true, unique: true
        #   translatable_property  :content,  Text
        #
        # NB! Will raise an error if there was no fields specified
        #
        def translatable_property *args
          (@translatable[:properties] ||= [])  << args
        end

        ###
        # Defines model that will be treated as translation handler.
        # Model can be defined as String, Symbol or Constant.
        # Examples:
        #
        #   translated_model TranslatedNews
        #   translated_model "TranslatedNews"
        #   translated_model :TranslatedNews
        #
        # Default: Translatable<ModelName>
        #
        def translatable_model model_name
          @translatable[:model] = translatable_model_prepared model_name
        end

        ###
        # Define the key that the translation will be used for belongs_to association,
        # to communicate with original model
        # Example:
        #
        #   translatable_origin :news
        #
        # Default: :origin
        #
        def translatable_origin origin_key
          @translatable[:origin] = translatable_origin_prepared origin_key
        end

        ###
        # Define the key that the translation will be used for belongs_to association,
        # to communicate with original model
        # Example:
        #
        #   translatable_origin :language
        #
        # Default: :locale
        #
        def translatable_locale locale_attr
          @translatable[:locale] = translatable_locale_prepared locale
        end

        ###
        # Returns Model as a constant that deals with translations
        def translatable_model_prepared model_name = nil
          model_constant = model_name
          model_constant ||= "Translatable#{self.name}"
          model_constant.to_s.constantize
        end


        def translatable_origin_prepared origin_key = nil
          origin_key || "origin"
        end

        def translatable_locale_prepared locale = nil
          locale || "locale"
        end

        ###
        # Define hash that contains all the translations
        def translatable_define_hash
          @translatable = {}
        end

        ###
        # Handles all the registring routine, defining methods,
        # properties, and everything else
        def translatable_register
          raise ArgumentError.new("At least one property should be defined") if [nil, []].include?(@translatable[:properties])
          [:model,:origin,:locale].each { |hash_key| @translatable[hash_key] ||= send "translatable_#{hash_key}_prepared" }

          translatable_register_properties_for_origin
          translatable_register_properties_for_translatable
        end

        ###
        # Handle the routine to define all th required stuff on the original maodel
        def translatable_register_properties_for_origin
          has Infinity, :translations, @translatable[:model].name, :child_key => [ :"#{@translatable[:origin]}_id" ]

          @translatable[:properties].each do |p|
            self.module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{p.first}
                current_translation && current_translation.#{p.first}
              end
            RUBY
          end
        end

        def translatable_register_properties_for_translatable
          @translatable[:properties].each do |p|
            @translatable[:model].__send__(:property, *p)
          end

          @translatable[:model].module_eval <<-RUBY, __FILE__, __LINE__ + 1
            property :#{@translatable[:locale]}, String, :required => true
            property :#{@translatable[:origin]}_id, String, :required => true

            belongs_to :#{@translatable[:origin]}, "#{self.name}"

            before :valid? do
              # Small hack to go around form submition problem
              # Without it it whould complai ther the original_id should be type of Integer
              self.__send__("#{@translatable[:origin]}_id=", nil) if self.__send__("#{@translatable[:origin]}_id") == ''
            end
          RUBY
        end
      end

      module InstanceMethods

        protected

        def translatable_locale_changed?
          @translatable_locale.to_s != ::I18n.locale.to_s
        end

        def current_translation
          if translatable_locale_changed?
            @translatable_locale = ::I18n.locale.to_s
            @current_translation = translations.first(:locale => @translatable_locale)
          end
          @current_translation
        end
      end
    end
  end
end

DataMapper::Model.append_extensions DataMapper::Is::Translatable