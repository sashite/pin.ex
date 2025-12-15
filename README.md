# Sashite.Pin

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_pin.svg)](https://hex.pm/packages/sashite_pin)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_pin)
[![License](https://img.shields.io/hexpm/l/sashite_pin.svg)](https://github.com/sashite/pin.ex/blob/main/LICENSE.md)

> **PIN** (Piece Identifier Notation) implementation for Elixir.

## What is PIN?

PIN (Piece Identifier Notation) provides an ASCII-based format for representing pieces in abstract strategy board games. PIN translates piece attributes from the [Game Protocol](https://sashite.dev/game-protocol/) into a compact, portable notation system.

This library implements the [PIN Specification v1.0.0](https://sashite.dev/specs/pin/1.0.0/).

## Installation

Add `sashite_pin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sashite_pin, "~> 1.0"}
  ]
end
```

## Usage

```elixir
# Parse PIN strings
{:ok, pin} = Sashite.Pin.parse("K")
pin.type      # => :K
pin.side      # => :first
pin.state     # => :normal
pin.terminal  # => false

Sashite.Pin.to_string(pin)  # => "K"

# Parse with pattern matching
{:ok, king} = Sashite.Pin.parse("K^")      # Terminal king
{:ok, rook} = Sashite.Pin.parse("+R")      # Enhanced rook
{:ok, pawn} = Sashite.Pin.parse("-p")      # Diminished second player pawn

# Bang version for direct access
pin = Sashite.Pin.parse!("K")

# Create identifiers directly
pin = Sashite.Pin.new(:K, :first)
pin = Sashite.Pin.new(:K, :first, :enhanced)
pin = Sashite.Pin.new(:K, :first, :normal, terminal: true)

# Validation
Sashite.Pin.valid?("K")        # => true
Sashite.Pin.valid?("+R")       # => true
Sashite.Pin.valid?("K^")       # => true
Sashite.Pin.valid?("invalid")  # => false

# State transformations (return new structs)
enhanced = Sashite.Pin.enhance(pin)
Sashite.Pin.to_string(enhanced)  # => "+K"

diminished = Sashite.Pin.diminish(pin)
Sashite.Pin.to_string(diminished)  # => "-K"

normalized = Sashite.Pin.normalize(enhanced)
Sashite.Pin.to_string(normalized)  # => "K"

# Side transformation
flipped = Sashite.Pin.flip(pin)
Sashite.Pin.to_string(flipped)  # => "k"

# Terminal transformations
terminal = Sashite.Pin.mark_terminal(pin)
Sashite.Pin.to_string(terminal)  # => "K^"

non_terminal = Sashite.Pin.unmark_terminal(terminal)
Sashite.Pin.to_string(non_terminal)  # => "K"

# Type transformation
queen = Sashite.Pin.with_type(pin, :Q)
Sashite.Pin.to_string(queen)  # => "Q"

# State queries
Sashite.Pin.normal?(pin)           # => true
Sashite.Pin.enhanced?(enhanced)    # => true
Sashite.Pin.diminished?(diminished) # => true

# Side queries
Sashite.Pin.first_player?(pin)     # => true
Sashite.Pin.second_player?(flipped) # => true

# Terminal queries
Sashite.Pin.terminal?(terminal)  # => true

# Comparison
king1 = Sashite.Pin.parse!("K")
king2 = Sashite.Pin.parse!("k")

Sashite.Pin.same_type?(king1, king2)  # => true
Sashite.Pin.same_side?(king1, king2)  # => false
```

## Format Specification

### Structure

```
[<state-modifier>]<letter>[<terminal-marker>]
```

### Components

| Component | Values | Description |
|-----------|--------|-------------|
| Letter | `A-Z`, `a-z` | Piece type and side |
| State Modifier | `+`, `-`, (none) | Enhanced, diminished, or normal |
| Terminal Marker | `^`, (none) | Terminal piece or not |

### Side Convention

- **Uppercase** (`A-Z`): First player
- **Lowercase** (`a-z`): Second player

### Examples

| PIN | Side | State | Terminal | Description |
|-----|------|-------|----------|-------------|
| `K` | First | Normal | No | Standard king |
| `K^` | First | Normal | Yes | Terminal king |
| `+R` | First | Enhanced | No | Promoted rook |
| `-p` | Second | Diminished | No | Weakened pawn |
| `+K^` | First | Enhanced | Yes | Enhanced terminal king |

## API Reference

### Parsing

```elixir
Sashite.Pin.parse(pin_string)   # => {:ok, %Sashite.Pin{}} | {:error, reason}
Sashite.Pin.parse!(pin_string)  # => %Sashite.Pin{} | raises ArgumentError
Sashite.Pin.valid?(pin_string)  # => boolean
```

### Creation

```elixir
Sashite.Pin.new(type, side)
Sashite.Pin.new(type, side, state)
Sashite.Pin.new(type, side, state, terminal: boolean)
```

### Conversion

```elixir
Sashite.Pin.to_string(pin)  # => String.t()
```

### Transformations

All transformations return new `%Sashite.Pin{}` structs:

```elixir
# State
Sashite.Pin.enhance(pin)
Sashite.Pin.diminish(pin)
Sashite.Pin.normalize(pin)

# Side
Sashite.Pin.flip(pin)

# Terminal
Sashite.Pin.mark_terminal(pin)
Sashite.Pin.unmark_terminal(pin)

# Attribute changes
Sashite.Pin.with_type(pin, new_type)
Sashite.Pin.with_side(pin, new_side)
Sashite.Pin.with_state(pin, new_state)
Sashite.Pin.with_terminal(pin, boolean)
```

### Queries

```elixir
# State
Sashite.Pin.normal?(pin)
Sashite.Pin.enhanced?(pin)
Sashite.Pin.diminished?(pin)

# Side
Sashite.Pin.first_player?(pin)
Sashite.Pin.second_player?(pin)

# Terminal
Sashite.Pin.terminal?(pin)

# Comparison
Sashite.Pin.same_type?(pin1, pin2)
Sashite.Pin.same_side?(pin1, pin2)
Sashite.Pin.same_state?(pin1, pin2)
Sashite.Pin.same_terminal?(pin1, pin2)
```

## Data Structure

```elixir
%Sashite.Pin{
  type: :A..:Z,           # Piece type (always uppercase atom)
  side: :first | :second, # Player side
  state: :normal | :enhanced | :diminished,
  terminal: boolean()
}
```

## Protocol Mapping

Following the [Game Protocol](https://sashite.dev/game-protocol/):

| Protocol Attribute | PIN Encoding |
|-------------------|--------------|
| Piece Name | ASCII letter choice |
| Piece Side | Letter case |
| Piece State | Optional prefix (`+`/`-`) |
| Terminal Status | Optional suffix (`^`) |

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PNN](https://sashite.dev/specs/pnn/) — Piece Name Notation
- [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) — Official specification

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
