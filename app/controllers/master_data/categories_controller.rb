# frozen_string_literal: true

module MasterData
  class CategoriesController < ApplicationController
    include RansackMultiSort

    before_action :set_category, only: %i[show edit update destroy]

    def index
      authorize Category, policy_class: MasterData::CategoryPolicy

      apply_ransack_search(policy_scope(Category,
                                        policy_scope_class: MasterData::CategoryPolicy::Scope).order(id: :desc))
      @pagy, @categories = paginate_results(@q.result)
    end

    def show
      authorize @category, policy_class: MasterData::CategoryPolicy
    end

    def new
      @category = Category.new
      authorize @category, policy_class: MasterData::CategoryPolicy
    end

    def create
      @category = Category.new(category_params)
      authorize @category, policy_class: MasterData::CategoryPolicy

      # Logic to be implemented later
    end

    def edit
      authorize @category, policy_class: MasterData::CategoryPolicy
    end

    def update
      authorize @category, policy_class: MasterData::CategoryPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @category, policy_class: MasterData::CategoryPolicy

      # Logic to be implemented later
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(
        :name,
        :category_type,
        :parent_id
      )
    end
  end
end
