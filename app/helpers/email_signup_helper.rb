module EmailSignupHelper
  def email_signup_path(atom_feed_url)
    if EmailSignupPagesFinder.exists_for_atom_feed?(atom_feed_url)
      organisation_email_signup_information_path_from_atom_feed(atom_feed_url)
    else
      new_email_signups_path(email_signup: {feed: atom_feed_url})
    end
  end

private

  def organisation_email_signup_information_path_from_atom_feed(atom_feed_url)
    organisation_email_signup_information_path extract_slug_from_atom_feed(atom_feed_url)
  end

  def extract_slug_from_atom_feed(atom_feed_url)
    /\/([\w-]+).atom$/.match(atom_feed_url)[1]
  end
end
