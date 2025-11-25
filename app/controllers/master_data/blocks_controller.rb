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

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_blocks_path
      end
    end


    def new
      @block = Block.new
      authorize @block, policy_class: MasterData::BlockPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_blocks_path
      end
    end

    def create
      @block = Block.new(block_params)
      authorize @block, policy_class: MasterData::BlockPolicy

      respond_to do |format|
        if @block.save
          format.turbo_stream do
            flash.now[:notice] = 'Block was successfully created.'
          end
          format.html { redirect_to master_data_blocks_path, notice: 'Block was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/blocks/form', locals: { block: @block }),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @block, policy_class: MasterData::BlockPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_blocks_path
      end
    end

    def update
      authorize @block, policy_class: MasterData::BlockPolicy

      respond_to do |format|
        if @block.update(block_params)
          format.turbo_stream do
            flash.now[:notice] = 'Block was successfully updated.'
          end
          format.html { redirect_to master_data_blocks_path, notice: 'Block was successfully updated.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/blocks/form', locals: { block: @block }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

def confirm_delete
  @block = Block.find_by(id: params[:id])
  unless @block
    redirect_to master_data_blocks_path, alert: "Block not found" and return
  end

  authorize @block, policy_class: MasterData::BlockPolicy

  # Only render the modal if Turbo frame request
  if turbo_frame_request?
    render layout: false
  else
    redirect_to master_data_blocks_path
  end
end

def destroy
  authorize @block, policy_class: MasterData::BlockPolicy

  respond_to do |format|
    if @block.destroy
      format.turbo_stream # looks for destroy.turbo_stream.erb
      format.html { redirect_to master_data_blocks_url, notice: 'Block was successfully deleted.' }
    else
      format.turbo_stream do
        flash.now[:alert] = "Unable to delete block: #{@block.errors.full_messages.join(', ')}"
        render :destroy, status: :unprocessable_entity
      end
      format.html do
        redirect_to master_data_blocks_url,
                    alert: "Unable to delete block: #{@block.errors.full_messages.join(', ')}"
      end
    end
  end
end

    private

    def set_block
      @block = Block.find(params[:id])
    end

    def block_params
      params.require(:block).permit(
        :block_number,
        :hectarage
      )
    end
  end
end
