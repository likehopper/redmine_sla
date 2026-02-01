# frozen_string_literal: true

# File: redmine_sla/Gemfile
# Purpose:
#   Declare Ruby gem dependencies required by the Redmine SLA plugin.
#   These gems must be installed in the Redmine environment in order for
#   the plugin features to operate correctly (nested forms, time parsing).

# Provides nested form fields used in SLA configuration screens
gem "nested_form"

# Natural language time parsing (e.g. "5 minutes", "2 hours")
gem "chronic"

# Duration parsing and formatting used for SLA time representation
gem "chronic_duration"

# Prevent Ruby 3.5 deprecation warnings (ostruct removed from default gems)
gem 'ostruct', require: false
