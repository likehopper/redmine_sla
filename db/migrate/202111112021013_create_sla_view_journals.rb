class CreateSlaViewJournals < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        execute File.read(File.expand_path('../../sql_functions/sla_get_date.sql', __FILE__))
        say "Created function sla_get_date"

        execute File.read(File.expand_path('../../sql_views/sla_view_journals.sql', __FILE__))
        say "Created view sla_view_journal"

      end

      dir.down do

        execute "DROP VIEW IF EXISTS public.sla_view_journals CASCADE ;"
        say "Dropped view sla_view_journals"

        execute "DROP FUNCTION IF EXISTS public.sla_get_date CASCADE ;"
        say "Dropped function sla_get_date"
        
      end
      
    end
    
  end

end
