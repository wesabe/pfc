require 'child_labor'

# makeofx2.0.py return codes and exceptions
class MakeOFX2
  SUCCESS = 0

  class AbstractException < Exception
    attr_accessor :debug_data
  end

  # FatalError is thrown if makeofx crashes
  class FatalError < AbstractException; RETURN_CODE = 1; end

  # NoInputError is thrown if makeofx is passed blank input
  class NoInputError < AbstractException; RETURN_CODE = 3; end

  # ParseError is thrown if makeofx should be able to understand the format, but fails parsing it
  class ParseError < AbstractException
    attr_accessor :statement_type # e.g. QIF, OFX1
    RETURN_CODE = 4
  end

  # UnsupportedFormatError is thrown if the statement isn't supported (e.g. PDF, HTML)
  class UnsupportedFormatError < AbstractException
    attr_accessor :statement_type # e.g. PDF, HTML, CSV
    RETURN_CODE = 5
  end

  # TimeoutError is thrown if fixofx times out
  class TimeoutError < AbstractException; RETURN_CODE = 128; end

  # catchall error if the return code from makeofx is unrecognized for some reason
  class UnknownError < AbstractException; end

  def self.convert(statement, options)
    # OFX_CONVERTER defined in config/environments/[production|development].rb
    # the converter is currently a python app

    command = OFX_CONVERTER + ' -d' +
      (options[:account_number] ? " --acctid #{options[:account_number]}" : '') +
      (options[:account_type] ? " --accttype \"#{options[:account_type]}\"" : '') +
      (options[:balance] ? " --balance #{options[:balance]}" : '') +
      (options[:currency] ? " --curdef #{options[:currency]}" : '') +
     (options[:financial_inst].date_format_ddmmyyyy? ? ' --dayfirst' : '')

    # using ChildLabor so we can not only separate stdout and stderr,
    # but also get the exit status (Open3 won't give us the exit status)
    stdout, stderr = nil

    task = ChildLabor.subprocess(command) do |t|
      t.write statement
      t.close_write
      stdout, stderr = t.read, t.read_stderr
    end

    # handle exceptions
    case task.exit_status
    when SUCCESS
      return stdout
    when FatalError::RETURN_CODE
      exception = FatalError.new
    when NoInputError::RETURN_CODE
      exception = NoInputError.new
    when ParseError::RETURN_CODE
      exception = ParseError.new
    when UnsupportedFormatError::RETURN_CODE
      exception = UnsupportedFormatError.new
    when TimeoutError::RETURN_CODE
      exception = TimeoutError.new
    else
      exception = UnknownError.new
    end
    exception.debug_data = "----- stdout:\n#{stdout}\n----- stderr:\n#{stderr}"
    raise exception
  end
end