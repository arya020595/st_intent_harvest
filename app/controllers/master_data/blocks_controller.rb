# frozen_string_literal: true

module MasterData
  class BlocksController < ApplicationController
    include RansackMultiSort

    before_action :set_block, only: %i[show edit update destroy]

    def index
      authorize Block, policy_class: MasterData::BlockPolicy

      apply_ransack_search(policy_scope(Block, policy_scope_class: MasterData::BlockPolicy::Scope).order(id: :desc))
      @pagy, @blocks = paginate_results(@q.result)
    end

    def show
      authorize @block, policy_class: MasterData::BlockPolicy
    end

    def new
      @block = Block.new
      authorize @block, policy_class: MasterData::BlockPolicy
    end

    def create
      @block = Block.new(block_params)
      authorize @block, policy_class: MasterData::BlockPolicy

      if @block.save
        redirect_to master_data_block_path(@block), notice: 'Block was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @block, policy_class: MasterData::BlockPolicy
    end

    def update
      authorize @block, policy_class: MasterData::BlockPolicy

      if @block.update(block_params)
        redirect_to master_data_block_path(@block), notice: 'Block was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @block, policy_class: MasterData::BlockPolicy

      @block.destroy!
      redirect_to master_data_blocks_url, notice: 'Block was successfully deleted.'
    end

    private

    def set_block
      @block = Block.find(params[:id])
    end

    def block_params
      params.require(:block).permit(
        :name,
        :hectarage,
        :location
      )
    end
  end
end
