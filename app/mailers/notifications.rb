class Notifications < ActionMailer::Base
  include ActionView::RecordIdentifier
  include Admin::EditionRoutesHelper

  def fact_check_request(request, url_options)
    @fact_check_request = request
    @url_options = url_options

    from_address = no_reply_email_address
    to_address = request.email_address
    subject = "Fact checking request from #{request.requestor.name}: #{request.edition_title}"

    mail(from: from_address, to: to_address, subject: subject)
  end

  def fact_check_response(request, url_options)
    @fact_check_request = request
    @url_options = url_options
    @comment_url = admin_edition_url(request.edition, url_options.merge(anchor: dom_id(request)))

    from_address = no_reply_email_address
    to_address = request.requestor.email
    subject = "Fact check comment added by #{request.email_address}: #{request.edition_title}"

    mail(from: from_address, to: to_address, subject: subject)
  end

  def edition_published(author, edition, admin_url, public_url)
    @author = author
    @edition = edition
    @admin_url = admin_url
    @public_url = public_url
    subject = "The #{edition.format_name} '#{edition.title}' has been published"
    mail from: no_reply_email_address, to: @author.email, subject: subject
  end

  def edition_rejected(author, edition, admin_url)
    @author = author
    @edition = edition
    @admin_url = admin_url
    subject = "The #{edition.format_name} '#{edition.title}' was rejected by #{edition.rejected_by.name}"
    mail from: no_reply_email_address, to: @author.email, subject: subject
  end

  def broken_link_reports(zip_path, recipient_address)
    filename = File.basename(zip_path)
    attachments[filename] = File.read(zip_path)

    mail from: no_reply_email_address, to: recipient_address, subject: 'GOV.UK broken link reports'
  end

  def document_list(csv, recipient_address, filter_title)
    attachments['document_list.csv'] = csv

    mail from: no_reply_email_address, to: recipient_address, subject: "#{filter_title} from GOV.UK"
  end

private

  def no_reply_email_address
    name = "GOV.UK publishing"
    if GovukAdminTemplate.environment_label !~ /production/i
      name.prepend("[GOV.UK #{GovukAdminTemplate.environment_label}] ")
    end

    address = Mail::Address.new("inside-government@digital.cabinet-office.gov.uk")
    address.display_name = name
    address.format
  end
end
