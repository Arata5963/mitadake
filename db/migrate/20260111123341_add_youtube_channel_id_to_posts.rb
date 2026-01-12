class AddYoutubeChannelIdToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :youtube_channel_id, :string
  end
end
