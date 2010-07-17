# if you are running this locally, comment out the following line
FIXOFX_TIMEOUT = 120

# prefer the version installed in /opt, if it exists
if File.exists?("/opt/fixofx/timeout")
  OFX_CONVERTER = "/opt/fixofx/timeout #{FIXOFX_TIMEOUT} /opt/fixofx/fixofx"
else
  OFX_CONVERTER = "/var/wesabe/util/fixofx/timeout #{FIXOFX_TIMEOUT} /var/wesabe/util/fixofx/fixofx"
end