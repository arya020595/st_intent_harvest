# frozen_string_literal: true

require 'test_helper'

module Exporters
  class BaseExporterTest < ActiveSupport::TestCase
    # Create a concrete implementation for testing the abstract base class
    class TestExporter < BaseExporter
      attr_reader :generate_export_called

      def initialize(records:, params: {}, **options)
        super
        @generate_export_called = false
      end

      protected

      def generate_export
        @generate_export_called = true
        'test export data'
      end

      def generate_filename
        build_filename('test')
      end

      def content_type
        'text/plain'
      end

      def file_extension
        'txt'
      end

      def resource_name
        'test'
      end
    end

    setup do
      @production1 = productions(:one)
      @production2 = productions(:two)
      @records = Production.all
    end

    # ============================================
    # Success Path Tests
    # ============================================

    test 'call returns Success monad with correct structure' do
      exporter = TestExporter.new(records: @records)
      result = exporter.call

      assert result.success?
      assert_instance_of Hash, result.value!
      assert result.value!.key?(:data)
      assert result.value!.key?(:filename)
      assert result.value!.key?(:content_type)
    end

    test 'call invokes generate_export method' do
      exporter = TestExporter.new(records: @records)
      exporter.call

      assert exporter.generate_export_called
    end

    test 'call returns correct data structure' do
      exporter = TestExporter.new(records: @records)
      result = exporter.call

      assert_equal 'test export data', result.value![:data]
      assert_equal 'text/plain', result.value![:content_type]
      assert_match(/test-.*\.txt/, result.value![:filename])
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'build_filename generates correct format with date range' do
      start_date = 3.days.ago.to_date
      end_date = Date.today
      params = { q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s } }

      exporter = TestExporter.new(records: @records, params: params)
      result = exporter.call

      expected = "test-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.txt"
      assert_equal expected, result.value![:filename]
    end

    test 'build_filename uses current date when no date params' do
      exporter = TestExporter.new(records: @records, params: {})
      result = exporter.call

      expected = "test-#{Date.current.strftime('%Y%m%d')}.txt"
      assert_equal expected, result.value![:filename]
    end

    test 'build_filename handles only start date' do
      start_date = 3.days.ago.to_date
      params = { q: { date_gteq: start_date.to_s } }

      exporter = TestExporter.new(records: @records, params: params)
      result = exporter.call

      expected = "test-#{start_date.strftime('%d-%m-%Y')}_to_All.txt"
      assert_equal expected, result.value![:filename]
    end

    test 'build_filename handles only end date' do
      end_date = Date.today
      params = { q: { date_lteq: end_date.to_s } }

      exporter = TestExporter.new(records: @records, params: params)
      result = exporter.call

      expected = "test-All_to_#{end_date.strftime('%d-%m-%Y')}.txt"
      assert_equal expected, result.value![:filename]
    end

    # ============================================
    # Validation Tests
    # ============================================

    test 'validates records are not nil' do
      exporter = TestExporter.new(records: nil)
      result = exporter.call

      assert result.failure?
      assert_match 'Records cannot be nil', result.failure
    end

    test 'accepts empty records collection' do
      empty_records = Production.none
      exporter = TestExporter.new(records: empty_records)
      result = exporter.call

      assert result.success?
    end

    # ============================================
    # Error Handling Tests
    # ============================================

    test 'handles errors during export generation' do
      failing_exporter = Class.new(BaseExporter) do
        protected

        def generate_export
          raise StandardError, 'Export generation failed'
        end

        def generate_filename
          'test.txt'
        end

        def content_type
          'text/plain'
        end

        def file_extension
          'txt'
        end

        def resource_name
          'test'
        end
      end

      exporter = failing_exporter.new(records: @records)
      result = exporter.call

      assert result.failure?
      assert_match 'Export generation failed', result.failure
    end

    test 'returns failure with error message when error occurs' do
      failing_exporter = Class.new(BaseExporter) do
        protected

        def generate_export
          raise StandardError, 'Test error'
        end

        def generate_filename
          'test.txt'
        end

        def content_type
          'text/plain'
        end

        def file_extension
          'txt'
        end

        def resource_name
          'test'
        end
      end

      exporter = failing_exporter.new(records: @records)
      result = exporter.call

      assert result.failure?
      assert_equal 'Test error', result.failure
    end

    # ============================================
    # NotImplementedError Tests
    # ============================================

    test 'raises NotImplementedError for generate_export if not implemented' do
      incomplete_exporter = Class.new(BaseExporter) do
        protected

        def generate_filename
          'test.txt'
        end

        def content_type
          'text/plain'
        end

        def file_extension
          'txt'
        end

        def resource_name
          'test'
        end
      end

      exporter = incomplete_exporter.new(records: @records)

      assert_raises(NotImplementedError) do
        exporter.call
      end
    end

    test 'raises NotImplementedError for generate_filename if not implemented' do
      incomplete_exporter = Class.new(BaseExporter) do
        protected

        def generate_export
          'data'
        end

        def content_type
          'text/plain'
        end

        def file_extension
          'txt'
        end

        def resource_name
          'test'
        end
      end

      exporter = incomplete_exporter.new(records: @records)

      assert_raises(NotImplementedError) do
        exporter.call
      end
    end

    # ============================================
    # Options Handling Tests
    # ============================================

    test 'accepts and stores additional options' do
      options = { custom_option: 'test_value' }
      exporter = TestExporter.new(records: @records, **options)

      assert_equal 'test_value', exporter.instance_variable_get(:@options)[:custom_option]
    end

    test 'params are accessible in exporter' do
      params = { q: { test: 'value' } }
      exporter = TestExporter.new(records: @records, params: params)

      assert_equal params, exporter.instance_variable_get(:@params)
    end

    # ============================================
    # Date Parsing Tests
    # ============================================

    test 'handles invalid date formats gracefully' do
      params = { q: { date_gteq: 'invalid-date', date_lteq: 'also-invalid' } }
      exporter = TestExporter.new(records: @records, params: params)

      # Should not raise error during initialization, will use fallback filename
      result = exporter.call
      assert result.success?
      # Should use current date as fallback since dates are invalid
      assert_match Date.current.strftime('%Y%m%d'), result.value![:filename]
    end

    test 'handles missing q param in params' do
      params = { other_param: 'value' }
      exporter = TestExporter.new(records: @records, params: params)
      result = exporter.call

      # Should use current date as fallback
      expected = "test-#{Date.current.strftime('%Y%m%d')}.txt"
      assert_equal expected, result.value![:filename]
    end
  end
end
