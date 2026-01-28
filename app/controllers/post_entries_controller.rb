# アクションプランコントローラー
# アクションプランの作成・編集・削除・達成処理を担当

class PostEntriesController < ApplicationController
  include ActionView::RecordIdentifier                                               # dom_idメソッドを使用可能に

  before_action :authenticate_user!, except: [ :show_achievement ]                   # 達成記録表示以外はログイン必須
  before_action :set_post                                                            # 親リソース（Post）を取得
  before_action :set_entry, only: [                                                  # 対象のエントリーを取得
    :edit, :update, :destroy, :achieve,                                              # 基本CRUD
    :toggle_like, :show_achievement, :update_reflection                              # いいね・達成関連
  ]
  before_action :check_entry_owner, only: [ :edit, :update, :destroy, :achieve, :update_reflection ]  # 所有者のみ

  # アクションプラン作成
  def create
    @entry = @post.post_entries.build(entry_params)                                  # エントリーを構築
    @entry.user = current_user                                                       # 作成者をセット

    if @entry.save                                                                   # 保存成功
      redirect_to @post, notice: "アクションプランを投稿しました"                    # 詳細へリダイレクト
    else                                                                             # 保存失敗
      redirect_to @post, alert: "投稿に失敗しました: #{@entry.errors.full_messages.join(', ')}"  # エラー表示
    end
  end

  # 編集画面
  def edit
    # @entry は set_entry で取得済み
  end

  # 更新
  def update
    process_thumbnail_update                                                         # サムネイル画像の更新処理
    process_video_change                                                             # 動画の変更処理

    if @entry.update(entry_params)                                                   # 更新成功
      respond_to_update_success                                                      # 成功レスポンス
    else                                                                             # 更新失敗
      respond_to_update_failure                                                      # 失敗レスポンス
    end
  end

  # 削除
  def destroy
    @entry.destroy                                                                   # エントリーを削除
    redirect_after_destroy                                                           # リダイレクト処理
  end

  # 達成処理（トグル / 感想・画像付き達成）
  def achieve
    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.html { handle_achieve_html }                                            # HTML形式
      format.json { handle_achieve_json }                                            # JSON形式
      format.turbo_stream { handle_achieve_turbo_stream }                            # Turbo Stream形式
    end
  end

  # 達成記録表示用データ取得（API）
  def show_achievement
    render json: build_achievement_json(@entry)                                      # 達成記録をJSONで返す
  end

  # 感想・画像編集（API）
  def update_reflection
    @entry.update_reflection!(                                                       # 振り返り・画像を更新
      reflection_text: params[:reflection],                                          # 振り返りテキスト
      result_image_s3_key: params[:result_image_s3_key]                              # 達成画像S3キー
    )
    render json: {                                                                   # 成功レスポンス
      success: true,
      reflection: @entry.reflection,
      result_image_url: @entry.signed_result_image_url                               # 新しい画像URLも返す
    }
  rescue StandardError => e                                                          # エラーが発生した場合
    render json: { success: false, error: e.message }, status: :unprocessable_entity  # エラーレスポンス
  end

  # いいねトグル
  def toggle_like
    existing_like = @entry.entry_likes.find_by(user: current_user)                   # 既存のいいねを検索

    if existing_like                                                                 # いいね済みの場合
      existing_like.destroy                                                          # いいね解除
    else                                                                             # 未いいねの場合
      @entry.entry_likes.create(user: current_user)                                  # いいね追加
    end

    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.html { redirect_back fallback_location: post_path(@post) }              # HTML形式
      format.turbo_stream do                                                         # Turbo Stream形式
        render turbo_stream: turbo_stream.replace(                                   # ボタン部分を置換
          "like_button_#{@entry.id}",                                                # 置換対象ID
          partial: "post_entries/like_button",                                       # パーシャル
          locals: { post_entry: @entry }                                             # ローカル変数
        )
      end
    end
  end

  private

  # 親リソース（Post）を取得
  def set_post
    @post = Post.find(params[:post_id])                                              # IDで検索
  end

  # 対象のエントリーを取得
  def set_entry
    @entry = @post.post_entries.find(params[:id])                                    # IDで検索
  end

  # エントリーの所有者かチェック
  def check_entry_owner
    return if @entry.user == current_user                                            # 所有者ならOK
    redirect_to @post, alert: "他のユーザーのアクションプランは編集・削除できません"  # 詳細へリダイレクト
  end

  # Strong Parameters
  def entry_params
    params.require(:post_entry).permit(:content, :deadline)                          # 許可パラメータ
  end

  # サムネイル画像の更新処理
  def process_thumbnail_update
    thumbnail_s3_key = params[:post_entry][:thumbnail_s3_key]                        # S3キーを取得
    return if thumbnail_s3_key.blank?                                                # 空なら終了

    if thumbnail_s3_key == "CLEAR"                                                   # クリア指定の場合
      @entry.update(thumbnail_url: nil)                                              # サムネイルを削除
    else                                                                             # S3キーが指定された場合
      @entry.update(thumbnail_url: thumbnail_s3_key)                                 # サムネイルを更新
    end
  end

  # 動画変更処理
  def process_video_change
    new_video_url = params[:post_entry][:new_video_url]                              # 新しい動画URLを取得
    return if new_video_url.blank?                                                   # 空なら終了

    new_post = Post.find_or_create_by_video(youtube_url: new_video_url)              # 新しい動画を取得
    if new_post&.persisted? && new_post.id != @entry.post_id                         # 有効な新しい動画の場合
      @entry.post = new_post                                                         # エントリーを新しい動画に紐づけ
      @post = new_post                                                               # @postを更新
    end
  rescue StandardError => e                                                          # エラーが発生した場合
    Rails.logger.error "Video change error: #{e.message}"                            # エラーログ出力
  end

  # 更新成功時のレスポンス
  def respond_to_update_success
    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.json do                                                                 # JSON形式
        redirect_url = params[:from] == "mypage" ? mypage_path : post_path(@post)    # リダイレクト先を決定
        render json: { success: true, redirect_url: redirect_url }                   # 成功レスポンス
      end
      format.html do                                                                 # HTML形式
        redirect_path = params[:from] == "mypage" ? mypage_path : @post              # リダイレクト先を決定
        redirect_to redirect_path, notice: "アクションプランを更新しました"          # リダイレクト
      end
    end
  end

  # 更新失敗時のレスポンス
  def respond_to_update_failure
    respond_to do |format|                                                           # レスポンス形式に応じた処理
      format.json do                                                                 # JSON形式
        render json: { success: false, error: @entry.errors.full_messages.join(", ") }, status: :unprocessable_entity  # エラーレスポンス
      end
      format.turbo_stream { render :edit, status: :unprocessable_entity }            # Turbo Stream形式
      format.html { render :edit, status: :unprocessable_entity }                    # HTML形式
    end
  end

  # 削除後のリダイレクト
  def redirect_after_destroy
    if params[:from] == "mypage" || request.referer&.include?("mypage")              # マイページから来た場合
      redirect_to mypage_path, notice: "アクションプランを削除しました"              # マイページへリダイレクト
    else                                                                             # それ以外の場合
      redirect_to post_path(@post, design: extract_design_from_referer), notice: "アクションプランを削除しました"  # 詳細へリダイレクト
    end
  end

  # HTML形式の達成処理（トグル）
  def handle_achieve_html
    if @entry.achieve!                                                               # 達成状態をトグル
      notice_message = @entry.achieved? ? "達成おめでとうございます！" : "未達成に戻しました"  # メッセージを決定
      redirect_after_achieve(notice_message)                                         # リダイレクト処理
    else                                                                             # 失敗した場合
      redirect_to @post, alert: "達成処理に失敗しました"                             # 詳細へリダイレクト
    end
  end

  # JSON形式の達成処理
  def handle_achieve_json
    if @entry.achieved?                                                              # 達成済みの場合
      @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)           # 未達成に戻す
      render json: { success: true, achieved: false }                                # 成功レスポンス
    else                                                                             # 未達成の場合
      @entry.achieve_with_reflection!(                                               # 感想・画像付きで達成
        reflection_text: params[:reflection],                                        # 振り返り
        result_image_s3_key: params[:result_image_s3_key]                            # 達成画像
      )
      render json: { success: true, achieved: true, entry: entry_json(@entry) }      # 成功レスポンス
    end
  rescue StandardError => e                                                          # エラーが発生した場合
    render json: { success: false, error: e.message }, status: :unprocessable_entity  # エラーレスポンス
  end

  # Turbo Stream形式の達成処理
  def handle_achieve_turbo_stream
    if @entry.achieved?                                                              # 達成済みの場合
      @entry.update!(achieved_at: nil, reflection: nil, result_image: nil)           # 未達成に戻す
      flash.now[:notice] = "未達成に戻しました"                                      # フラッシュメッセージ
    else                                                                             # 未達成の場合
      @entry.achieve_with_reflection!(                                               # 感想・画像付きで達成
        reflection_text: params[:reflection],                                        # 振り返り
        result_image_s3_key: params[:result_image_s3_key]                            # 達成画像
      )
      flash.now[:notice] = "達成おめでとうございます！"                              # フラッシュメッセージ
    end
  rescue StandardError => e                                                          # エラーが発生した場合
    flash.now[:alert] = e.message                                                    # エラーメッセージ
  end

  # 達成後のリダイレクト
  def redirect_after_achieve(notice_message)
    if params[:redirect_to] == "mypage" || request.referer&.include?("mypage")       # マイページへリダイレクト指定
      redirect_to mypage_path, notice: notice_message                                # マイページへ
    else                                                                             # それ以外
      redirect_to post_path(@post, design: extract_design_from_referer), notice: notice_message  # 詳細へ
    end
  end

  # 達成記録のJSON構造を構築
  def build_achievement_json(entry)
    {
      id: entry.id,                                                                  # エントリーID
      content: entry.content,                                                        # プラン内容
      reflection: entry.reflection,                                                  # 振り返り
      achieved_at: entry.achieved_at&.strftime("%Y年%m月%d日"),                      # 達成日時
      result_image_url: entry.signed_result_image_url,                               # 達成画像URL
      fallback_thumbnail_url: entry.signed_thumbnail_url || youtube_thumbnail_url(entry.post),  # フォールバックURL
      post: {                                                                        # 投稿情報
        id: entry.post.id,                                                           # 投稿ID
        title: entry.post.youtube_title,                                             # タイトル
        url: post_path(entry.post)                                                   # 投稿URL
      },
      user: {                                                                        # ユーザー情報
        name: entry.user&.name,                                                      # ユーザー名
        avatar_url: entry.user&.avatar&.url                                          # アバターURL
      },
      can_edit: user_signed_in? && entry.user == current_user                        # 編集可能フラグ
    }
  end

  # エントリーのJSON構造を構築
  def entry_json(entry)
    {
      id: entry.id,                                                                  # エントリーID
      content: entry.content,                                                        # プラン内容
      reflection: entry.reflection,                                                  # 振り返り
      achieved_at: entry.achieved_at&.strftime("%Y年%m月%d日"),                      # 達成日時
      result_image_url: entry.signed_result_image_url,                               # 達成画像URL
      display_thumbnail_url: entry.display_result_thumbnail_url                      # 表示用サムネイルURL
    }
  end

  # リファラーからデザインパラメータを抽出
  def extract_design_from_referer
    return nil unless request.referer                                                # リファラーがなければnil

    uri = URI.parse(request.referer)                                                 # URIをパース
    Rack::Utils.parse_query(uri.query)["design"]                                     # designパラメータを取得
  rescue URI::InvalidURIError                                                        # 無効なURLの場合
    nil                                                                              # nilを返す
  end

  # YouTubeサムネイルURLを生成
  def youtube_thumbnail_url(post)
    "https://i.ytimg.com/vi/#{post.youtube_video_id}/mqdefault.jpg"                  # サムネイルURL
  end
end
