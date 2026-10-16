# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# File: redmine_sla/test/documentation/modules/00_roles_module.rb
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

# Screenshots for doc/SETTINGS.md (Roles and permissions).
# Roles come from the core fixtures, so they are taken once, with example-01.
module RolesDocumentationTest
  def test_00_roles
    return unless @current_suite == 'example-01'

    log_user('admin', 'admin')

    # Permissions report, reduced to the SLA module rows
    visit '/roles/permissions'
    assert_selector 'tr.permission-view_sla'
    page.execute_script(<<~JS)
      var filters = document.getElementById('filters');
      if (filters) filters.style.display = 'none';
      var keep = ['permission-view_sla', 'permission-manage_sla'];
      var rows = document.querySelectorAll('table.permissions tbody tr');
      rows.forEach(function(tr, i) {
        var next = rows[i + 1];
        var isSlaGroup = tr.classList.contains('group') && next && next.classList.contains('permission-view_sla');
        if (!isSlaGroup && !keep.some(function(c) { return tr.classList.contains(c); })) tr.style.display = 'none';
      });
      document.querySelectorAll('#content p.buttons, #content p.other-formats').forEach(function(el) { el.style.display = 'none'; });
    JS
    take_doc_screenshot('01-01-roles-permissions.png', folder: 'settings')

    # Role edit form, reduced to the SLA module fieldset
    role = Role.find_by!(name: 'Manager')
    visit "/roles/#{role.id}/edit"
    assert_selector '#module_sla'
    page.execute_script(<<~JS)
      var content = document.getElementById('content');
      Array.from(content.querySelectorAll('form > *')).forEach(function(el) {
        if (el.id !== 'permissions' && el.tagName !== 'H3') el.style.display = 'none';
      });
      content.querySelectorAll('h3').forEach(function(h) {
        if (h.nextElementSibling && h.nextElementSibling.id !== 'permissions') h.style.display = 'none';
      });
      document.querySelectorAll('#permissions > *').forEach(function(el) {
        if (el.id !== 'module_sla') el.style.display = 'none';
      });
    JS
    take_doc_screenshot('01-02-role-edit-sla.png', folder: 'settings')
  end
end
