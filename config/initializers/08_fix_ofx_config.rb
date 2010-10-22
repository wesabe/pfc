# if you are running this locally, comment out the following line
FIXOFX_TIMEOUT = 120

if (fixofx = Rails.root.join('fixofx')).exist?
  OFX_CONVERTER = fixofx
elsif File.exist?("/opt/fixofx/timeout")
  OFX_CONVERTER = "/opt/fixofx/timeout #{FIXOFX_TIMEOUT} /opt/fixofx/fixofx"
elsif File.exist?("/var/wesabe/util/fixofx/timeout")
  OFX_CONVERTER = "/var/wesabe/util/fixofx/timeout #{FIXOFX_TIMEOUT} /var/wesabe/util/fixofx/fixofx"
elsif Rails.root.join('../fixofx/fixofx.py').exist?
  path = Rails.root.join('../fixofx/fixofx.py')
  OFX_CONVERTER = "python #{path}"
end
