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

    def destroy
      authorize @category, policy_class: MasterData::CategoryPolicy

      respond_to do |format|
        if @category.destroy
          format.turbo_stream do
            flash.now[:notice] = 'Category was successfully deleted.'
          end
          format.html { redirect_to master_data_categories_url, notice: 'Category was successfully deleted.' }
        else
          format.turbo_stream do
            flash.now[:alert] = "Unable to delete category: #{@category.errors.full_messages.join(', ')}"
            render :destroy, status: :unprocessable_entity
          end
          format.html do
            redirect_to master_data_categories_url,
                        alert: "Unable to delete category: #{@category.errors.full_messages.join(', ')}"
          end
        end
      end
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
