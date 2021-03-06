# This can be used to force publish all documents for a particular organisation
class ForcePublisher
  attr_reader :failures, :successes, :editions_to_publish

  def initialize(editions_to_publish)
    @failures = []
    @successes = []
    @editions_to_publish = editions_to_publish
  end

  class Worker
    def user
      @user ||= User.find_by!(name: "GDS Inside Government Team")
    end

    def force_publish!(editions, reporter)
      editions.each do |edition|
        if edition.nil?
          reporter.failure(edition, 'Edition is nil')
        else
          publisher = Whitehall.edition_services.force_publisher(edition, user: user, remark: 'Bulk force published after import')
          if !publisher.can_perform?
            reporter.failure(edition, publisher.failure_reason)
          else
            begin
              Edition::AuditTrail.acting_as(user) do
                publisher.perform!
              end
              reporter.success(edition)
            rescue => e
              reporter.failure(edition, e)
            end
          end
        end
      end
    end
  end

  def force_publish!(limit = nil)
    suppress_logging!
    editions = limit ? @editions_to_publish.take(limit) : @editions_to_publish
    Worker.new.force_publish!(editions, self)
  end

  def suppress_logging!
    ActiveRecord::Base.logger = Logger.new(Rails.root.join("log/force_publish.log"))
  end

  def success(edition)
    puts "OK : #{edition.id}: https://www.gov.uk#{Whitehall.url_maker.public_document_path(edition)}"
    @successes << edition
  end

  def failure(edition, reason)
    puts "ERR: #{edition.id unless edition.nil?}: #{reason.to_s}"
    @failures << [edition, reason]
  end

  def self.for_organisation(acronym, options = {})
    organisation = Organisation.find_by!(acronym: acronym)
    excluded_types = (options[:excluded_types] ? [*options[:excluded_types]] : []).map do |type_name|
      Object.const_get(type_name)
    end
    editions_to_publish = organisation.editions
      .draft
      .latest_edition
      .where("exists (select * from document_sources ds where ds.document_id=editions.document_id)")
    if excluded_types.any?
      editions_to_publish = editions_to_publish.where("type not in (?)", excluded_types.map(&:name))
    end
    ForcePublisher.new(editions_to_publish)
   end
end
