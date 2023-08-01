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

  def sla_bar(purcent, is_closed)

    width = '200'

    fill = label = purcent
    unfill = 100 - purcent

    # Colors used for an active issue depending on progress [ 0% < 80% < 100% ] = [ good < warn < fail ]
    case purcent
      when 0..79
        css = 'good'
      when 80..100
        css = 'warn'
      else # > 100
        fill = 100
        unfill = 0
        label = '>100'
        css = 'fail'
    end # case purcent
      
    # If issue is closed, then bars are shown in pastel shades according to the respect of the sla
    if is_closed
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
            ), :class => 'sla', :style => "width: #{width}px;").html_safe
  
  end

  def sla_pie(purcent, is_closed )

    label = purcent.to_s.concat("%")

    # CCS colors used for an active issue depending on progress [ 0% < 80% < 100% ] = [ good < warn < fail ]
    case purcent
      when 0..79
        css = 'good'
      when 80..100
        css = 'warn'
      else # > 100
        label = '>100%'
        purcent = 100
        css = 'fail'
    end # case purcent
      
    # If issue is closed, then pie are shown in dark shades according to the respect of the sla
    if is_closed
      if ( label == '>100%' )
        css = 'doneko'
      else
        css = 'doneok'
      end
    end

    return content_tag('div', label, :class => 'pie '+css, :style => "--p:"+purcent.to_s).html_safe

  end


end
