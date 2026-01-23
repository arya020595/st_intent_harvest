# frozen_string_literal: true

# Production Seeds - Mills Master Data
# Create palm oil mills

puts '🏭 Creating mills...'

mills_data = [
  { name: 'Sarawak Palm Oil Mill' },
  { name: 'Miri Processing Plant' },
  { name: 'Bintulu Central Mill' },
  { name: 'Kuching Agro Mill' },
  { name: 'Mukah Regional Mill' }
]

mills_data.each do |mill_data|
  Mill.find_or_create_by!(name: mill_data[:name])
end

puts "    ✓ #{Mill.count} mills"
puts '✓ Mills created'
