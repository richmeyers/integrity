require 'dm-migrations/migration_runner'

DataMapper.migration '2011-10-14T20:09:23Z', :change_commit_message_to_text do
  up do
    modify_table :commits do
      change_column :message, String
    end
  end
  
  down do
    # nothing
  end
end
