# if you are running this locally, comment out the following line
FIXOFX_TIMEOUT = 120

# prefer the version installed in /opt, if it exists
if File.exists?("/opt/fixofx/timeout")
  OFX_CONVERTER = "/opt/fixofx/timeout #{FIXOFX_TIMEOUT} /opt/fixofx/fixofx"
elsif File.exists?("/var/wesabe/util/fixofx/timeout")
  OFX_CONVERTER = "/var/wesabe/util/fixofx/timeout #{FIXOFX_TIMEOUT} /var/wesabe/util/fixofx/fixofx"
elsif File.exists?(Rails.root.join('../fixofx/fixofx.py'))
  path = Rails.root.join('../fixofx/fixofx.py')
  OFX_CONVERTER = "python #{path}"
end
