require 'active_record_like_interface'
require 'active_support/core_ext/object/blank.rb'
require 'active_support/core_ext/string/inflections.rb'

class NewsArticleType
  include ActiveRecordLikeInterface

  FORMAT_ADVICE = {
    1 => "<p>News written exclusively for GOV.UK which users need, can act on and can’t get from other sources. Avoid duplicating press releases.</p>",
    2 => "<p>Unedited press releases as sent to the media, and official statements from the organisation or a minister.</p><p>Do <em>not</em> use for: statements to Parliament. Use the “Speech” format for those.</p>",
    3 => "<p>Government statements in response to media coverage, such as rebuttals and ‘myth busters’.</p><p>Do <em>not</em> use for: statements to Parliament. Use the “Speech” format for those.</p>",
    999 => "<p>DO NOT USE. This is a legacy category for content created before sub-types existed.</p>",
    1000 => "<p>DO NOT USE. This is a holding category for content that has been imported automatically.</p>",
  }.to_json.freeze

  attr_accessor :id, :singular_name, :plural_name, :prevalence, :key

  def slug
    plural_name.downcase.gsub(/[^a-z]+/, "-")
  end

  def self.find_by_slug(slug)
    all.detect { |type| type.slug == slug }
  end

  def self.all_slugs
    all.map(&:slug).to_sentence
  end

  def self.by_prevalence
    all.group_by(&:prevalence)
  end

  def self.ordered_by_prevalence
    primary + migration
  end

  def self.primary
    by_prevalence[:primary]
  end

  def self.migration
    by_prevalence[:migration]
  end

  def search_format_types
    ['news-article-' + self.key.tr('_', ' ').parameterize]
  end

  def genus_key
    'news_article'
  end

  NewsStory = create(id: 1, key: "news_story", singular_name: "News story", plural_name: "News stories", prevalence: :primary)
  PressRelease = create(id: 2, key: "press_release", singular_name: "Press release", plural_name: "Press releases", prevalence: :primary)
  GovernmentResponse = create(id: 3, key: "government_response", singular_name: "Government response", plural_name: "Government responses", prevalence: :primary)

  # Temporary to allow migration
  Unknown                = create(id: 999, key: "announcement", singular_name: "Announcement", plural_name: "Announcements", prevalence: :migration)
  # For imported news with a blank news_article_type field
  ImportedAwaitingType   = create(id: 1000, key: "imported", singular_name: "Imported - awaiting type", plural_name: "Imported - awaiting type", prevalence: :migration)
end
