class AddWagonProgramToAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :analyses, :wagon_program, :string
  end
end
