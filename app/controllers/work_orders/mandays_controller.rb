# frozen_string_literal: true

module WorkOrders
  class MandaysController < ApplicationController
    include RansackMultiSort

    before_action :set_manday, only: %i[show edit update destroy]
    before_action :load_workers, only: %i[new edit]

    def index
      authorize Manday, policy_class: WorkOrders::MandayPolicy

      apply_ransack_search(policy_scope(Manday,
                                        policy_scope_class: WorkOrders::MandayPolicy::Scope).order(work_month: :desc))
      @pagy, @mandays = paginate_results(@q.result)
    end

    def show
      authorize @manday, policy_class: WorkOrders::MandayPolicy
    end

    def new
      @manday = Manday.new
      authorize @manday, policy_class: WorkOrders::MandayPolicy
      prepare_manday_form
    end

    def create
      @manday = Manday.new(normalized_manday_params)
      authorize @manday, policy_class: WorkOrders::MandayPolicy

      if @manday.save
        redirect_to work_orders_mandays_path, notice: 'Manday was successfully created.'
      else
        load_workers
        prepare_manday_form
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @manday, policy_class: WorkOrders::MandayPolicy
      prepare_manday_form
    end

    def update
      authorize @manday, policy_class: WorkOrders::MandayPolicy

      if @manday.update(normalized_manday_params)
        redirect_to work_orders_mandays_path, notice: 'Manday was successfully updated.'
      else
        load_workers
        prepare_manday_form
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @manday, policy_class: WorkOrders::MandayPolicy

      if @manday.destroy
        redirect_to work_orders_mandays_path, notice: 'Manday was successfully deleted.', status: :see_other
      else
        redirect_to work_orders_mandays_path, alert: 'There was an error deleting the manday.', status: :see_other
      end
    end

    private

    def set_manday
      @manday = Manday.includes(mandays_workers: :worker).find(params[:id])
    end

    def load_workers
      @workers = Worker.active.order(:name)
    end

    # Prepares the manday form by building rows for workers not yet added
    # This creates a spreadsheet-like form with all active workers listed
    def prepare_manday_form
      existing_worker_ids = @manday.mandays_workers.map(&:worker_id).compact
      missing_worker_ids = @workers.pluck(:id) - existing_worker_ids

      missing_worker_ids.each do |worker_id|
        @manday.mandays_workers.build(worker_id: worker_id)
      end
    end

    def manday_params
      params.require(:manday).permit(
        :work_month,
        mandays_workers_attributes: %i[id worker_id days remarks _destroy]
      )
    end

    def normalized_manday_params
      WorkOrderServices::ParamsNormalizer.call(manday_params)
    end
  end
end
