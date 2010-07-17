# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register "application/x-ofx", :ofx, %w( text/ofx application/ofx )
Mime::Type.register "application/x-qif", :qif, %w( text/qif application/qif )
Mime::Type.register "application/x-qfx", :qfx, %w( text/qfx application/qfx )
Mime::Type.register "application/x-ofx2", :ofx2, %w( text/ofx2 application/ofx2 )
Mime::Type.register "application/vnd.ms-excel", :xls, %w( text/xls application/vnd.ms-excel )
Mime::Type.register "application/x-gzip", :gzip
Mime::Type.register "application/zip", :zip