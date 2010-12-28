# Helper functions
successCount = 0
ok = (cond, msg) -> cond and successCount += 1 or (throw msg)
logs = []
log = -> logs.push msg for msg in arguments
oklog = -> ok msg is logs.shift() for msg in arguments

# Test init
# Test before and after

class A extends Class
  @after
    init: -> log 'A.@after init'
  @introduce
    foo: -> log 'A.foo'; 'result of foo'


class B extends A
  @after
    foo: -> log 'B.@after foo'
  @before
    foo: -> log 'B.@before foo'

b = new B()
oklog 'A.@after init'
ok b.foo() is 'result of foo'
oklog 'B.@before foo', 'A.foo', 'B.@after foo'


# Test properties and initialize

class C_ extends Class
  @initialize
    _x: -1
  @property
    x:
      get: -> @_x ?= 0
      set: (@_x) ->
    y:
      get: -> @_y ?= 0
      set: (@_y) ->


class C extends C_
  @after __set__x: (x) -> log 'C.@after set x'

C.after
  __set__y: (y) -> log 'External C.@after set y'

c = new C()
ok c.x() is -1
c.x 4; ok c.x() is 4
oklog 'C.@after set x'

# Test delegation

class D extends Class
  @initialize
    c: -> new C
  @delegate
    x: 'c'
    y2: 'c.y'

d = new D
ok d.y2() is 0
ok d.y2(4).y2() is 4
oklog 'External C.@after set y'

# Test Mixins

class E extends D
  @initialize
    queue: Array

class Event extends Class
  @after init: (@type, @sender, data = {}) ->
     @[k] = v for k,v of data

# Define a mixin "FiresEvents"
FiresEvents = ->
  @initialize
    _on: Object
  @introduce
    on: (name, f) -> (@_on[name] ?= []).push f
    off: (name, f) ->
      if f?
        @_on[name] = (g for g in @_on[name] when g isnt f)
      else delete @_on[name]
    fire: (name, data) ->
      e = new Event name, @, data
      f e  for f in @_on[name] or []

# Apply the mixin to class E
E.do FiresEvents

e = new E
e.on 'change', ({prop}) -> log 'Change detected: ' + prop
e.fire 'change', prop: 'foo'
ok log 'Change detected: foo'

# test initializer
e.queue.push 3
ok e.queue.length is 1
e2 = new E
ok not e2.queue.length

document.getElementById('console').innerHTML = "#{successCount} tests completed successfully."

# DSL for creating and extending classes and mixins

# Create a class
# Initialize properties on a per-instance basis using functions
# Here, every instance of A will have its own queue.
class A extends Class
  @initialize
    queue: Array

a1 = new A
a1.queue.push 'foo'
(new A).queue # empty

# Use @introduce when you intend to declare new keys
# Here, an exception is thrown since 'queue' was introduced in A
class B extends A
  @introduce
    queue: ->
    bar: ->

# Define a mixin
QueueMixin = ->
  @initialize
    queue: Array
  @introduce push: (x) -> @queue.push x

# Extend a mixin
StackMixin = ->
  @do QueueMixin
  @introduce pop: -> @queue.pop()

OtherMixin = ->

class MyStack extends Class
  @do StackMixin, OtherMixin #Apply mixins
  # Do other stuff



