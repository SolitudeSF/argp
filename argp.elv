var tok-arg = 0
var tok-long = 1
var tok-short = 2
var tok-term = 3

var value-separators = ['=' ':']

fn find-sep {|a sep|
  var i = 0
  while (< $i (count $a)) {
    if (has-value $sep $a[$i]) { break }
    set i = (+ $i 1)
  }
  num $i
}

fn arg-component-parse {|a|
  var len = (count $a)
  if (and (> $len 1) (eq $a[0] '-')) {
    if (eq $a[1] '-') {
      if (> $len 2) {
        var sep = (find-sep $a $value-separators)
        if (eq $sep (- $len 1)) {
          fail "Missing value after value separator for argument: "$a[2..]
        } elif (eq $sep $len) {
          put [&kind=$tok-long &name=$a]
        } else {
          put [&kind=$tok-long &name=$a[..$sep] &value=$a[$sep..]]
        }
      } else {
        put [&kind=$tok-term]
      }
    } else {
      if (> $len 2) {
        if (has-value $value-separators $a[2]) {
          fail "Missing value after value separator for argument: "$a[1]
        } else {
          put [&kind=$tok-short &name=$a[..2] &value=$a[2..]]
        }
      } else {
        put [&kind=$tok-short &name=$a]
      }
    }
  } else {
    put [&kind=$tok-arg &name=$a]
  }
}

fn arg-tokens {|a|
  var only-args = $false
  for arg $a {
    if $only-args {
      put [&kind=$tok-arg &name=$arg]
    } else {
      var @tok = (arg-component-parse $arg)
      if (eq $tok-term $tok[0][kind]) {
        set only-args = $true
      }
      put $@tok
    }
  }
}

fn tok-to-arg {|a|
  if (eq $a[kind] $tok-arg) {
    put $a[name]
  } elif (or (eq $a[kind] $tok-long) (eq $a[kind] $tok-short)) {
    put $a[name]$a[value]
  } elif (eq $a[kind] $tok-term) {
    put '--'
  }
}

fn short-value {|a|
  if (has-value $value-separators $a[0]) { put $a[1..] } else { put $a }
}

fn parse-arg {|cli|
  var options = [&]
  var short-map = [&]
  var arguments = []

  keys $cli | each {|key|
    var opts = $cli[$key]
    var short = $key[0]
    if (has-key $opts short) { set short = $opts[short] }
    if (or (not-eq (kind-of $short) string) (!= (count $short) 1)) {
      fail "Short option should be a single character."
    } elif (not (has-key $short-map $short)) {
      set short-map[$short] = $key
    }
    if (and (has-key $opts needs-arg) $opts[needs-arg]) {
      set options[$key] = nil
    } else {
      set options[$key] = $false
    }
  }

  var i = 0
  var @tokens = (arg-tokens $args)
  while (< $i (count $tokens)) {
    var arg = $tokens[$i]
    var kind = $arg[kind]
    if (eq $kind $tok-arg) {
      set arguments = [$@arguments $arg[name]]
    } elif (eq $kind $tok-long) {
      var name = $arg[name][2..]
      if (has-key $cli $name) {
        if (and (has-key $cli[$name] needs-arg) $cli[$name][needs-arg]) {
          if (has-key $arg value) {
            set options[$name] = $arg[value][1..]
          } else {
            if (>= $i (- (count $tokens) 1)) {
              fail "Missing value for argument: "$name
            } else {
              set i = (+ $i 1)
              set options[$name] = (tok-to-arg $tokens[$i])
            }
          }
        } elif (has-key $arg value) {
          fail "Unexpected value: "$arg[value][1..]
        } else {
          set options[$name] = $true
        }
      } else {
        fail "Unknown argument: "$name
      }
    } elif (eq $kind $tok-short) {
      var key = $arg[name][1..]
      if (has-key $short-map $key) {
        var name = $short-map[$key]
        if (and (has-key $cli[$name] needs-arg) $cli[$name][needs-arg]) {
          if (has-key $arg value) {
            set options[$name] = (short-value $arg[value])
          } else {
            if (>= $i (- (count $tokens) 1)) {
              fail "Missing value for argument: "$name
            } else {
              i = (+ $i 1)
              set options[$name] = (tok-to-arg $tokens[$i])
            }
          }
        } elif (has-key $arg value) {
          fail "Unexpected value: "(short value $arg[value])
        } else {
          set options[$name] = $true
        }
      } else {
        fail "Unknown argument: "$key
      }
    }
    set i = (+ $i 1)
  }
  put $options $arguments
}
