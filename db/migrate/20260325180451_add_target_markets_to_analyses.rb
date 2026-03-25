class AddTargetMarketsToAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :analyses, :target_markets, :text
  end
end
