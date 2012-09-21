require "test_helper"

class OrganisationsControllerTest < ActionController::TestCase

  SUBPAGE_ACTIONS = [:about, :agencies_and_partners, :consultations, :contact_details, :management_team]

  should_be_a_public_facing_controller

  include FilterRoutesHelper

  test "shows organisation name and description" do
    organisation = create(:organisation,
      logo_formatted_name: "unformatted name",
      description: "organisation-description"
    )
    get :show, id: organisation
    assert_select ".organisation .name", text: "unformatted name"
    assert_select ".organisation .description", text: "organisation-description"
  end

  test "#show links to the chief of the defence staff" do
    chief_of_the_defence_staff = create(:military_role, chief_of_the_defence_staff: true)
    person = create(:person)
    create(:role_appointment, role: chief_of_the_defence_staff, person: person)
    organisation = create(:organisation, roles: [chief_of_the_defence_staff])

    get :show, id: organisation

    assert_select_object chief_of_the_defence_staff do
      assert_select "a[href=?]", person_path(person), text: person.name
    end
  end

  test "#show doesn't present expanded navigation for non-department organisations" do
    organisation = create(:organisation, organisation_type: create(:organisation_type, name: "Other"))
    get :show, id: organisation
    assert_select "nav" do
      refute_select "a[href=?]", announcements_path(departments: [organisation])
      refute_select "a[href=?]", publications_path(departments: [organisation])
      refute_select "a[href=?]", consultations_organisation_path(organisation)
    end
  end

  test "shows primary featured editions in ordering defined by association" do
    organisation = create(:organisation)
    news_article = create(:published_news_article)
    policy = create(:published_policy)
    create(:featured_edition_organisation, edition: news_article, organisation: organisation, ordering: 1)
    create(:featured_edition_organisation, edition: policy, organisation: organisation, ordering: 0)

    get :show, id: organisation

    assert_equal [policy, news_article], assigns(:primary_featured_editions).collect(&:model)
  end

  test "shows a maximum of 3 primary featured editions" do
    organisation = create(:organisation)
    4.times do
      edition = create(:published_edition)
      create(:featured_edition_organisation, edition: edition, organisation: organisation)
    end

    get :show, id: organisation

    assert_equal 3, assigns(:primary_featured_editions).length
  end

  test "shows a maximum of 3 secondary featured editions" do
    organisation = create(:organisation)
    7.times do
      edition = create(:published_edition)
      create(:featured_edition_organisation, edition: edition, organisation: organisation)
    end

    get :show, id: organisation

    assert_equal 3, assigns(:secondary_featured_editions).length
  end

  test "showing a live organisation renders the show template" do
    organisation = create(:organisation, govuk_status: 'live')

    get :show, id: organisation

    assert_template 'show'
  end

  test "showing a joining organisation renders the external template" do
    organisation = create(:organisation, govuk_status: 'joining')

    get :show, id: organisation

    assert_template 'external'
  end

  test "showing an exempt organisation renders the external template" do
    organisation = create(:organisation, govuk_status: 'exempt')

    get :show, id: organisation

    assert_template 'external'
  end

  test "shows a thumbnail link of the organisation site when joining" do
    organisation = create(:organisation, govuk_status: 'joining', url: 'http://example.com')

    get :show, id: organisation

    assert_select ".thumbnail" do
      assert_select "a[href=?]", organisation.url do
        assert_select "img[src$=?]", "#{organisation.slug}.png"
      end
    end
  end

  test "shows a thumbnail link of the organisation site when exempt" do
    organisation = create(:organisation, govuk_status: 'exempt', url: 'http://example.com')

    get :show, id: organisation

    assert_select ".thumbnail" do
      assert_select "a[href=?]", organisation.url do
        assert_select "img[src$=?]", "#{organisation.slug}.png"
      end
    end
  end

  test "display a secondary featured editions" do
    organisation = create(:organisation)
    # the first 3 are featured and the 4th will be our secondary featured
    3.times do
      edition = create(:published_edition)
      create(:featured_edition_organisation, edition: edition, organisation: organisation)
    end
    edition = create(:published_edition, summary: "This is the summary of the edition")
    create(:featured_edition_organisation, edition: edition, organisation: organisation)

    get :show, id: organisation
    assert_select ".secondary-featured .summary", text: edition.summary
  end

  test "should not display an empty secondary featured editions section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select ".secondary-featured"
  end

  test "shows organisation's featured news article with image" do
    featured_image = create(:edition_organisation_image_data)
    news_article = create(:published_news_article)
    organisation = create(:organisation)
    create(:featured_edition_organisation, edition: news_article, organisation: organisation, image: featured_image, alt_text: "alt-text")

    get :show, id: organisation

    assert_select_object news_article do
      assert_select ".img img[src$='#{featured_image.file.url}'][alt=?]", "alt-text"
      assert_select ".document-type", 'News article'
    end
  end

  test "should not display an empty published policies section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select "#policies"
  end

  test "should not display an empty published publications section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select "#publications"
  end

  test "should not display an empty consultations section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select "#consultations"
  end

  test "should not display the child organisations section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select "#child_organisations"
  end

  test "should not display the parent organisations section" do
    organisation = create(:organisation)
    get :show, id: organisation
    refute_select "#parent_organisations"
  end

  test "should display the organisation's topics with content" do
    topics = [0, 1, 2].map { |n| create(:topic, published_edition_count: n) }
    organisation = create(:organisation, topics: topics)
    get :show, id: organisation
    assert_select "#topics" do
      assert_select_object topics[1]
      assert_select_object topics[2]
      refute_select_object topics[0]
    end
  end

  test "should display the count of published policies with topics" do
    topic_1 = create(:topic)
    topic_2 = create(:topic)
    organisation = create(:organisation, topics: [topic_1, topic_2])
    create(:published_policy, organisations: [organisation], topics: [topic_1])
    create(:published_policy, organisations: [organisation], topics: [topic_2])
    create(:published_policy, organisations: [organisation], topics: [topic_2])

    get :show, id: organisation

    assert_select '#topics' do
      assert_select_object topic_1 do
        assert_select '.policies', text: 'Contains 1 policy'
      end
      assert_select_object topic_2 do
        assert_select '.policies', text: 'Contains 2 policies'
      end
    end
  end

  test "should display link to policies filter if there are many policies" do
    topic_1 = create(:topic)
    topic_2 = create(:topic)
    organisation = create(:organisation, topics: [topic_1, topic_2])
    create(:published_policy, organisations: [organisation], topics: [topic_1])
    create(:published_policy, organisations: [organisation], topics: [topic_2])
    create(:published_policy, organisations: [organisation], topics: [topic_2])
    create(:published_policy, organisations: [organisation], topics: [topic_1])

    get :show, id: organisation

    assert_select '#policies' do
      assert_select "a[href='#{policies_filter_path(organisation)}']"
    end
  end

  test "should not display an empty topics section" do
    organisation = create(:organisation)
    get :show, id: organisation
    assert_select "#topics", count: 0
  end

  test "should display the organisation's policies with content" do
    organisation = create(:organisation)
    policies = [0, 1, 2].map { |n| create(:published_policy, organisations: [organisation]) }
    get :show, id: organisation
    assert_select "#policies" do
      assert_select_object policies[1] do
        assert_select '.summary', text: policies[1].summary
      end
      assert_select_object policies[2] do
        assert_select '.summary', text: policies[2].summary
      end
      assert_select_object policies[0] do
        assert_select '.summary', text: policies[0].summary
      end
    end
  end

  test "should display the organisation's publications with content" do
    organisation = create(:organisation)
    publications = [0, 1, 2].map { |n| create(:published_publication, organisations: [organisation]) }
    get :show, id: organisation
    assert_select "#publications" do
      assert_select_object publications[1] do
        assert_select '.publication-date'
        assert_select '.document-type'
      end
      assert_select_object publications[2] do
        assert_select '.publication-date'
        assert_select '.document-type'
      end
      assert_select_object publications[0] do
        assert_select '.publication-date'
        assert_select '.document-type'
      end
    end
  end

  test "presents the contact details of the organisation using hcard" do
    ministerial_department = create(:organisation_type, name: "Ministerial Department")
    organisation = create(:organisation, organisation_type: ministerial_department,
      name: "Ministry of Pomp", contacts_attributes: [{
        description: "Main",
        email: "pomp@gov.uk",
        address: "1 Smashing Place, London", postcode: "LO1 8DN",
        contact_numbers_attributes: [
          { label: "Helpline", number: "02079460000" },
          { label: "Fax", number: "02079460001" }
        ]
      }]
    )
    get :contact_details, id: organisation

    assert_select ".organisation.hcard" do
      assert_select ".fn.org", "Ministry of Pomp"
      assert_select ".adr" do
        assert_select ".street-address", "1 Smashing Place, London"
        assert_select ".postal-code", "LO1 8DN"
      end
      assert_select ".tel", /02079460000/ do
        assert_select ".type", "Helpline"
      end
      assert_select ".email", /pomp@gov\.uk/ do
        assert_select ".type", "Email"
      end
    end
  end

  test "should use html line breaks when displaying the address" do
    organisation = create(:organisation, contacts_attributes: [{description: "Main", address: "Line 1\nLine 2"}])
    get :contact_details, id: organisation
    assert_select ".street-address", /Line 1/
    assert_select ".street-address", /Line 2/
    assert_select ".street-address br", count: 1
  end

  test "should link to a google map" do
    organisation = create(:organisation, contacts_attributes: [{description: "Main", latitude: 51.498772, longitude: -0.130974}])
    get :contact_details, id: organisation
    assert_select "a[href='http://maps.google.co.uk/maps?q=51.498772,-0.130974']"
  end

  test "should show published consultations associated with the organisation" do
    published_consultation = create(:published_consultation)
    draft_consultation = create(:draft_consultation)
    organisation = create(:organisation, editions: [published_consultation, draft_consultation])

    get :consultations, id: organisation

    assert_select_object(published_consultation)
    refute_select_object(draft_consultation)
  end

  test "should show consultations in order of publication date" do
    earlier_consultation = create(:published_consultation, published_at: 2.days.ago)
    later_consultation = create(:published_consultation, published_at: 1.days.ago)
    organisation = create(:organisation, editions: [earlier_consultation, later_consultation])

    get :consultations, id: organisation

    assert_equal [later_consultation, earlier_consultation], assigns(:consultations)
  end

  SUBPAGE_ACTIONS.each do |action|
    test "should show social media accounts on organisation #{action} subpage" do
      social_media_account = create(:social_media_account)
      organisation = create(:organisation, social_media_accounts: [social_media_account])
      get action, id: organisation
      assert_select ".social_media_accounts"
    end

    test "should show description on organisation #{action} subpage" do
      organisation = create(:organisation, description: "organisation-description")
      get action, id: organisation
      assert_select ".description", text: "organisation-description"
    end
  end

  test "should render the about-us content using govspeak markup" do
    organisation = create(:organisation,
      name: "organisation-name",
      about_us: "body-in-govspeak"
    )

    govspeak_transformation_fixture "body-in-govspeak" => "body-in-html" do
      get :about, id: organisation
    end

    assert_select ".body", text: "body-in-html"
  end

  test "should display corporate publications on about-us page" do
    published_corporate_publication = create(:published_corporate_publication)
    organisation = create(:organisation, editions: [
      published_corporate_publication,
    ])
    get :about, id: organisation
    assert_select_object(published_corporate_publication)
  end

  test "should display link to corporate information pages on about-us page" do
    organisation = create(:organisation)
    corporate_information_page = create(:corporate_information_page, organisation: organisation)
    get :about, id: organisation
    assert_select "a[href='#{organisation_corporate_information_page_path(organisation, corporate_information_page)}']"
  end

  test "shows ministerial roles in the specified order" do
    junior_role = create(:ministerial_role)
    senior_role = create(:ministerial_role)
    organisation = create(:organisation)
    create(:organisation_role, organisation: organisation, role: junior_role, ordering: 2)
    create(:organisation_role, organisation: organisation, role: senior_role, ordering: 1)

    get :show, id: organisation

    assert_equal [senior_role, junior_role], assigns(:ministerial_roles).collect(&:model)
  end

  test "shows links to ministers people pages" do
    minister = create(:ministerial_role)
    person = create(:person)
    create(:role_appointment, role: minister, person: person)
    organisation = create(:organisation, ministerial_roles: [minister])

    get :show, id: organisation

    assert_select_object minister do
      assert_select "a[href=?]", person_path(person), text: person.name
    end
  end

  test "shows names and roles of those ministers associated with organisation" do
    person_1 = create(:person, forename: "Fred")
    person_2 = create(:person, forename: "Bob")
    ministerial_role_1 = create(:ministerial_role, name: "Secretary of State")
    ministerial_role_2 = create(:ministerial_role, name: "Minister of State")
    create(:role_appointment, person: person_1, role: ministerial_role_1)
    create(:role_appointment, person: person_2, role: ministerial_role_2)
    organisation = create(:organisation, ministerial_roles: [ministerial_role_1, ministerial_role_2])
    minister_in_another_organisation = create(:ministerial_role)

    get :show, id: organisation

    assert_select_object(ministerial_role_1) do
      assert_select ".current-appointee a[href=#{person_path(person_1)}]", "Fred"
      assert_select "a[href=#{ministerial_role_path(ministerial_role_1)}]", text: "Secretary of State"
    end
    assert_select_object(ministerial_role_2) do
      assert_select ".current-appointee a[href=#{person_path(person_2)}]", "Bob"
      assert_select "a[href=#{ministerial_role_path(ministerial_role_2)}]", text: "Minister of State"
    end
    refute_select_object(minister_in_another_organisation)
  end

  test "shows minister role even if it is not currently fulfilled by any person" do
    minister = create(:ministerial_role, people: [])
    organisation = create(:organisation, ministerial_roles: [minister])

    get :show, id: organisation

    assert_select_object(minister)
  end

  test "should display the minister's picture if available" do
    ministerial_role = create(:ministerial_role)
    person = create(:person, image: File.open(File.join(Rails.root, 'test', 'fixtures', 'minister-of-funk.jpg')))
    create(:role_appointment, person: person, role: ministerial_role)
    organisation = create(:organisation, ministerial_roles: [ministerial_role])
    get :show, id: organisation
    assert_select "img[src*=minister-of-funk.jpg]"
  end

  test "should display a generic image if the minister doesn't have their own picture" do
    ministerial_role = create(:ministerial_role)
    person = create(:person)
    create(:role_appointment, person: person, role: ministerial_role)
    organisation = create(:organisation, ministerial_roles: [ministerial_role])
    get :show, id: organisation
    assert_select "img[src*=blank-person.png]"
  end

  test "shows leading management team members with links to person pages" do
    permanent_secretary = create(:board_member_role, permanent_secretary: true)
    person = create(:person)
    create(:role_appointment, role: permanent_secretary, person: person)
    organisation = create(:organisation, board_member_roles: [permanent_secretary])

    get :management_team, id: organisation

    assert_select permanent_secretary_board_members_selector do
      assert_select_object(permanent_secretary) do
        assert_select "a[href='#{person_path(person)}']"
      end
    end
  end

  test "should not display an empty leading management team section" do
    junior = create(:board_member_role)
    organisation = create(:organisation, board_member_roles: [junior])

    get :management_team, id: organisation

    refute_select permanent_secretary_board_members_selector
  end

  test "shows non-leading management team members with links to person pages" do
    junior = create(:board_member_role)
    person = create(:person)
    create(:role_appointment, role: junior, person: person)
    organisation = create(:organisation, board_member_roles: [junior])

    get :management_team, id: organisation

    assert_select other_board_members_selector do
      assert_select_object(junior) do
        assert_select "a[href='#{person_path(person)}']", text: person.name
      end
    end
  end

  test "should not display an empty non-leading management team section" do
    organisation = create(:organisation)

    get :management_team, id: organisation

    refute_select other_board_members_selector
  end

  test "should display all chiefs of staff" do
    chief_of_staff = create(:military_role)
    chief_of_the_defence_staff = create(:military_role, chief_of_the_defence_staff: true)
    organisation = create(:organisation, roles: [chief_of_staff, chief_of_the_defence_staff])

    get :chiefs_of_staff, id: organisation

    assert_select_object chief_of_staff
  end

  test "should link to the organisation's chiefs of staff page" do
    organisation = create(:organisation)
    role = create(:military_role, organisations: [organisation])
    role_appointment = create(:role_appointment, role: role)

    get :show, id: organisation

    assert_select 'a[href=?]', chiefs_of_staff_organisation_path(organisation)
  end

  test "should display a list of organisations" do
    organisation_1 = create(:organisation)
    organisation_2 = create(:organisation)

    get :index

    assert_select_object(organisation_1)
    assert_select_object(organisation_2)
  end

  test "index avoids n+1 selects" do
    10.times { create(:organisation) }
    queries_used = count_queries { get :index }
    assert 10 > queries_used, "Expected less than 10 queries, #{queries_used} were counted"
  end

  test "should display orgsanisations in alphabetical order" do
    organisation_c = create(:organisation, name: 'C')
    organisation_a = create(:organisation, name: 'A')
    organisation_b = create(:organisation, name: 'B')

    get :alphabetical

    assert_equal [organisation_a, organisation_b, organisation_c], assigns(:organisations)
  end

  test "should place organisation specific css class on every organisation sub page" do
    ministerial_department = create(:organisation_type, name: "Ministerial Department")
    organisation = create(:organisation, organisation_type: ministerial_department)

    [:show, :about, :consultations, :contact_details, :management_team].each do |page|
      get page, id: organisation
      assert_select "##{dom_id(organisation)}.#{organisation.slug}.ministerial-department"
    end
  end

  test "shows 4 most recently published editions associated with organisation" do
    editions = 3.times.map { |n| create(:published_policy, published_at: n.days.ago) } +
                3.times.map { |n| create(:published_publication, published_at: (3 + n).days.ago) } +
                3.times.map { |n| create(:published_consultation, published_at: (6 + n).days.ago) } +
                3.times.map { |n| create(:published_speech, published_at: (9 + n).days.ago) }

    organisation = create(:organisation, editions: editions)
    get :show, id: organisation

    assert_select "h1", "Latest"
    editions[0,4].each do |edition|
      assert_select_object edition
    end
    editions[10,2].each do |edition|
      refute_select_object edition
    end
  end

  test "should not show most recently published editions when there are none" do
    organisation = create(:organisation, editions: [])
    get :show, id: organisation

    refute_select "h1", text: "Recently updated"
  end

  test "should show list of links to social media accounts" do
    twitter = create(:social_media_service, name: "Twitter")
    flickr = create(:social_media_service, name: "Flickr")
    twitter_account = create(:social_media_account, social_media_service: twitter, url: "https://twitter.com/#!/bisgovuk")
    flickr_account = create(:social_media_account, social_media_service: flickr, url: "http://www.flickr.com/photos/bisgovuk")
    organisation = create(:organisation, social_media_accounts: [twitter_account, flickr_account])

    get :show, id: organisation

    assert_select ".social_media_accounts" do
      assert_select_object twitter_account
      assert_select_object flickr_account
    end
  end

  test "should not show list of links to social media accounts if there are none" do
    organisation = create(:organisation, social_media_accounts: [])

    get :show, id: organisation

    refute_select ".social_media_accounts"
  end

  private

  def assert_disclaimer_present(organisation)
    assert_select "#organisation_disclaimer" do
      assert_select "a[href='#{organisation.url}']"
    end
  end
end
