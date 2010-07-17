# installation-dependent paths for the api
module ApiEnv
  PATH = { :statement_files => ENV['RAILS_ENV'] == 'test' ? '/var/wesabe/uploads/test' : '/var/wesabe/uploads/current',
           :upload_temp_dir => "/var/wesabe/uploads/tmp" # temp dir for QIF uploads
         }
  MAX_UPLOAD_SIZE = 5242880  # bytes
end