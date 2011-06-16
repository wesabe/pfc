require "openssl"

require "collections/all_the_same"
require "collections/shuffle"
require "collections/stringify_hash"

require "file/change_extname"

require "numeric/big_decimal"
require "numeric/normalize"
require "numeric/percentage"
require "numeric/sign"

require "object/silence_warnings"
require "object/tap"

require "rails_libraries/ar_class_quoting"
require "rails_libraries/ar_dependent_records"
require "rails_libraries/ar_enumerable"
require "rails_libraries/ar_error_sentence"
require "rails_libraries/ar_latest"
require "rails_libraries/better_time_in_words"
require "rails_libraries/builder_dasherize"
require "rails_libraries/migrations_type_fix"
require "rails_libraries/paginate_collection"
require "rails_libraries/quiet_back_redirection"
require "rails_libraries/number_to_currency_fix"
require "rails_libraries/session_debug"

require "string/better_titlecase"
require "string/dom_id"
require "string/titleize_fix"
require "string/to_gz"
require "string/version_to_i"
require "string/better_pluralize"

require "time/ambiguous_date"

require 'date/parse.rb'
# force reloading of Date::Format
Kernel::load 'date/format.rb'