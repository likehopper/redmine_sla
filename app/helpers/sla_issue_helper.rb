# frozen_string_literal: true

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

module SlaIssueHelper

  include ActionView::Context
  include ActionView::Helpers::TagHelper

  def sla_bar(purcent, options={})

    width = options[:width] || '100;'
    legend = options[:legend] || ''

    fill = label = purcent
    unfill = 100 - purcent

    case purcent
    when 0..79
      css = 'inprogress'
    when 80..100
      css = 'warn'
    else # > 100
      fill = 100
      unfill = 0
      label = '>100'
      css = 'fail'
    end # case purcent
      
    if options[:done]
      if ( purcent > 100 )
        css = 'doneko'
      else
        css = 'doneok'
      end
    end

    return content_tag('table',
            content_tag('tr',
              ( fill > 0 ? content_tag('td', "#{label}%" , :style => "width: #{fill}%;", :class => css) : ''.html_safe ) +
              ( unfill > 0 ? content_tag('td', "" , :style => "width: #{unfill}%;", :class => 'todo') : ''.html_safe )
            ), :class => 'sla', :style => "width: #{width}px;").html_safe +
            content_tag('span', legend.html_safe, :class => 'pourcent').html_safe
  end

end
