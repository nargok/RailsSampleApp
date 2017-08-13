class Micropost < ApplicationRecord
  belongs_to :user
  default_scope -> { order(created_at: :desc)} # データ作成日の降順に並べる
  # mount_uploader :picture, PictureUploader # うまく動かないから一旦削除
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140}
end
