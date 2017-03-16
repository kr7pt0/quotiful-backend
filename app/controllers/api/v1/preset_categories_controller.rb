module Api
  module V1
    class PresetCategoriesController < Api::BaseController
      
      skip_before_filter :validate_authentication_token
      before_filter :validate_preset_category_object, only: [:show]

      def index
        @categories = PresetCategory.all

        json = Response::Collection.new('preset_category', @categories, { alt_key: :categories, api_version: @api_version }).to_json

        render json: json, status: 200
      end

      def show
        category = PresetCategory.find(params[:id])

        json = Response::Object.new('preset_category', category, { alt_name: :category, api_version: @api_version }).to_json
        
        render json: json, status: 200
      end

      def all
        @categories = PresetCategory.all

        json = Response::Collection.new('preset_category_lean', @categories, { alt_key: :categories, api_version: @api_version }).to_json

        render json: json, status: 200
      end

      def images
        category = PresetCategory.find(params[:id])
        count = params[:count].present? ? params[:count] : 20
        images = category.preset_images.order("created_at DESC").page(params[:page]).per(count)

        json = Response::Collection.new('preset_image', images, { page: params[:page], api_version: @api_version }).to_json

        render json: json, status: 200
      end

      protected

        def ensure_params_id_exist
          return unless params[:id].blank?
          render json: { success: false, message: "Missing category id" }, status: 200
        end

        def check_existence_of_preset_category
          return if PresetCategory.exists?(id: params[:id])
          render json: { success: false, message: "Preset image not found" }, status: 200
        end

        def validate_preset_category_object
          ensure_params_id_exist || check_existence_of_preset_category
        end

    end
  end
end