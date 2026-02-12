# frozen_string_literal: true

# Production Seeds - Workers
# Create worker records with employment details
# Uses Worker model constants for valid values

puts '👷 Creating workers...'

# Reference Worker model constants for valid values
# Worker::WORKER_TYPES = ['Part - Time', 'Full - Time']
# Worker::GENDERS = %w[Male Female]
# Worker::POSITIONS = %w[Harvester General Driver Maintenance Mechanic Security Mandour Loaders]
# Worker::NATIONALITIES = %w[local foreigner foreigner_no_passport]

full_time = Worker::WORKER_TYPES.find { |t| t == 'Full - Time' }          # 'Full - Time'
part_time = Worker::WORKER_TYPES.find { |t| t == 'Part - Time' }          # 'Part - Time'
male = Worker::GENDERS.find { |g| g == 'Male' }                           # 'Male'
female = Worker::GENDERS.find { |g| g == 'Female' }                       # 'Female'
local = Worker::NATIONALITIES.find { |n| n == 'local' }                   # 'local'
foreigner = Worker::NATIONALITIES.find { |n| n == 'foreigner' }           # 'foreigner'
foreigner_no_passport = Worker::NATIONALITIES.find { |n| n == 'foreigner_no_passport' } # 'foreigner_no_passport'

# Positions from Worker::POSITIONS
harvester = Worker::POSITIONS.find { |p| p == 'Harvester' }               # 'Harvester'
general = Worker::POSITIONS.find { |p| p == 'General' }                   # 'General'
driver = Worker::POSITIONS.find { |p| p == 'Driver' }                     # 'Driver'
maintenance = Worker::POSITIONS.find { |p| p == 'Maintenance' }           # 'Maintenance'
mechanic = Worker::POSITIONS.find { |p| p == 'Mechanic' }                 # 'Mechanic'
security = Worker::POSITIONS.find { |p| p == 'Security' }                 # 'Security'
mandour = Worker::POSITIONS.find { |p| p == 'Mandour' }                   # 'Mandour'
loaders = Worker::POSITIONS.find { |p| p == 'Loaders' }                   # 'Loaders'

workers_data = [
  { identity_number: 'ID-001', name: 'Ahmad Yani', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2020-01-15', nationality: local, position: harvester },
  { identity_number: 'ID-002', name: 'Siti Nurhaliza', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2020-03-10', nationality: local, position: general },
  { identity_number: 'ID-003', name: 'Budi Santoso', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2021-05-20', nationality: local, position: harvester },
  { identity_number: 'ID-004', name: 'Dewi Lestari', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2019-08-12', nationality: local, position: general },
  { identity_number: 'ID-005', name: 'Eko Prasetyo', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2022-02-05', nationality: local, position: loaders },
  { identity_number: 'ID-006', name: 'Fitri Handayani', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2020-11-22', nationality: local, position: general },
  { identity_number: 'ID-007', name: 'Gunawan Wijaya', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2018-06-30', nationality: local, position: driver },
  { identity_number: 'ID-008', name: 'Hani Kartika', worker_type: part_time, gender: female, is_active: true,
    hired_date: '2023-01-18', nationality: local, position: general },
  { identity_number: 'ID-009', name: 'Irfan Hakim', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2019-04-25', nationality: local, position: mechanic },
  { identity_number: 'ID-010', name: 'Jasmine Putri', worker_type: part_time, gender: female, is_active: true,
    hired_date: '2021-09-14', nationality: local, position: general },
  { identity_number: 'ID-011', name: 'Kurniawan', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2020-07-08', nationality: local, position: harvester },
  { identity_number: 'ID-012', name: 'Linda Sari', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2019-12-03', nationality: local, position: general },
  { identity_number: 'ID-013', name: 'Muhammad Ali', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2022-05-16', nationality: local, position: loaders },
  { identity_number: 'ID-014', name: 'Nur Azizah', worker_type: full_time, gender: female, is_active: false,
    hired_date: '2018-10-20', nationality: local, position: general },
  { identity_number: 'ID-015', name: 'Oscar Pratama', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2023-03-12', nationality: local, position: harvester },
  { identity_number: 'ID-016', name: 'Putri Indah', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2021-01-28', nationality: local, position: general },
  { identity_number: 'ID-017', name: 'Rahmat Hidayat', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2020-04-15', nationality: local, position: maintenance },
  { identity_number: 'ID-018', name: 'Sri Rahayu', worker_type: part_time, gender: female, is_active: true,
    hired_date: '2022-08-22', nationality: local, position: general },
  { identity_number: 'ID-019', name: 'Taufik Rahman', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2019-02-14', nationality: local, position: mandour },
  { identity_number: 'ID-020', name: 'Umi Kalsum', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2020-09-05', nationality: local, position: general },
  { identity_number: 'ID-021', name: 'Vino Bastian', worker_type: part_time, gender: male, is_active: false,
    hired_date: '2021-11-30', nationality: foreigner, position: harvester },
  { identity_number: 'ID-022', name: 'Wulan Guritno', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2018-05-18', nationality: local, position: security },
  { identity_number: 'ID-023', name: 'Yudi Setiawan', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2020-12-08', nationality: local, position: driver },
  { identity_number: 'ID-024', name: 'Zahra Amelia', worker_type: part_time, gender: female, is_active: true,
    hired_date: '2022-03-25', nationality: foreigner, position: general },
  { identity_number: 'ID-025', name: 'Agus Salim', worker_type: full_time, gender: male, is_active: true,
    hired_date: '2019-07-10', nationality: local, position: harvester },
  { identity_number: 'ID-026', name: 'Bella Saphira', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2021-04-02', nationality: local, position: general },
  { identity_number: 'ID-027', name: 'Chandra Putra', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2023-02-14', nationality: foreigner, position: loaders },
  { identity_number: 'ID-028', name: 'Diana Pungky', worker_type: full_time, gender: female, is_active: false,
    hired_date: '2018-09-22', nationality: local, position: general },
  { identity_number: 'ID-029', name: 'Erwin Prasetya', worker_type: part_time, gender: male, is_active: true,
    hired_date: '2022-06-18', nationality: foreigner_no_passport, position: harvester },
  { identity_number: 'ID-030', name: 'Farah Quinn', worker_type: full_time, gender: female, is_active: true,
    hired_date: '2020-10-25', nationality: local, position: general }
]

# Batch insert workers
existing_workers = Worker.pluck(:identity_number)
new_workers = workers_data.reject { |w| existing_workers.include?(w[:identity_number]) }

if new_workers.any?
  workers_insert_data = new_workers.map do |w|
    {
      identity_number: w[:identity_number],
      name: w[:name],
      worker_type: w[:worker_type],
      gender: w[:gender],
      is_active: w[:is_active],
      hired_date: Date.parse(w[:hired_date]),
      nationality: w[:nationality],
      position: w[:position],
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  Worker.insert_all(workers_insert_data)
end

puts "✓ Created #{Worker.count} workers"
