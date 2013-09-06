class OrganisationType
  private
  DATA = {
    executive_office:            ["Executive office",                       "EO"],
    ministerial_department:      ["Ministerial department",                 "D"],
    non_ministerial_department:  ["Non-ministerial department",             "D"],
    executive_agency:            ["Executive agency",                       "EA"],
    executive_ndpb:              ["Executive non-departmental public body", "PB"],
    advisory_ndpb:               ["Advisory non-departmental public body",  "PB"],
    tribunal_ndpb:               ["Tribunal non-departmental public body",  "PB"],
    public_corporation:          ["Public corporation",                     "PC"],
    independent_monitoring_body: ["Independent monitoring body",            "IM"],
    adhoc_advisory_group:        ["Ad-hoc advisory group",                  "AG"],
    devolved_administration:     ["Devolved administration",                "DA"],
    sub_organisation:            ["Sub-organisation",                       "OT"],
    other:                       ["Other",                                  "OT"]
  }

  LISTING_ORDER = [
    :executive_office,
    :ministerial_department,
    :non_ministerial_department,
    :executive_agency,
    :executive_ndpb,
    :advisory_ndpb,
    :tribunal_ndpb,
    :public_corporation,
    :independent_monitoring_body,
    :adhoc_advisory_group,
    :devolved_administration,
    :sub_organisation,
    :other
  ]

  AGENCY_OR_PUBLIC_BODY_TYPES = [
    :executive_agency,
    :executive_ndpb,
    :advisory_ndpb,
    :tribunal_ndpb,
    :independent_monitoring_body,
    :adhoc_advisory_group,
    :other
  ]

  NON_DEPARTMENTAL_PUBLIC_BODY_TYPES = [
    :executive_ndpb,
    :advisory_ndpb,
    :tribunal_ndpb
  ]

  @@instances = {}

  public
  def self.get(key)
    key = key.to_sym
    raise KeyError, "#{key} is not a known organisation type." if DATA[key].nil?

    @@instances[key] ||= new(key, *DATA[key])
  end

  def self.all
    DATA.keys.map {|key| get(key)}
  end

  def self.in_listing_order
    LISTING_ORDER.map {|key| get(key)}
  end

  def self.valid_keys
    DATA.keys
  end

  def self.executive_office
    get :executive_office
  end
  def self.ministerial_department
    get :ministerial_department
  end
  def self.non_ministerial_department
    get :non_ministerial_department
  end
  def self.executive_agency
    get :executive_agency
  end
  def self.executive_ndpb
    get :executive_ndpb
  end
  def self.advisory_ndpb
    get :advisory_ndpb
  end
  def self.tribunal_ndpb
    get :tribunal_ndpb
  end
  def self.public_corporation
    get :public_corporation
  end
  def self.independent_monitoring_body
    get :independent_monitoring_body
  end
  def self.adhoc_advisory_group
    get :adhoc_advisory_group
  end
  def self.devolved_administration
    get :devolved_administration
  end
  def self.sub_organisation
    get :sub_organisation
  end
  def self.other
    get :other
  end


  attr_reader :key, :name, :analytics_prefix

  def initialize(key, name, analytics_prefix)
    @key = key
    @name = name
    @analytics_prefix = analytics_prefix
  end

  def listing_position
    LISTING_ORDER.index(key)
  end

  def executive_office?
    key == :executive_office
  end
  def ministerial_department?
    key == :ministerial_department
  end
  def non_ministerial_department?
    key == :non_ministerial_department
  end
  def executive_agency?
    key == :executive_agency
  end
  def executive_ndpb?
    key == :executive_ndpb
  end
  def advisory_ndpb?
    key == :advisory_ndpb
  end
  def tribunal_ndpb?
    key == :tribunal_ndpb
  end
  def public_corporation?
    key == :public_corporation
  end
  def independent_monitoring_body?
    key == :independent_monitoring_body
  end
  def adhoc_advisory_group?
    key == :adhoc_advisory_group
  end
  def devolved_administration?
    key == :devolved_administration
  end
  def sub_organisation?
    key == :sub_organisation
  end
  def other?
    key == :other
  end

  def is_non_departmental_public_body?
    NON_DEPARTMENTAL_PUBLIC_BODY_TYPES.include?(key)
  end

  def agency_or_public_body?
    AGENCY_OR_PUBLIC_BODY_TYPES.include? key
  end
end
