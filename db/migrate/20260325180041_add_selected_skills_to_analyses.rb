class AddSelectedSkillsToAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :analyses, :hard_skills_selected, :text
    add_column :analyses, :soft_skills_selected, :text
  end
end
