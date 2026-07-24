# frozen_string_literal: true

class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.string :long_link, null: false
      t.string :short_link, null: false
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :links, :short_link, unique: true
  end
end
