
# Helpers from underscorejs
isFunction = (x) -> !!(x and x.constructor and x.call and x.apply)
isString = (x) -> !!(x is '' or (x and x.charCodeAt and x.substr))

exports =

  Class: class Class

    # Test to ensure we aren't accidentally overriding keys
    @__noClobber__ = (ks...) ->
      for k in ks
        if @::[k]? then throw 'Clobber detected'
      @

    #### Extenders
    # **Extenders** allow you to extend the classes prototype with the
    # the provided attributes

    # Extend the prototype with the given object, possibly clobbering
    # pre-existing properties.
    @extend = (o, f = (k,v)->v) ->
      @::[k] = f k,v for k,v of o; @


    # Override keys on the prototype. Keys must already be defined higher
    # in the class hierarchy.
    @override = (o) -> @extend o,
      (k,v) =>
        if not @::[k] then throw 'Nothing to override'
        if @::hasOwnProperty k then throw 'Property redefined'
        v

    # In the majority of cases, overriding is done to run code
    # before or after the super runs. @before and @after
    # wrap the current method in a new function that executes the given
    # code in the right order. You don't have to worry if
    # the super exists or not.
    @before = (o) -> @extend o,
      (k,v) => w = @::[k]; ->
          v.apply @, arguments
          w?.apply @, arguments

    @after = (o) -> @extend o,
      (k,v)=> w = @::[k]; ->
          r = w?.apply @, arguments
          v.apply @, arguments; r


    #### Introducers
    # **Introducers** are extenders that check to make sure you are not
    # accidentally clobbering a key.

    # Safely extend the prototype with new keys
    @introduce = (o, f = (k,v)->v) -> @extend o,
      (k,v) => @__noClobber__ k; f k,v

    # **@property** introducer
    # For each key, expects an object with a get/set pair of accessor functions
    # (e.g., `@property x: get: (-> @_x or -1), set: (@_x) ->`
    # The result is a single accessor method. Calling this method
    # with no arguments will call your getter and with one argument,
    # your setter. Your setter is only called if the result of your getter
    # isnt the new value (i.e., setter is only called if the value has appeared
    # to have changed)
    @property = (o) -> @introduce o,
      (k,v) =>
        @__noClobber__(
          get = '__get__'+k,
          set = '__set__'+k )
        @::[get] = v.get
        @::[set] = v.set
        (x) ->
          old = @[get]()
          if arguments.length
            (if x isnt old then @[set] x,old); @
          else old

    # **@initialize** Introducer
    # Declare properties on your class that get initialized to the
    # supplied value. If the value supplied is a function, that function will
    # be evaluated everytime a new instance that is created to initialize it.
    # (e.g., `@initialize queue: -> Array`) will give each instance it's own
    # queue.

    @initialize = (o) -> @introduce o,
      (k,v) => if isFunction v then new @Initializer k,v else v

    class @Initializer
      constructor: (@key, @f) ->
      initInstance: (inst) -> inst[@key] = @f.call inst

    # **@delegate** introducer facilitates delegating methods
    # to methods of an attribute on the instance.
    # `@delegate x: 'point'` delegates the method @x to @point.x (e.g., like writing
    # `@introduce x: -> @point.x.apply @, arguments`)
    # Alternatively, you can specify the method to call on the delegate like this:
    # `@delegate w: 'dim.width'` (delegates @w to @dim.width)
    # When returning the value of the delegated function, the proxy function checks
    # if the return value is the delegate, in which case it returns `this` instead
    # of the delegate.
    @delegate = (o) -> @introduce o,
      (k,v) =>
        if (ps = v.split '.').length is 1
          delgslot = v; method = k
        else
          delgslot = ps[0]; method = ps[1]
        ->
          delg = @[delgslot]; m = delg[method];
          r = m.apply delg, arguments
          if r is delg then @ else r

    # Good supplement for chaining and with
    # Makes mixins a breeze
    @do: (fs...) -> f.call @ for f in fs

    constructor: ->
      v.initInstance @ for k,v of @ when v instanceof Class.Initializer
      @init?.apply @, arguments

    # Good supplement for chaining and with
    do: @do

@Class = exports.Class; exports