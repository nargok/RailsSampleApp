class CreateMicroposts < ActiveRecord::Migration[5.0]
  def change
    create_table :microposts do |t|
      t.text :content
      t.references :user, foreign_key: true

      t.timestamps
    end
    # 作成時刻の逆順でデータを取り出すため、インデックスを付与する
    add_index :microposts, [:user_id, :created_at]
  end
end
