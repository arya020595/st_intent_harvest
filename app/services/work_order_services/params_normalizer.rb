# frozen_string_literal: true

module WorkOrderServices
  # Service Object for normalizing work order parameters
  # Follows Single Responsibility Principle - only handles param normalization
  class ParamsNormalizer
    def self.call(params)
      new(params).normalize
    end

    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def normalize
      normalize_work_month
      @params
    end

    private

    # Convert work_month from YYYY-MM format to Date (first day of month)
    def normalize_work_month
      return unless @params[:work_month].present? && @params[:work_month].is_a?(String)

      @params[:work_month] = parse_month_string(@params[:work_month])
    end

    # Parse YYYY-MM format to first day of month
    def parse_month_string(month_string)
      Date.parse("#{month_string}-01")
    rescue StandardError
      nil
    end
  end
end
