# frozen_string_literal: true

class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.string :long_link, null: false
      t.string :short_link, null: false
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      # No `foreign_key: true`: users live on the primary database while
      # links are sharded, and Postgres cannot enforce a cross-database FK.
      t.references :user, null: false

      t.timestamps
    end

    add_index :links, :short_link, unique: true
  end
end
