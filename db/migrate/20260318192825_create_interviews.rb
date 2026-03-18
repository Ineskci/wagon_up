class CreateInterviews < ActiveRecord::Migration[8.1]
  def change
    create_table :interviews do |t|
      t.references :role, null: false, foreign_key: true
      t.integer :overall_score
      t.text :feedback_summary
      t.string :category

      t.timestamps
    end
  end
end
