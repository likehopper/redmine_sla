class CreateSlaViewRollStatuses < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        execute File.read(File.expand_path('../../sql_views/sla_view_roll_statuses.sql', __FILE__))
        say "Created view sla_view_roll_statuses"

      end

      dir.down do

        execute "DROP VIEW IF EXISTS public.sla_view_roll_statuses CASCADE ;"
        say "Dropped view sla_view_roll_statuses"

      end
      
    end
    
  end

end
