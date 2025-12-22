# frozen_string_literal: true

module MasterData
  class CategoriesController < ApplicationController
    include RansackMultiSort
    include SoftDeletableController

    before_action :set_category, only: %i[show edit update destroy confirm_delete]

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

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_categories_path
      end
    end

    def create
      @category = Category.new(category_params)
      authorize @category, policy_class: MasterData::CategoryPolicy

      respond_to do |format|
        if @category.save
          format.turbo_stream do
            flash.now[:notice] = 'Category was successfully created.'
          end
          format.html { redirect_to master_data_categories_path, notice: 'Category was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/categories/form', locals: { category: @category }),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @category, policy_class: MasterData::CategoryPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_categories_path
      end
    end

    def update
      authorize @category, policy_class: MasterData::CategoryPolicy

      respond_to do |format|
        if @category.update(category_params)
          format.turbo_stream do
            flash.now[:notice] = 'Category was successfully updated.'
          end
          format.html { redirect_to master_data_categories_path, notice: 'Category was successfully updated.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/categories/form', locals: { category: @category }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end


    def confirm_delete
      @category = Category.find_by(id: params[:id])
      unless @category
        redirect_to master_data_categories_path, alert: "Category not found" and return
      end

      authorize @category, policy_class: MasterData::CategoryPolicy

      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_categories_path
      end
    end


    def destroy
      authorize @category, policy_class: MasterData::CategoryPolicy
      super
    end

    def restore
      @category = Category.with_discarded.find(params[:id])
      authorize @category, policy_class: MasterData::CategoryPolicy
      super
    end

    private

    def set_category
      @category = Category.find_by(id: params[:id])
      return if @category.present?

      if turbo_frame_request?
        render turbo_stream: turbo_stream.replace("modal", ""), status: :ok
      else
        redirect_to master_data_categories_path
      end
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
