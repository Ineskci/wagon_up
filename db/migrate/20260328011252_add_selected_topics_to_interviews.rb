class AddSelectedTopicsToInterviews < ActiveRecord::Migration[8.1]
  def change
    add_column :interviews, :selected_topics, :text
  end
end
