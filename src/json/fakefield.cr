require "json"

module JSON::Serializable           # < reference documentation
end

module JSON
  # :nodoc:
  annotation FakeField
  end

  # `JSON::Serializable::Fake` allows method calls to generate JSON content.
  #
  # ### Example
  #
  # ```
  # require "json/fakefield"
  #
  # class Sum
  #   include JSON::Serializable
  #   include JSON::Serializable::Fake
  #
  #   property a : UInt32
  #   property b : UInt32
  #
  #   def initialize(@a, @b)
  #   end
  #
  #   @[JSON::FakeField]
  #   def sum(json : ::JSON::Builder) : Nil
  #     json.number(a + b)
  #   end
  # end
  #
  # s = Sum.new(10, 5)
  # puts s.to_json # => { "a": 10, "b": 5, "sum": 15 }
  # ```
  #
  # ### Usage
  #
  # `JSON::Serializable::Fake` will create `extend_to_json` (which will actually call
  # your methods) and will replace the `on_to_json` method generated by `JSON::Serializable`.
  #
  # `JSON::Serializable::Fake` **is** compatible with `JSON::Serializable::Unmapped` and
  # `JSON::Serializable::Strict` _as long as_ `JSON::Serializable::Fake` is included **last**.
  #
  # You can customize the behavior of each fake field via the `JSON::FakeField` annotation.
  # Method calls **MUST** accept `::JSON::Builder` as a parameter and return `::Nil`.  The
  # construction of JSON elements is handled via [::JSON::Builder](https://github.com/crystal-lang/crystal/blob/master/src/json/builder.cr#L6).
  #
  # `JSON::FakeField` properties:
  # * **key**: an explicit name of the field added to the json string (by default it uses the method name)
  # * **supress_key**: if `true` no json field will be implictly added.  This allows the method call to create multiple json fields
  #
  # WARNING: At the moment it is **not** possible to deserialize fake fields into a method call.  There is no technical limitation,
  # just a lack of time.  However, you can use `JSON::Serializable::Unmapped` to capture all the fake fields.
  #
  module Serializable::Fake
    protected def extend_to_json(json : ::JSON::Builder) : Nil
      {% begin %}
        # See: https://crystal-lang.org/api/1.8.0/Crystal/Macros/TypeNode.html
        # see: https://github.com/crystal-lang/crystal/issues/5067
        {% for t in ([@type] + @type.ancestors) %}
          {% for imeth in t.methods %}
            {% ann = imeth.annotation(::JSON::FakeField) %}
            {% if ann %}
              {% if ann[:suppress_key] == true %}
                {{ imeth.name }} json
              {% else %}
                json.field {{ (ann[:key] || imeth.name).stringify }} do
                  {{ imeth.name }} json
                end
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end

    protected def on_to_json(json : ::JSON::Builder) : Nil
      extend_to_json json
      super
    end
  end
end
