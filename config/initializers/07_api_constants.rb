# installation-dependent paths for the api
module ApiEnv
  FILE_PATH = Rails.env.development? ? File.join(Rails.root, 'private', 'wesabe') : '/var/wesabe'

  PATH = { :statement_files => Rails.env.test? ? File.join(FILE_PATH, 'uploads', 'test') : File.join(FILE_PATH, 'uploads', 'current'),
           :upload_temp_dir =>  File.join(FILE_PATH, 'uploads', 'tmp') # temp dir for QIF uploads
         }

  MAX_UPLOAD_SIZE = 5242880  # bytes
end
