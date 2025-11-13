# frozen_string_literal: true

module MasterData
  class CategoriesController < ApplicationController
    include RansackMultiSort

    before_action :set_category, only: %i[show edit update destroy]

    def index
      authorize Category, policy_class: MasterData::CategoryPolicy

      apply_ransack_search(policy_scope(Category,
                                        policy_scope_class: MasterData::CategoryPolicy::Scope).order(id: :desc))
      @pagy, @categories = paginate_results(@q.result.includes(:parent))
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

      if @category.save
        redirect_to master_data_category_path(@category), notice: 'Category was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @category, policy_class: MasterData::CategoryPolicy
    end

    def update
      authorize @category, policy_class: MasterData::CategoryPolicy

      if @category.update(category_params)
        redirect_to master_data_category_path(@category), notice: 'Category was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @category, policy_class: MasterData::CategoryPolicy

      @category.destroy!
      redirect_to master_data_categories_url, notice: 'Category was successfully deleted.'
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
