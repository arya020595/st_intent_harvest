# frozen_string_literal: true

# Production Seeds - Workers
# Create worker records with employment details

puts '👷 Creating workers...'

workers_data = [
  { identity_number: 'ID-001', name: 'Ahmad Yani', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-01-15', nationality: 'Local' },
  { identity_number: 'ID-002', name: 'Siti Nurhaliza', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-03-10', nationality: 'Local' },
  { identity_number: 'ID-003', name: 'Budi Santoso', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2021-05-20', nationality: 'Local' },
  { identity_number: 'ID-004', name: 'Dewi Lestari', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2019-08-12', nationality: 'Local' },
  { identity_number: 'ID-005', name: 'Eko Prasetyo', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2022-02-05', nationality: 'Local' },
  { identity_number: 'ID-006', name: 'Fitri Handayani', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-11-22', nationality: 'Local' },
  { identity_number: 'ID-007', name: 'Gunawan Wijaya', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2018-06-30', nationality: 'Local' },
  { identity_number: 'ID-008', name: 'Hani Kartika', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2023-01-18', nationality: 'Local' },
  { identity_number: 'ID-009', name: 'Irfan Hakim', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2019-04-25', nationality: 'Local' },
  { identity_number: 'ID-010', name: 'Jasmine Putri', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2021-09-14', nationality: 'Local' },
  { identity_number: 'ID-011', name: 'Kurniawan', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-07-08', nationality: 'Local' },
  { identity_number: 'ID-012', name: 'Linda Sari', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2019-12-03', nationality: 'Local' },
  { identity_number: 'ID-013', name: 'Muhammad Ali', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2022-05-16', nationality: 'Local' },
  { identity_number: 'ID-014', name: 'Nur Azizah', worker_type: 'Full-Time', gender: 'Female', is_active: false,
    hired_date: '2018-10-20', nationality: 'Local' },
  { identity_number: 'ID-015', name: 'Oscar Pratama', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2023-03-12', nationality: 'Local' },
  { identity_number: 'ID-016', name: 'Putri Indah', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2021-01-28', nationality: 'Local' },
  { identity_number: 'ID-017', name: 'Rahmat Hidayat', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-04-15', nationality: 'Local' },
  { identity_number: 'ID-018', name: 'Sri Rahayu', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2022-08-22', nationality: 'Local' },
  { identity_number: 'ID-019', name: 'Taufik Rahman', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2019-02-14', nationality: 'Local' },
  { identity_number: 'ID-020', name: 'Umi Kalsum', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-09-05', nationality: 'Local' },
  { identity_number: 'ID-021', name: 'Vino Bastian', worker_type: 'Part-Time', gender: 'Male', is_active: false,
    hired_date: '2021-11-30', nationality: 'Foreigner' },
  { identity_number: 'ID-022', name: 'Wulan Guritno', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2018-05-18', nationality: 'Local' },
  { identity_number: 'ID-023', name: 'Yudi Setiawan', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2020-12-08', nationality: 'Local' },
  { identity_number: 'ID-024', name: 'Zahra Amelia', worker_type: 'Part-Time', gender: 'Female', is_active: true,
    hired_date: '2022-03-25', nationality: 'Foreigner' },
  { identity_number: 'ID-025', name: 'Agus Salim', worker_type: 'Full-Time', gender: 'Male', is_active: true,
    hired_date: '2019-07-10', nationality: 'Local' },
  { identity_number: 'ID-026', name: 'Bella Saphira', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2021-04-02', nationality: 'Local' },
  { identity_number: 'ID-027', name: 'Chandra Putra', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2023-02-14', nationality: 'Foreigner' },
  { identity_number: 'ID-028', name: 'Diana Pungky', worker_type: 'Full-Time', gender: 'Female', is_active: false,
    hired_date: '2018-09-22', nationality: 'Local' },
  { identity_number: 'ID-029', name: 'Erwin Prasetya', worker_type: 'Part-Time', gender: 'Male', is_active: true,
    hired_date: '2022-06-18', nationality: 'Foreigner' },
  { identity_number: 'ID-030', name: 'Farah Quinn', worker_type: 'Full-Time', gender: 'Female', is_active: true,
    hired_date: '2020-10-25', nationality: 'Local' }
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
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  Worker.insert_all(workers_insert_data)
end

puts "✓ Created #{Worker.count} workers"
