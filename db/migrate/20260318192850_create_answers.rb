class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :interview, null: false, foreign_key: true
      t.text :question
      t.text :answer
      t.text :feedback
      t.integer :score

      t.timestamps
    end
  end
end
