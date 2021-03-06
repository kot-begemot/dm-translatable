# encoding: utf-8
require 'helper'
require 'news'

class TestDmTranslatable < Test::Unit::TestCase

  def setup
    before_setup
  end

  def teardown
    after_teardown
  end

  def test_translatable_hash_is_defined
    th = News.instance_variable_get :@translatable

    assert_kind_of Hash, th
    assert th.has_key?(:properties)
  end

  def test_translatable_hash_has_default_model
    assert_equal ::TranslatableNews, News.send(:translatable_model_prepared, 'TranslatableNews')
  end

  def test_translatable_assepts_constant_as_model
    assert_equal ::TranslatableNews, News.send(:translatable_model_prepared, ::TranslatableNews)
  end

  def test_translatable_assepts_sting_as_model
    assert_equal ::TranslatableNews, News.send(:translatable_model_prepared, "TranslatableNews")
  end

  def test_translatable_assepts_symbol_as_model
    assert_equal ::TranslatableNews, News.send(:translatable_model_prepared, :TranslatableNews)
  end

  def test_instance_respond_to_translatable_methods
    news = News.new

    assert news.respond_to?(:title), "title methods is missing for News instance"
    assert news.respond_to?(:content), "content methods is missing for News instance"
  end

  def test_translated_instance_has_translatable_methods
    news = TranslatableNews.new

    assert news.respond_to?(:title), "Title method is missing for TranslatableNews instance"
    assert news.respond_to?(:content), "Content method is missing for TranslatableNews instance"
  end

  def test_translated_instance_has_relation_to_origin
    news = TranslatableNews.new

    assert news.respond_to?(:locale), "Locale method is missing for TranslatableNews instance"
    assert news.respond_to?(:origin_id), "Origin methods is missing for TranslatableNews instance"
    assert news.respond_to?(:origin), "Origin methods is missing for TranslatableNews instance"
  end

  def test_create_without_translation
    news = News.create

    assert news.saved?
    assert_nil TranslatableNews.last
  end

  def test_create_with_translation
    news = News.create :translations => [{ :title => "Заголовок", :content => "Содержание", :locale => "ru"}]

    assert news.saved?

    t_news = TranslatableNews.last
    assert_equal news.id, t_news.origin_id.to_i
    assert_equal "Заголовок", t_news.title
    assert_equal "Содержание", t_news.content
    assert_equal "ru", t_news.locale
  end

  def test_create_with_translation_with_multiple_locales
    news = News.create :translations => [{ :title => "Заголовок", :content => "Содержание", :locale => "ru"},
      {:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]

    assert news.saved?

    t_news = TranslatableNews.first
    assert_equal news.id, t_news.origin_id.to_i
    assert_equal "Заголовок", t_news.title
    assert_equal "Содержание", t_news.content
    assert_equal "ru", t_news.locale

    t_news = TranslatableNews.last
    assert_equal news.id, t_news.origin_id.to_i
    assert_equal "Resent News", t_news.title
    assert_equal "That is where the text goes", t_news.content
    assert_equal "en", t_news.locale
  end

  def test_access_of_default_translation
    news = News.create :translations => [{:title => "Заголовок", :content => "Содержание", :locale => "ru"},
      {:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]

    assert news.saved?

    assert_equal "Resent News", news.title
    assert_equal "That is where the text goes", news.content
  end

  def test_access_of_other_translation
    news = News.create :translations => [{:title => "Заголовок", :content => "Содержание", :locale => "ru"},
      {:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]

    assert news.saved?

    ::I18n.locale = :ru
    assert_equal "Заголовок", news.title
    assert_equal "Содержание", news.content
    ::I18n.locale = ::I18n.default_locale
  end

  def test_adding_the_translation
    news = News.create :translations => [{:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]

    assert news.saved?

    t_news = news.translations.create :title => "Заголовок", :content => "Содержание",:locale => "ru"

    assert t_news.saved?
    assert t_news.saved?
  end

  def test_getting_different_translations
    news = News.create :translations => [{:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]
    
    assert news.saved?

    t_news = news.translations.create :title => "Заголовок", :content => "Содержание",:locale => "ru"
    assert t_news.saved?

    assert_equal "Resent News", news.title
    assert_equal "That is where the text goes", news.content

    ::I18n.locale = :ru

    assert_equal "Заголовок", news.title
    assert_equal "Содержание", news.content
    ::I18n.locale = ::I18n.default_locale
  end

  def test_access_unexisting_translation
    news = News.create :translations => [{:title => "Заголовок", :content => "Содержание", :locale => "ru"},
      {:title => "Resent News", :content => "That is where the text goes", :locale => "en"}]

    assert news.saved?

    ::I18n.locale = :de
    assert_nil news.title
    assert_nil news.content
    ::I18n.locale = ::I18n.default_locale
  end
end
