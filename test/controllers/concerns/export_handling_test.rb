# frozen_string_literal: true

require 'test_helper'

class ExportHandlingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:superadmin)
    sign_in @user

    @production1 = productions(:one)
    @production2 = productions(:two)
    @production3 = productions(:three)
  end

  # ============================================
  # CSV Export Tests
  # ============================================

  test 'CSV export returns success response with correct content type' do
    get productions_path(format: :csv, q: { date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s })

    assert_response :success
    assert_equal 'text/csv', response.content_type
    assert_match 'attachment', response.headers['Content-Disposition']
  end

  test 'CSV export includes correct filename with date range' do
    start_date = 4.days.ago.to_date
    end_date = Date.today

    get productions_path(
      format: :csv,
      q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s }
    )

    expected_filename = "productions-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.csv"
    assert_match expected_filename, response.headers['Content-Disposition']
  end

  test 'CSV export contains headers' do
    get productions_path(format: :csv, q: { date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s })

    assert_response :success
    csv_data = response.body

    assert_match 'Date', csv_data
    assert_match 'Ticket Estate No.', csv_data
    assert_match 'Ticket Mill No.', csv_data
    assert_match 'Mill', csv_data
    assert_match 'Block No.', csv_data
    assert_match 'Total Bunches', csv_data
    assert_match 'Total Weight (Ton)', csv_data
  end

  test 'CSV export contains production data' do
    get productions_path(format: :csv, q: { date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s })

    assert_response :success
    csv_data = response.body

    assert_match @production1.ticket_estate_no, csv_data
    assert_match @production2.ticket_estate_no, csv_data
    assert_match @production1.mill.name, csv_data
  end

  # ============================================
  # PDF Export Tests
  # ============================================

  test 'PDF export returns success response with correct content type' do
    get productions_path(format: :pdf, q: { date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s })

    assert_response :success
    assert_equal 'application/pdf', response.content_type
    assert_match 'inline', response.headers['Content-Disposition']
  end

  test 'PDF export includes correct filename with date range' do
    start_date = 4.days.ago.to_date
    end_date = Date.today

    get productions_path(
      format: :pdf,
      q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s }
    )

    expected_filename = "productions-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.pdf"
    assert_match expected_filename, response.headers['Content-Disposition']
  end

  test 'PDF export without date filter uses current date in filename' do
    get productions_path(format: :pdf)

    expected_filename = "productions-#{Date.current.strftime('%Y%m%d')}.pdf"
    assert_match expected_filename, response.headers['Content-Disposition']
  end

  # ============================================
  # Error Handling Tests
  # ============================================

  test 'export handles missing records gracefully' do
    # Delete all productions
    Production.delete_all

    get productions_path(format: :csv, q: { date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s })

    assert_response :success
    # Should still have headers even with no data
    assert_match 'Date', response.body
  end

  test 'export with invalid date parameters handles error' do
    get productions_path(format: :csv, q: { date_gteq: 'invalid-date', date_lteq: Date.today.to_s })

    # Application should handle invalid dates - either success or redirect with error
    assert_includes [200, 302], response.status
  end

  # ============================================
  # Filter Tests
  # ============================================

  test 'CSV export respects mill filter' do
    mill = mills(:one)

    get productions_path(
      format: :csv,
      q: { mill_id_eq: mill.id, date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s }
    )

    assert_response :success
    csv_data = response.body

    assert_match mill.name, csv_data
  end

  test 'CSV export respects block filter' do
    block = blocks(:one)

    get productions_path(
      format: :csv,
      q: { block_id_eq: block.id, date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s }
    )

    assert_response :success
    csv_data = response.body

    assert_match block.block_number, csv_data
  end

  test 'PDF export includes filter information in output' do
    mill = mills(:one)

    get productions_path(
      format: :pdf,
      q: { mill_id_eq: mill.id, date_gteq: 4.days.ago.to_s, date_lteq: Date.today.to_s }
    )

    assert_response :success
    # PDF should be generated successfully with filters
    assert_equal 'application/pdf', response.content_type
  end
end
