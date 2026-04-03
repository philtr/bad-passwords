class CreateTokenVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :token_versions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :token_version, null: false

      t.timestamps
    end
  end
end
