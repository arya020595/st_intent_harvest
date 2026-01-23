# frozen_string_literal: true

# Production Seeds - Daily Production Records
# Create production records with mills and blocks

puts '📦 Creating production records...'

# Get reference data
blocks = Block.order(:block_number).limit(10).to_a
mills = Mill.kept.to_a

if blocks.empty?
  puts '    ⚠️  No blocks found, skipping production records'
  return
end

if mills.empty?
  puts '    ⚠️  No mills found, skipping production records'
  return
end

# Create production records for the last 30 days
productions_data = []
start_date = 30.days.ago.to_date
end_date = Date.current

(start_date..end_date).each do |date|
  # Create 3-5 random production records per day
  records_count = rand(3..5)

  records_count.times do |i|
    block = blocks.sample
    mill = mills.sample

    productions_data << {
      date: date,
      block_id: block.id,
      mill_id: mill.id,
      ticket_estate_no: "EST-#{date.strftime('%Y%m%d')}-#{format('%03d', i + 1)}",
      ticket_mill_no: "MILL-#{date.strftime('%Y%m%d')}-#{format('%03d', i + 1)}",
      total_bunches: rand(100..500),
      total_weight_ton: rand(5.0..25.0).round(2),
      created_at: Time.current,
      updated_at: Time.current
    }
  end
end

# Batch insert production records
if productions_data.any?
  # Remove duplicates based on date and block
  existing_records = Production.pluck(:date, :block_id).map { |d, b| [d, b] }
  new_records = productions_data.reject { |p| existing_records.include?([p[:date], p[:block_id]]) }

  if new_records.any?
    Production.insert_all(new_records)
    puts "    ✓ #{new_records.size} production records created"
  else
    puts '    ✓ Production records already exist'
  end
end

puts "    ✓ Total: #{Production.count} production records"
puts '✓ Production records created'
