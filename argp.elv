tok-arg = 0
tok-long = 1
tok-short = 2
tok-term = 3

value-separators = ['=' ':']

fn find-sep [a sep]{
  i = 0
  while (< $i (count $a)) {
    if (has-value $sep $a[$i]) { break }
    i = (+ $i 1)
  }
  put $i
}

fn arg-component-parse [a]{
  len = (float64 (count $a))
  if (and (> $len 1) (eq $a[0] '-')) {
    if (eq $a[1] '-') {
      if (> $len 2) {
        sep = (find-sep $a $value-separators)
        if (eq $sep (- $len 1)) {
          fail "Missing value after value separator for argument: "$a[2:]
        } elif (eq $sep $len) {
          put [&kind=$tok-long &name=$a]
        } else {
          put [&kind=$tok-long &name=$a[:$sep] &value=$a[$sep':']]
        }
      } else {
        put [&kind=$tok-term]
      }
    } else {
      if (> $len 2) {
        if (has-value $value-separators $a[2]) {
          fail "Missing value after value separator for argument: "$a[1]
        } else {
          put [&kind=$tok-short &name=$a[:2] &value=$a[2:]]
        }
      } else {
        put [&kind=$tok-short &name=$a]
      }
    }
  } else {
    put [&kind=$tok-arg &name=$a]
  }
}

fn arg-tokens [a]{
  only-args = $false
  for arg $a {
    if $only-args {
      put [&kind=$tok-arg &name=$arg]
    } else {
      @tok = (arg-component-parse $arg)
      if (eq $tok-term $tok[0][kind]) {
        only-args = $true
      }
      put $@tok
    }
  }
}

fn tok-to-arg [a]{
  if (eq $a[kind] $tok-arg) {
    put $a[name]
  } elif (or (eq $a[kind] $tok-long) (eq $a[kind] $tok-short)) {
    put $a[name]$a[value]
  } elif (eq $a[kind] $tok-term) {
    put '--'
  }
}

fn short-value [a]{
  if (has-value $value-separators $a[0]) { put $a[1:] } else { put $a }
}

fn parse-arg [cli]{
  options = [&]
  short-map = [&]
  arguments = []

  keys $cli | each [key]{
    opts = $cli[$key]
    short = $key[0]
    if (has-key $opts short) { short = $opts[short] }
    if (or (not-eq (kind-of $short) string) \
           (not-eq (count $short) 1)) {
      fail "Short option should be a single character."
    } elif (not (has-key $short-map $short)) {
      short-map[$short] = $key
    }
    if (and (has-key $opts needs-arg) $opts[needs-arg]) {
      options[$key] = nil
    } else {
      options[$key] = $false
    }
  }

  i = 0
  @tokens = (arg-tokens $args)
  while (< $i (count $tokens)) {
    arg = $tokens[$i]
    kind = $arg[kind]
    if (eq $kind $tok-arg) {
      arguments = [$@arguments $arg[name]]
    } elif (eq $kind $tok-long) {
      name = $arg[name][2:]
      if (has-key $cli $name) {
        if (and (has-key $cli[$name] needs-arg) $cli[$name][needs-arg]) {
          if (has-key $arg value) {
            options[$name] = $arg[value][1:]
          } else {
            if (>= $i (- (count $tokens) 1)) {
              fail "Missing value for argument: "$name
            } else {
              i = (+ $i 1)
              options[$name] = (tok-to-arg $tokens[$i])
            }
          }
        } elif (has-key $arg value) {
          fail "Unexpected value: "$arg[value][1:]
        } else {
          options[$name] = $true
        }
      } else {
        fail "Unknown argument: "$name
      }
    } elif (eq $kind $tok-short) {
      key = $arg[name][1:]
      if (has-key $short-map $key) {
        name = $short-map[$key]
        if (and (has-key $cli[$name] needs-arg) $cli[$name][needs-arg]) {
          if (has-key $arg value) {
            options[$name] = (short-value $arg[value])
          } else {
            if (>= $i (- (count $tokens) 1)) {
              fail "Missing value for argument: "$name
            } else {
              i = (+ $i 1)
              options[$name] = (tok-to-arg $tokens[$i])
            }
          }
        } elif (has-key $arg value) {
          fail "Unexpected value: "(short value $arg[value])
        } else {
          options[$name] = $true
        }
      } else {
        fail "Unknown argument: "$key
      }
    }
    i = (+ $i 1)
  }
  put $options $arguments
}
