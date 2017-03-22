module Api
  module V1
    class UsersController < Api::BaseController
      
      before_filter :ensure_params_user_exist, only: [:email_check]
      skip_before_filter :validate_authentication_token, only: [:email_check]
      before_filter :validate_user_object, except: [:email_check, :requested_by, :feed, :suggested]

      def email_check
        json = {
          data: {
            email: params[:user][:email],
            user_exists?: User.exists?(email: params[:user][:email])
          },
          success: true
        }.to_json
        
        render json: json, status: 200
      end

      def show
        json = Response::Object.new('user', instance_user, {current_user_id: current_user.id, api_version: @api_version}).to_json
        render json: json, status: 200
      end

      def daily_quote
        random_quote_from_collections = instance_user.collected_posts.order("RANDOM()").first
        random_quote_from_portfolio = instance_user.posts.order("RANDOM()").first

        prng = Random.new
        if prng.rand(1)
          daily_quote = random_quote_from_collections
        else
          daily_quote = random_quote_from_portfolio
        end

        Activity.for_post_gets_sent_for_daily_quote(current_user.id, {post_id: daily_quote.id})
        render json: Response::Object.new('post', daily_quote, {current_user_id: current_user.id, api_version: @api_version}).to_json, status: 200
      end



      def feed
        hash_conditions = {page: params[:page], count: params[:count]}
        hash_conditions.reject!{ |k,v| v.blank? }

        @posts = current_user.authenticated_feed(hash_conditions)

        json = Response::Collection.new('post', @posts, {current_user_id: current_user.id, page: params[:page], api_version: @api_version}).to_json

        render json: json, status: 200
      end

      def suggested
        page = params[:page] || 1
        count = params[:count] || 10
        @users = User.active.suggested.page(page).per(count).order("users.email = 'info@quotiful.com' DESC, users.updated_at DESC")

        json = Response::Collection.new('user', @users, {current_user_id: current_user.id, page: params[:page], api_version: @api_version}).to_json

        render json: json, status: 200
      end

      def follows
        page = params[:page] || 1
        count = params[:count] || 10

        @users = instance_user.followed_by_self.includes(:follows, :followers).order("relationships.created_at DESC").page(page).per(count)

        json = Response::Collection.new('user', @users, { current_user_id: current_user.id, relative_user_id: instance_user.id, page: page, api_version: @api_version }).to_json
        
        render json: json, status: 200
      end

      def followed_by
        page = params[:page] || 1
        count = params[:count] || 10

        @users = instance_user.followed_by_users.includes(:follows, :followers).order("relationships.created_at DESC").page(page).per(count)

        json = Response::Collection.new('user', @users, { current_user_id: current_user.id, relative_user_id: instance_user.id, page: page, api_version: @api_version }).to_json

        render json: json, status: 200
      end

      def requested_by
        page = params[:page] || 1
        count = params[:count] || 10
        
        @users = current_user.requested_by_users.page(page).per(count)

        json = Response::Collection.new('user', @users, { current_user_id: current_user.id, relative_user_id: instance_user.id, page: page, api_version: @api_version }).to_json

        render json: json, status: 200
      end

      def spam
        instance_user.is_spammer!

        json = Response::Object.new('user', instance_user, {current_user_id: current_user.id, api_version: @api_version}).to_json
        
        render json: json, status: 200
      end

      def recent
        @posts = instance_user.posts.order('posts.created_at DESC').page(params[:page]).per(params[:count] || 10)

        json = Response::Collection.new('post', @posts, {current_user_id: current_user.id, page: params[:page], instance_user_id: instance_user.id, api_version: @api_version}).to_json

        render json: json, status: 200
      end

      def recent_lean
        @posts = instance_user.posts.order('posts.created_at DESC').page(params[:page]).per(params[:count] || 10)

        json = Response::Collection.new('post_lean', @posts, {current_user_id: current_user.id, page: params[:page], instance_user_id: instance_user.id, api_version: @api_version}).to_json

        render json: json, status: 200
      end

      def collection_lean
        hash_conditions = {page: params[:page], count: params[:count]}
        hash_conditions.reject!{ |k,v| v.blank? }
        page = params[:page] || 1
        count = params[:count] || 10

        @posts = instance_user.collected_posts.order('collections.created_at DESC').page(page).per(count)

        json = Response::Collection.new('post_lean', @posts, {current_user_id: current_user.id, page: page, api_version: @api_version}).to_json

        render json: json, status: 200
      end

      protected

        def is_current_user?
          instance_user.id == current_user.id
        end

        def ensure_params_id_exist
          return unless params[:id].blank?
          render json: { success: false, message: "Missing user_id parameter" }, status: 200
        end

        def check_existence_of_user
          return if User.exists?(id: params[:id])
          render json: { success: false, message: "User not found" }, status: 200
        end

        def instance_user
          @instance_user ||= User.find(params[:id])
        end

        def validate_user_object
          ensure_params_id_exist || check_existence_of_user
        end

    end
  end
end