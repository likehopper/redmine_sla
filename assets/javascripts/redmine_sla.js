/*
 * File: redmine_sla/assets/javascripts/redmine_sla.js
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Redmine SLA - service level agreement plugin
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).before(content.replace(regexp, new_id));
}

document.addEventListener('DOMContentLoaded', function() {
  var markers = {
    level: '◇',
    spent: '◎',
    term: '◷',
    remain: '\u231B\uFE0E',
    respect: '☷'
  };

  document.querySelectorAll('#available_c option, #selected_c option').forEach(function(option) {
    var match = option.value.match(/^get_sla_(spent|term|remain|respect)_\d+$/);
    var role = option.value === 'get_sla_level' || option.value === 'sla_level' ? 'level' :
      option.value === 'spent' ? 'spent' : match && match[1];

    if (role && !option.dataset.slaMarker) {
      option.text = markers[role] + ' ' + option.text;
      option.dataset.slaMarker = role;
    }
  });
});
