# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string(255)
#  user_id          :integer
#  body             :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  tagged_users     :text
#

class Comment < ActiveRecord::Base
  attr_accessible :body, :commentable_id, :commentable_type, :user_id, :tagged_users

  belongs_to :commentable, polymorphic: true
  belongs_to :user

  serialize :tagged_users

  validates_presence_of :body

  def tagged_users=(raw)
    value = if raw.is_a?(String)
      ids = raw.split(',')
      users = User.where(id: ids)
      hash = {}
      users.each do |user|
        hash.update(user.id => {user_id: user.id, full_name: user.full_name})
        Activity.for_tagged_in_comment_to(user.id, self.user_id)
      end
      hash
    else
      raw
    end

    write_attribute(:tagged_users, value)
  end

  def to_builder
    bool_errors = self.errors.present?
    Jbuilder.new do |json|
      json.data do |data|
        data.comment do |comment|
          comment.body self.body
          comment.post_id self.commentable_id
          comment.commented_at self.created_at.to_i
          comment.tagged_users self.tagged_users
          comment.set! :user do
            comment.set! :user_id, self.user_id
            comment.set! :full_name, self.user.full_name
            comment.set! :profile_picture_url, self.user.profile_picture_url
          end
        end
        
        if bool_errors
          data.errors self.errors.full_messages
        end
      end
      json.success !bool_errors
    end
  end
end
