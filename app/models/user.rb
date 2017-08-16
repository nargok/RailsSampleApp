class User < ApplicationRecord
  has_many :microposts, dependent: :destroy # ユーザーが消されたら紐付く投稿も消える
  has_many :active_relationships, class_name: "Relationship",
           foreign_key: "follower_id",
           dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
           foreign_key: "followed_id",
           dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed # フォローしているユーザ（followed) をfollowingとして扱う
  has_many :followers, through: :passive_relationships, source: :follower # フォローされているユーザ（follower) をfollowersとして扱う
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX},
            uniqueness: { case_sensitive: false } # メールアドレスの大文字小文字を区別しない
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST:
                BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def self.digest(string)
    const = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST:
                BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  class << self
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST:
                  BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    # remember_digestがnilの場合にfalseを返す　2つのブラウザを使っていて片方でログアウトした場合
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # アカウントを有効にする
  def activate
    # update_attribute(:activated, true)
    # update_attribute(:activated_at, Time.zone.now)
    # update_attributeを2回呼ぶ（DB更新が2回）からDB更新1回に変更
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # ユーザーのステータスフィードを返す
  # フォローしているユーザーと、自分のマイクロポストを取得する
  # following_idsはhas_many throughを定義すると使えるようになるメソッド
  # User.first.following.map(&:id)と同じ動きをする　フォローしているIDの配列をつくる
  def feed
    # 大量のフィードがあってもDB問い合わせによる処理が遅くならないようにチューニングする
    # Micropost.where("user_id IN (?) OR user_id = ?", following_ids, id)
    # サブセレクトを設定
    following_ids = "SELECT followed_id FROM relationships
                WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end

  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end

  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  private

  def downcase_email
    self.email.downcase! # self.email = email.downcaseと同じ意味
  end

  # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

end
