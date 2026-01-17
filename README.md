# pin.ex

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_pin.svg)](https://hex.pm/packages/sashite_pin)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_pin)
[![License](https://img.shields.io/hexpm/l/sashite_pin.svg)](https://github.com/sashite/pin.ex/blob/main/LICENSE)

> **PIN** (Piece Identifier Notation) implementation for Elixir.

## Overview

This library implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/).

## Installation

Add `sashite_pin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sashite_pin, "~> 2.0"}
  ]
end
```

## Usage

### Parsing (String → Identifier)

Convert a PIN string into an `Identifier` struct.

```elixir
# Standard parsing (returns {:ok, identifier} or {:error, reason})
{:ok, pin} = Sashite.Pin.parse("K")
pin.type       # => :K
pin.side       # => :first
pin.state      # => :normal
pin.terminal   # => false

# With state modifier
{:ok, pin} = Sashite.Pin.parse("+R")
pin.state  # => :enhanced

# With terminal marker
{:ok, pin} = Sashite.Pin.parse("K^")
pin.terminal  # => true

# Combined
{:ok, pin} = Sashite.Pin.parse("+K^")
pin.state     # => :enhanced
pin.terminal  # => true

# Bang version (raises on error)
pin = Sashite.Pin.parse!("K")

# Invalid input
{:error, :empty_input} = Sashite.Pin.parse("")
Sashite.Pin.parse!("invalid")  # => raises ArgumentError
```

### Formatting (Identifier → String)

Convert an `Identifier` back to a PIN string.

```elixir
# From Identifier struct
pin = Sashite.Pin.Identifier.new(:K, :first)
Sashite.Pin.Identifier.to_string(pin)  # => "K"

# With attributes
pin = Sashite.Pin.Identifier.new(:R, :second, :enhanced)
Sashite.Pin.Identifier.to_string(pin)  # => "+r"

pin = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
Sashite.Pin.Identifier.to_string(pin)  # => "K^"
```

### Validation

```elixir
# Boolean check
Sashite.Pin.valid?("K")        # => true
Sashite.Pin.valid?("+R")       # => true
Sashite.Pin.valid?("K^")       # => true
Sashite.Pin.valid?("invalid")  # => false
```

### Accessing Identifier Data

```elixir
{:ok, pin} = Sashite.Pin.parse("+K^")

# Get attributes (direct struct access)
pin.type       # => :K
pin.side       # => :first
pin.state      # => :enhanced
pin.terminal   # => true

# Get string components
Sashite.Pin.Identifier.letter(pin)  # => "K"
Sashite.Pin.Identifier.prefix(pin)  # => "+"
Sashite.Pin.Identifier.suffix(pin)  # => "^"
```

### Transformations

All transformations return new immutable structs.

```elixir
{:ok, pin} = Sashite.Pin.parse("K")

# State transformations
Sashite.Pin.Identifier.enhance(pin) |> Sashite.Pin.Identifier.to_string()    # => "+K"
Sashite.Pin.Identifier.diminish(pin) |> Sashite.Pin.Identifier.to_string()   # => "-K"
Sashite.Pin.Identifier.normalize(pin) |> Sashite.Pin.Identifier.to_string()  # => "K"

# Side transformation
Sashite.Pin.Identifier.flip(pin) |> Sashite.Pin.Identifier.to_string()  # => "k"

# Terminal transformations
Sashite.Pin.Identifier.mark_terminal(pin) |> Sashite.Pin.Identifier.to_string()    # => "K^"
Sashite.Pin.Identifier.unmark_terminal(pin) |> Sashite.Pin.Identifier.to_string()  # => "K"

# Attribute changes
Sashite.Pin.Identifier.with_type(pin, :Q) |> Sashite.Pin.Identifier.to_string()       # => "Q"
Sashite.Pin.Identifier.with_side(pin, :second) |> Sashite.Pin.Identifier.to_string()  # => "k"
Sashite.Pin.Identifier.with_state(pin, :enhanced) |> Sashite.Pin.Identifier.to_string()    # => "+K"
Sashite.Pin.Identifier.with_terminal(pin, true) |> Sashite.Pin.Identifier.to_string()      # => "K^"
```

### Queries

```elixir
{:ok, pin} = Sashite.Pin.parse("+K^")

# State queries
Sashite.Pin.Identifier.normal?(pin)      # => false
Sashite.Pin.Identifier.enhanced?(pin)    # => true
Sashite.Pin.Identifier.diminished?(pin)  # => false

# Side queries
Sashite.Pin.Identifier.first_player?(pin)   # => true
Sashite.Pin.Identifier.second_player?(pin)  # => false

# Terminal query
pin.terminal  # => true

# Comparison queries
{:ok, other} = Sashite.Pin.parse("k")
Sashite.Pin.Identifier.same_type?(pin, other)      # => true
Sashite.Pin.Identifier.same_side?(pin, other)      # => false
Sashite.Pin.Identifier.same_state?(pin, other)     # => false
Sashite.Pin.Identifier.same_terminal?(pin, other)  # => false
```

## API Reference

### Types

```elixir
# Identifier represents a parsed PIN with all attributes.
defmodule Sashite.Pin.Identifier do
  @type t :: %__MODULE__{
    type: atom(),      # :A to :Z
    side: :first | :second,
    state: :normal | :enhanced | :diminished,
    terminal: boolean()
  }

  # Creates an Identifier from attributes.
  # Raises ArgumentError if attributes are invalid.
  @spec new(atom(), atom(), atom(), keyword()) :: t()
  def new(type, side, state \\ :normal, opts \\ [])

  # Returns the PIN string representation.
  @spec to_string(t()) :: String.t()
  def to_string(identifier)
end
```

### Constants

```elixir
Sashite.Pin.Constants.valid_types()       # => [:A, :B, ..., :Z]
Sashite.Pin.Constants.valid_sides()       # => [:first, :second]
Sashite.Pin.Constants.valid_states()      # => [:normal, :enhanced, :diminished]
Sashite.Pin.Constants.max_string_length() # => 3
```

### Parsing

```elixir
# Parses a PIN string into an Identifier.
# Returns {:ok, identifier} or {:error, reason}.
@spec Sashite.Pin.parse(String.t()) :: {:ok, Sashite.Pin.Identifier.t()} | {:error, atom()}

# Parses a PIN string into an Identifier.
# Raises ArgumentError if the string is not valid.
@spec Sashite.Pin.parse!(String.t()) :: Sashite.Pin.Identifier.t()
```

### Validation

```elixir
# Reports whether string is a valid PIN.
@spec Sashite.Pin.valid?(String.t()) :: boolean()
```

### Transformations

All transformations return new `%Sashite.Pin.Identifier{}` structs:

```elixir
# State transformations
@spec enhance(t()) :: t()
@spec diminish(t()) :: t()
@spec normalize(t()) :: t()

# Side transformation
@spec flip(t()) :: t()

# Terminal transformations
@spec mark_terminal(t()) :: t()
@spec unmark_terminal(t()) :: t()

# Attribute changes
@spec with_type(t(), atom()) :: t()
@spec with_side(t(), atom()) :: t()
@spec with_state(t(), atom()) :: t()
@spec with_terminal(t(), boolean()) :: t()
```

### Errors

Parsing returns `{:error, reason}` tuples with these atoms:

| Reason | Cause |
|--------|-------|
| `:empty_input` | String length is 0 |
| `:input_too_long` | String exceeds 3 characters |
| `:must_contain_one_letter` | Missing or multiple letters |
| `:invalid_state_modifier` | Invalid prefix character |
| `:invalid_terminal_marker` | Invalid suffix character |

## Design Principles

- **Bounded values**: Explicit validation of types, sides, states
- **Functional style**: Pure functions, immutable structs
- **Elixir idioms**: `{:ok, result}` / `{:error, reason}` tuples, bang functions
- **Pattern matching**: Structs enable pattern matching in function heads
- **Pipe-friendly**: Transformations designed for `|>` operator
- **No dependencies**: Pure Elixir standard library only

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Official specification
- [PIN Examples](https://sashite.dev/specs/pin/1.0.0/examples/) — Usage examples

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
