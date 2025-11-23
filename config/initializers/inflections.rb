# File: redmine_sla/config/initializers/inflections.rb
# Purpose:
#   Define custom inflection rules for the Redmine SLA plugin.
#   In particular, ensure that the singular/plural forms of "sla_cache"
#   are handled correctly by ActiveRecord (e.g. model ↔ table names).

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'sla_cache', 'sla_caches'
end