# lib/tasks/data_cleanup.rake
namespace :data do
  desc "本番環境の全データを削除（ユーザー、投稿、アクションプラン全て）"
  task clear_all: :environment do
    puts "全データを削除します..."
    
    # 依存関係の順番で削除
    EntryLike.delete_all
    puts "- EntryLike: 削除完了"
    
    Achievement.delete_all
    puts "- Achievement: 削除完了"
    
    PostEntry.delete_all
    puts "- PostEntry: 削除完了"
    
    Post.delete_all
    puts "- Post: 削除完了"
    
    User.delete_all
    puts "- User: 削除完了"
    
    puts "全データの削除が完了しました"
  end
end
