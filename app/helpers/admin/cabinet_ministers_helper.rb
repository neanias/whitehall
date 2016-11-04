module Admin::CabinetMinistersHelper
  def ministers_role_ordering_fields(_form, cabinet_minister_roles, key)
    roles_map = cabinet_minister_roles.map do |role|
      label = role.name
      label << " (#{role.current_person.name})" if role.current_person
      content_tag(:div,
        [label_tag("#{key}[#{role.id}][ordering]", link_to(label, [:edit, :admin, role.becomes(Role)])),
         text_field_tag("#{key}[#{role.id}][ordering]", yield(role), class: "ordering")].join.html_safe, class: "well"
                 )
    end
    roles_map.join.html_safe
  end

  def organisation_ordering_fields(organisations)
    organisations_map = organisations.map do |org|
      label = org.name
      content_tag(:div,
        [
          label_tag("organisation[#{org.id}][ordering]", org.name),
          text_field_tag("organisation[#{org.id}][ordering]", org.ministerial_ordering, class: "ordering")
        ].join.html_safe,
        class: "well"
                 )
    end
    organisations_map.join.html_safe
  end
end
