# argp
Argument parser for [Elvish](https://elv.sh).

Install with `epm:install github.com/solitudesf/argp`.

## Example

Running this program like `./test.elv --test 123 outfile -h infile`

```elvish
use github.com/solitudesf/argp/argp argp

cli = [
  &test=[&needs-arg=$true]
  &help=[&short=h]
]

options arguments = (argp:parse-arg $cli)

put $options
# ▶ [&test=123 &help=$true]

put $arguments
# ▶ [outfile infile]
```

## Features
- Allows separating option and value with `<space>`, `:` or `=`.
- For short (one character) options value separator can be omited. `-m1`.
- `--` token terminates option parsing, so all arguments after it treated as freestanding arguments.

## Usage

Usage consists of composing a map describing CLI.
Module exposes function `parse-arg` which parses arguments and returns two values: map of options and list of freestanding arguments.
Keys of the map act as option identifiers and long variant of the option. By default options are treated as boolean flags. To require a value you need to add `&needs-arg=$true` to option submap. You can also specify shorthand version of flag using `&short` key, otherwise it assumes first character of the flag.
