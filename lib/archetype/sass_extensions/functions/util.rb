module Archetype::SassExtensions::Util

  #
  # simple test for `null` or `nil` (deprecated) value. this is here for back-compat support with old `nil` syntax
  #
  # *Parameters*:
  # - <tt>$value</tt> {*} the value to test
  # *Returns*:
  # - {Boolean} whether or not the value is null
  #
  def is_null(value)
    is_deprecated_nil = (value.is_a?(Sass::Script::Value::String) && value.value == 'nil')
    #helpers.warn("[#{Archetype.name}:nil] the usage of `nil` will be removed in a future release, please use the Sass standard `null`")
    return Sass::Script::Bool.new(value == null || is_deprecated_nil)
  end

  #
  # converts individual arguments into an archetype meta object that can be stored on a key in a map
  #
  # *Parameters*:
  # - <tt>args...</tt> {*} the values to put into the meta object
  # *Returns*:
  # - {Map} the meta object
  #
  def multiple_values(*args)
    return helpers.array_to_meta(args)
  end

  #
  # given a map with meta data, extract the message and substitute any key-value pairs (@see str-substitute)
  #
  # *Parameters*:
  # - <tt>$map</tt> {Map} the map to observe
  # - <tt>$subsitutes</tt> {Map} the map of substitutes
  # *Returns*:
  # - {String} the meta message
  #
  def meta_message(map, subsitutes = nil)
    message = null
    meta = map_get_meta(map)
    message = str_substitute(map_get(meta, identifier(helpers::META[:message])), subsitutes) if not meta.value.nil?
    return message
  end

  #
  # check to see if a map key has multiple values
  #
  # *Parameters*:
  # - <tt>$map</tt> {Map} the map to observe
  # *Returns*:
  # - {Boolean} whether or not the map key represents multiple values
  #
  def has_multiple_values(map)
    meta = map_get_meta(map)
    return map_has_key(meta, identifier(helpers::META[:has_multiples])) if not meta.value.nil?
    return bool(false)
  end

  #
  # retrieve the archetype meta data from a map
  #
  # *Parameters*:
  # - <tt>$map</tt> {Map} the map to observe
  # *Returns*:
  # - {Map} the data contained within the meta key
  #
  def map_get_meta(map)
    if map.is_a?(Sass::Script::Value::Map) and map_has_key(map, identifier(helpers::META[:meta])).value
      return map_get(map, identifier(helpers::META[:meta]))
    end
    return null
  end

  #
  # given a map of styles, get the derived style of a given property
  #
  # *Parameters*:
  # - <tt>$styles</tt> {Map} the map of styles
  # - <tt>$properties</tt> {String|List} the properties to extract the derived styles for
  # - <tt>$format</tt> {String} the format to return the results in [auto|map|list]
  # - <tt>$strict</tt> {Boolean} if true, will only return an exact match, and not try to extrapolate the value
  # *Returns*:
  # - {List|Map|*} either a list/map of the values or the individual value itself
  #
  def derived_style(styles, properties = [], format = 'auto', strict = false)
    strict = strict.value if strict.respond_to?(:value)
    return Archetype::Functions::CSS.get_derived_styles(helpers.data_to_hash(styles), properties, helpers.to_str(format).to_sym, strict)
  end
end
