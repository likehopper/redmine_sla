class CreateSlaGetDate < ActiveRecord::Migration[5.2]

  def change

    reversible do |dir|
    
      dir.up do

        execute File.read(File.expand_path('../../sql_functions/sla_get_date.sql', __FILE__))
        say "Created function sla_get_date"

      end

      dir.down do

        execute "DROP FUNCTION IF EXISTS public.sla_get_date CASCADE ;"
        say "Dropped function sla_get_date"
        
      end
      
    end
    
  end

end
