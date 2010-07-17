# $Id: calc.y,v 1.4 2005/11/20 13:29:32 aamine Exp $
#
# Very simple calculater.

class SimpleCalc
  prechigh
    nonassoc UMINUS
    left '*' '/'
    left '+' '-'
  preclow
rule
  target: exp
        | /* none */ { result = 0 }

  exp: exp '+' exp { result += val[2] }
     | exp '-' exp { result -= val[2] }
     | exp '*' exp { result *= val[2] }
     | exp '/' exp { result /= val[2] }
     | '(' exp ')' { result = val[1] }
     | '-' NUMBER  =UMINUS { result = -val[1] }
     | '.' NUMBER { result = "0.#{val[1]}".to_f }
     | NUMBER
end

---- header
# $Id: calc.y,v 1.4 2005/11/20 13:29:32 aamine Exp $
---- inner

  def parse(str)
    @q = []
    until str.empty?
      case str
      when /\A\s+/
      when /\A\d+(\.\d+)?/
        @q.push [:NUMBER, $&.to_f]
      when /\A.|\n/o
        s = $&
        @q.push [s, s]
      end
      str = $'
    end
    @q.push [false, '$end']
    do_parse
  end

  def next_token
    @q.shift
  end

---- footer

if $0 == __FILE__
  parser = SimpleCalc.new
  puts
  puts 'type "Q" to quit.'
  puts
  while true
    puts
    print '? '
    str = gets.chop!
    break if /q/i =~ str
    begin
      puts "= #{parser.parse(str)}"
    rescue ParseError
      puts $!
    end
  end
end
