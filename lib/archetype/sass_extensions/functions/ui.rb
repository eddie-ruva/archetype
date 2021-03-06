require 'archetype/functions/helpers'
require 'thread'

#
# This module provides some UI helper methods.
#
module Archetype::SassExtensions::UI
  # :stopdoc:
  @@archetype_ui_mutex = Mutex.new
  # :startdoc:

  #
  # generate a unique token
  #
  # *Parameters*:
  # - <tt>$prefix</tt> {String} a string to prefix the UID with, `class` and `id` will generate a unique selector
  # *Returns*:
  # - {String} the unique string
  #
  def unique(prefix = '')
    prefix = helpers.to_str(prefix, ' ', :quotes)
    prefix = '.' if prefix == 'class'
    prefix = '#' if prefix == 'id'
    suffix = (defined?(ArchetypeTestHelpers) || defined?(Test::Unit)) ? "RANDOM_UID" : "#{Time.now.to_i}-#{rand(36**8).to_s(36)}-#{uid}"
    return identifier("#{prefix}archetype-uid-#{suffix}")
  end

  #
  # tokenize a given value
  #
  # *Parameters*:
  # - <tt>$item</tt> {*} the item to generate a unique hash from
  # *Returns*:
  # - {String} a token of the string
  #
  def tokenize(item)
    prefix = helpers.to_str(environment.var('CONFIG_GENERATED_TAG_PREFIX') || Archetype.name) + '-'
    token = prefix + item.hash.to_s
    return identifier(token)
  end

  #
  # parse a CSS content string and format it for injection into innerHTML
  #
  # *Parameters*:
  # - <tt>$content</tt> {String} the CSS content string
  # *Returns*:
  # - {String} the processed string
  #
  def _ie_pseudo_content(content)
    content = helpers.to_str(content)
    # escape &
    content = content.gsub(/\&/, '&amp;')
    # convert char codes (and remove single trailing whitespace if present) (e.g. \2079 -> &#x2079;)
    content = content.gsub(/\\([\da-fA-F]{4})\s?/, '&#x\1;')
    # escape tags and cleanup quotes
    content = content.gsub(/\</, '&lt;').gsub(/\>/, '&gt;')
    # cleanup quotes
    content = content.gsub(/\A"|"\Z/, '').gsub(/\"/, '\\"')
    return identifier(content)
  end

  #
  # given a string of styles, convert it into a map
  #
  # *Parameters*:
  # - <tt>$string</tt> {String} the string to convert
  # *Returns*:
  # - {Map} the converted map of styles
  #
  def _style_string_to_map(string = '')
    # convert to string and strip all comments
    string = helpers.to_str(string, ' ').gsub(/\/\*(?!\*\/)*\*\//, '')
    # then split it on each rule and for each rule break it into it's key-value pairs
    styles = string.split(';').map do |rule|
      k, v = rule.split(':')
      [identifier(k), identifier(v)]
    end
    # then recompose the map
    return Sass::Script::Value::Map.new(Sass::Util.to_hash(styles))
  end

  #
  # given a set of grid sizes and an individual size, return the closest matching size
  #
  # *Parameters*:
  # - <tt>$grids</tt> {List} the list of grid options
  # - <tt>$size</tt> {Number} the size to find a match for
  # *Returns*:
  # - {Number} the closest matching grid size
  #
  def choose_best_glyph_grid(grids, size)
    return grids if grids == null

    grids = grids.to_a

    # perfect match?
    if grids.include?(size)
      return size
    end

    # otherwise let's find the best match
    # start with assuming the first item is the best
    best = {
      :grid     => grids.first,
      :distance => (+1.0/0.0) # similuate Float::INFINITY, but for Ruby 1.8
    }

    # for each grid option...
    grids.each do |grid|
      # if the units are comparable...
      if unit(grid) == unit(size)

        tmp_grid = strip_units(grid).value.to_f
        tmp_size = strip_units(size).value.to_f

        # simple algorithm to compute the distance between the size and grid
        #  choose the lesser of the (mod) or (grid - mod)
        #  then divide it by grid^(number_of_grid_choices)
        mod = (tmp_size % tmp_grid)
        distance = [mod, tmp_grid - mod].min / tmp_grid**(grids.length)

        # if it's closer (smaller distance), use it...
        if distance < best[:distance]
          best = {
            :grid     => grid,
            :distance => distance
          }
        end
      end
    end
    # return the best match we found
    return best[:grid]
  end

  #
  # checks if a string looks like it's just a composition of character codes
  #
  # *Parameters*:
  # - <tt>$string</tt> {String} the string to check
  # *Returns*:
  # - {Boolean} whether or not the string looks like a sequence of character codes
  #
  def looks_like_character_code(string)
    string = helpers.to_str(string, ' ', :quotes)
    return bool(string =~ /^(\\([\da-fA-F]{4})\s*)+$/)
  end

  #
  # registers a breakpoint
  #
  # *Parameters*:
  # - <tt>$key</tt> {String} the key to register it under
  # - <tt>$value</tt> {*} the value to register
  # *Returns*:
  # - {Boolean} whether or not the value was registered
  #
  def register_breakpoint(key, value)
    # we need a dup as the Hash is frozen
    breakpoints = registered_breakpoints.dup
    # if there's no key registered...
    if breakpoints[key].nil? || is_null(breakpoints[key]).value
      # just register the value
      breakpoints[key] = value
    # otherwise, if the current value is different...
    elsif breakpoints[key] != value
      # throw a warning
      helpers.warn("[#{Archetype.name}:breakpoint] a breakpoint for `#{key}` is already set to `#{breakpoints[key]}`, ignoring `#{value}`")
      return bool(false)
    end
    environment.global_env.set_var('CONFIG_BREAKPOINTS', Sass::Script::Value::Map.new(breakpoints))
    return bool(true)
  end

  #
  # retrieves a breakpoint
  #
  # *Parameters*:
  # - <tt>$key</tt> {String} the key to lookup
  # *Returns*:
  # - {*} the registered breakpoint
  #
  def get_breakpoint(key)
    return registered_breakpoints[key] || null
  end

private

  def uid
    @@archetype_ui_mutex.synchronize do
      @@uid ||= 0
      @@uid += 1
    end
  end

  def registered_breakpoints
    breakpoints = environment.var('CONFIG_BREAKPOINTS')
    breakpoints.respond_to?(:to_h) ? breakpoints.to_h : {}
  end
end
