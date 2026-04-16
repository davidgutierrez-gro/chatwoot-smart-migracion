class AddKanbanFieldsToLabels < ActiveRecord::Migration[7.0]
  def up
    add_column :labels, :position, :integer, default: 0, null: false
    add_column :labels, :hide_in_kanban, :boolean, default: false, null: false

    # Set initial position based on alphabetical order per account
    Label.reset_column_information
    Label.unscoped.all.group_by(&:account_id).each do |_account_id, labels|
      labels.sort_by(&:title).each_with_index do |label, index|
        label.update_column(:position, index)
      end
    end
  end

  def down
    remove_column :labels, :position
    remove_column :labels, :hide_in_kanban
  end
end
