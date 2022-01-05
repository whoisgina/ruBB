class Topic < ApplicationRecord
    has_many :posts, -> { order(created_at: :asc) }
    has_many :topic_views

    belongs_to :author, class_name: 'User', inverse_of: :created_topics

    accepts_nested_attributes_for :posts

    validates_presence_of :title, :author

    scope :by_most_recent_post, -> {
      subquery = Post.select(:id)
                     .where("posts.topic_id = topics.id")
                     .order(created_at: :desc).limit(1)
    
      joins(<<-SQL).order('posts.created_at DESC')
        LEFT JOIN posts
          ON posts.topic_id = topics.id
          AND posts.id = (#{subquery.to_sql})
      SQL
    }
end
