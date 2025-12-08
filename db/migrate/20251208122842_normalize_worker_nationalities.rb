class NormalizeWorkerNationalities < ActiveRecord::Migration[8.1]
  def up
    # Convert existing nationality values to normalized format
    # 'Local' -> 'local'
    # 'Foreigner' -> 'foreigner'
    # 'Foreigner (No Passport)' -> 'foreigner_no_passport'

    reversible do |dir|
      dir.up do
        Worker.where(nationality: 'Local').update_all(nationality: 'local')
        Worker.where(nationality: 'Foreigner').update_all(nationality: 'foreigner')
        Worker.where(nationality: 'Foreigner (No Passport)').update_all(nationality: 'foreigner_no_passport')
      end

      dir.down do
        Worker.where(nationality: 'local').update_all(nationality: 'Local')
        Worker.where(nationality: 'foreigner').update_all(nationality: 'Foreigner')
        Worker.where(nationality: 'foreigner_no_passport').update_all(nationality: 'Foreigner (No Passport)')
      end
    end
  end

  def down
    # Handled by reversible block above
  end
end
