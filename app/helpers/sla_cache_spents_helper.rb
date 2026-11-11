# frozen_string_literal: true
# File: redmine_sla/app/helpers/sla_cache_spents_helper.rb
# SPDX-License-Identifier: GPL-2.0-or-later

# Redmine SLA - Redmine's Plugin 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module SlaCacheSpentsHelper

  # Spents have no project route: the project context is the project_id
  # parameter. GET forms must repeat it as a hidden field, since browsers
  # drop the query string of a GET form action.
  def _sla_cache_spents_path(project, issue, *args)
    options = args.extract_options!
    sla_cache_spents_path(*args, options.merge(project_id: project&.identifier))
  end

end