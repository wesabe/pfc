# Be sure to restart your server when you modify this file.

# clear out all default Rails inflections and do our own, since the Rails defaults are wrong in a few places
# and poorly written

ActiveSupport::Inflector.inflections.clear
ActiveSupport::Inflector.inflections do |inflect|
  inflect.plural(/$/, 's')
  inflect.plural(/s$/i, 's')
  inflect.plural(/x$/i, 'xes')
  inflect.plural(/z$/i, 'zzes')
  inflect.plural(/(ax|test)is$/i, '\1es')
  inflect.plural(/(octop)us$/i, '\1i')
  inflect.plural(/(alias|status|virus)$/i, '\1es')
  inflect.plural(/(bu)s$/i, '\1ses')
  inflect.plural(/(buffal|tomat)o$/i, '\1oes')
  inflect.plural(/([ti])um$/i, '\1a')
  inflect.plural(/sis$/i, 'ses')
  inflect.plural(/(?:([^f])fe|([lr])f)$/i, '\1\2ves')
  inflect.plural(/([^aeiouy]|qu)y$/i, '\1ies')
  inflect.plural(/(x|ch|ss|sh)$/i, '\1es')
  inflect.plural(/(matr|vert|ind)(?:ix|ex)$/i, '\1ices')
  inflect.plural(/([m|l])ouse$/i, '\1ice')
  inflect.plural(/^(ox)$/i, '\1en')
  inflect.plural(/^(gas)$/i, '\1es')

  inflect.singular(/s$/i, '')
  inflect.singular(/(\w)\1es$/,'\1')
  inflect.singular(/(new|ga|serie)s$/i, '\1s')
  inflect.singular(/([ti])a$/i, '\1um')
  inflect.singular(/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, '\1\2sis')
  inflect.singular(/^(analy)ses$/i, '\1sis')
  inflect.singular(/([^f])ves$/i, '\1fe')
  inflect.singular(/([lr])ves$/i, '\1f')
  inflect.singular(/oves$/i, 'ove')
  inflect.singular(/([^aeiouy]|qu)ies$/i, '\1y')
  inflect.singular(/(x|ch|ss|sh)es$/i, '\1')
  inflect.singular(/([m|l])ice$/i, '\1ouse')
  inflect.singular(/(bus)es$/i, '\1')
  inflect.singular(/(o)es$/i, '\1')
  inflect.singular(/^(cris|ax|test)es$/i, '\1is')
  inflect.singular(/(octop)i$/i, '\1us')
  inflect.singular(/(alias|status|virus)es$/i, '\1')
  inflect.singular(/^(ox)en/i, '\1')
  inflect.singular(/(vert|ind)ices$/i, '\1ex')
  inflect.singular(/(matr)ices$/i, '\1ix')
  inflect.singular(/(quiz)zes$/i, '\1')
  inflect.singular(/(hive|tive|movie|shoe)s$/i, '\1')

  inflect.irregular('person', 'people')
  inflect.irregular('man', 'men')
  inflect.irregular('child', 'children')

  inflect.uncountable(%w(equipment information rice money species series fish sheep feedback))
end