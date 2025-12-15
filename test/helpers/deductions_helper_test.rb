# frozen_string_literal: true

require 'test_helper'

class DeductionsHelperTest < ActionView::TestCase
  test 'sorted_deductions returns empty array for nil input' do
    assert_equal [], sorted_deductions(nil)
  end

  test 'sorted_deductions returns empty array for non-hash input' do
    assert_equal [], sorted_deductions('not a hash')
    assert_equal [], sorted_deductions([])
  end

  test 'sorted_deductions returns empty array for empty hash' do
    assert_equal [], sorted_deductions({})
  end

  test 'sorted_deductions orders EPF first' do
    deductions = {
      'EPF_LOCAL' => { 'name' => 'EPF' },
      'SOCSO' => { 'name' => 'SOCSO' }
    }

    result = sorted_deductions(deductions)
    assert_equal 'EPF_LOCAL', result[0][0]
  end

  test 'sorted_deductions orders SOCSO second' do
    deductions = {
      'EPF_LOCAL' => { 'name' => 'EPF' },
      'SOCSO' => { 'name' => 'SOCSO' },
      'EIS_LOCAL' => { 'name' => 'EIS' }
    }

    result = sorted_deductions(deductions)
    assert_equal 'SOCSO', result[1][0]
  end

  test 'sorted_deductions orders EIS third' do
    deductions = {
      'EPF_LOCAL' => { 'name' => 'EPF' },
      'SOCSO' => { 'name' => 'SOCSO' },
      'EIS_LOCAL' => { 'name' => 'EIS' }
    }

    result = sorted_deductions(deductions)
    assert_equal 'EIS_LOCAL', result[2][0]
  end

  test 'sorted_deductions puts other deductions last' do
    deductions = {
      'ZAKAT' => { 'name' => 'Zakat' },
      'EPF_LOCAL' => { 'name' => 'EPF' },
      'SOCSO' => { 'name' => 'SOCSO' },
      'EIS_LOCAL' => { 'name' => 'EIS' }
    }

    result = sorted_deductions(deductions)
    assert_equal 'ZAKAT', result[3][0]
  end

  test 'sorted_deductions handles EPF_FOREIGN' do
    deductions = {
      'EPF_FOREIGN' => { 'name' => 'EPF Foreign' },
      'SOCSO' => { 'name' => 'SOCSO' }
    }

    result = sorted_deductions(deductions)
    assert_equal 'EPF_FOREIGN', result[0][0]
    assert_equal 'SOCSO', result[1][0]
  end

  test 'sorted_deductions handles EIS variants' do
    deductions = {
      'EIS_FOREIGN' => { 'name' => 'EIS Foreign' },
      'EIS_LOCAL' => { 'name' => 'EIS Local' },
      'SOCSO' => { 'name' => 'SOCSO' },
      'EPF_LOCAL' => { 'name' => 'EPF' }
    }

    result = sorted_deductions(deductions)
    # EPF first, SOCSO second, then EIS variants
    assert_equal 'EPF_LOCAL', result[0][0]
    assert_equal 'SOCSO', result[1][0]
    assert_includes %w[EIS_FOREIGN EIS_LOCAL], result[2][0]
    assert_includes %w[EIS_FOREIGN EIS_LOCAL], result[3][0]
  end

  test 'sorted_deductions complete ordering scenario' do
    deductions = {
      'ZAKAT' => { 'name' => 'Zakat' },
      'EPF_LOCAL' => { 'name' => 'EPF' },
      'SOCSO' => { 'name' => 'SOCSO' },
      'EIS_LOCAL' => { 'name' => 'EIS' },
      'ADVANCED_PAYMENT' => { 'name' => 'Advanced Payment' }
    }

    result = sorted_deductions(deductions)
    codes = result.map { |code, _data| code }

    # EPF, SOCSO, EIS first
    assert_equal 'EPF_LOCAL', codes[0]
    assert_equal 'SOCSO', codes[1]
    assert_equal 'EIS_LOCAL', codes[2]

    # Others alphabetically
    others = codes[3..]
    assert_equal %w[ADVANCED_PAYMENT ZAKAT], others.sort
  end

  test 'sorted_deductions preserves data structure' do
    deductions = {
      'EPF_LOCAL' => {
        'name' => 'EPF',
        'employee_amount' => 100.0,
        'employer_amount' => 120.0
      }
    }

    result = sorted_deductions(deductions)
    code, data = result[0]

    assert_equal 'EPF_LOCAL', code
    assert_equal 'EPF', data['name']
    assert_equal 100.0, data['employee_amount']
    assert_equal 120.0, data['employer_amount']
  end
end
