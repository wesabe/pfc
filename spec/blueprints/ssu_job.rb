SsuJob.blueprint do
  status      { SsuJob::Status::SUCCESSFUL }
  user        { User.make }
  result      { 'ok' }
  job_guid    { ActiveSupport::SecureRandom.hex(16) }
  expires_at  { 1.hour.from_now }
end

SsuJob.blueprint(:started) do
  status  { SsuJob::Status::PENDING }
  result  { 'started' }
  version { 0 }
end

SsuJob.blueprint(:pending) do
  status  { SsuJob::Status::PENDING }
  result  { 'auth.user' }
  version { 2 }
end

SsuJob.blueprint(:expired) do
  status     { SsuJob::Status::PENDING }
  result     { 'auth.user' }
  version    { 2 }
  expires_at { 1.minute.ago }
end