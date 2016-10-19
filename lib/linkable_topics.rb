# Creates a payload for the topic (formerly specialist sector) select box.
class LinkableTopics
  def topics
    items = fetch_topics_from_publishing_api
    items = change_separator(items)
    items = select_only_subtopics(items)
    items = format_for_select_input(items)
    items = group_for_grouped_select(items)
    alphabetize_by_parent(items)
  end

private

  def fetch_topics_from_publishing_api
    Whitehall.publishing_api_v2_client.get_linkables(document_type: 'topic')
  end

  # collections-publisher uses a slash to separate the top-level topic name from
  # the second-level topic (or "subtopic"). Whitehall has historically used a colon,
  # so we'll change that here.
  def change_separator(items)
    items.map do |item|
      item['internal_name'] = item.fetch('internal_name').gsub(' / ', ': ')
      item
    end
  end

  # Documents can only be tagged to subtopics, eg. /topic/business-tax/capital-allowances,
  # but not https://www.gov.uk/topic/business-tax
  def select_only_subtopics(all_topics)
    all_topics.select { |item| item.fetch('internal_name').include?(': ') }
  end

  def format_for_select_input(items)
    items.map do |item|
      title = item.fetch('internal_name')
      title = "#{title} (draft)" if item.fetch("publication_state") == "draft"

      select_value = item.fetch('content_id')

      [title, select_value]
    end
  end

  # Grouping in a nested array will make Rails show the options in a grouped select
  def group_for_grouped_select(items)
    items.group_by { |entry| entry.first.split(': ').first }
  end

  def alphabetize_by_parent(items)
    items.sort_by(&:first)
  end
end
