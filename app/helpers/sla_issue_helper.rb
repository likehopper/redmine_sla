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

  def sla_display( percent, is_closed, type="bar" )

    label = percent.to_s.concat("%")

    # CCS colors used for an active issue depending on progress [ 0% < 80% < 100% ] = [ good < warn < fail ]
    case percent
      when 0..79
        css_color = 'good'
      when 80..100
        css_color = 'warn'
      else # > 100
        css_color = 'fail'
        label = '>100%'
        percent = 100
    end # case purcent
      
    # If issue is closed, then pie are shown in dark shades according to the respect of the sla
    if is_closed
      if ( label == '>100%' )
        css_color = 'doneko'
      else
        css_color = 'doneok'
      end
    end

    if ( type == "pie" )
      css_form = "sla_pie"
    else
      css_form = "sla_bar"
    end

    css_class = 'sla_display '+css_color+' '+css_form

    return content_tag('div', label, :label =>  label, :class => css_class, :style => "--p:"+percent.to_s).html_safe

  end


end
