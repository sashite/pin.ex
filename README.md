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
alias Sashite.Pin.Identifier

# Parse PIN strings
{:ok, identifier} = Identifier.parse("K")
identifier.type      # => :K
identifier.side      # => :first
identifier.state     # => :normal
identifier.terminal  # => false

Identifier.to_string(identifier)  # => "K"

# Parse with pattern matching
{:ok, king} = Identifier.parse("K^")      # Terminal king
{:ok, rook} = Identifier.parse("+R")      # Enhanced rook
{:ok, pawn} = Identifier.parse("-p")      # Diminished second player pawn

# Bang version for direct access
identifier = Identifier.parse!("K")

# Create identifiers directly
identifier = Identifier.new(:K, :first)
identifier = Identifier.new(:K, :first, :enhanced)
identifier = Identifier.new(:K, :first, :normal, terminal: true)

# Validation
Identifier.valid?("K")        # => true
Identifier.valid?("+R")       # => true
Identifier.valid?("K^")       # => true
Identifier.valid?("invalid")  # => false

# State transformations (return new structs)
enhanced = Identifier.enhance(identifier)
Identifier.to_string(enhanced)  # => "+K"

diminished = Identifier.diminish(identifier)
Identifier.to_string(diminished)  # => "-K"

normalized = Identifier.normalize(enhanced)
Identifier.to_string(normalized)  # => "K"

# Side transformation
flipped = Identifier.flip(identifier)
Identifier.to_string(flipped)  # => "k"

# Terminal transformations
terminal = Identifier.mark_terminal(identifier)
Identifier.to_string(terminal)  # => "K^"

non_terminal = Identifier.unmark_terminal(terminal)
Identifier.to_string(non_terminal)  # => "K"

# Type transformation
queen = Identifier.with_type(identifier, :Q)
Identifier.to_string(queen)  # => "Q"

# State queries
Identifier.normal?(identifier)     # => true
Identifier.enhanced?(enhanced)     # => true
Identifier.diminished?(diminished) # => true

# Side queries
Identifier.first_player?(identifier)  # => true
Identifier.second_player?(flipped)    # => true

# Terminal queries
Identifier.terminal?(terminal)  # => true

# Comparison
king1 = Identifier.parse!("K")
king2 = Identifier.parse!("k")

Identifier.same_type?(king1, king2)  # => true
Identifier.same_side?(king1, king2)  # => false
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
Identifier.parse(pin_string)   # => {:ok, %Identifier{}} | {:error, reason}
Identifier.parse!(pin_string)  # => %Identifier{} | raises ArgumentError
Identifier.valid?(pin_string)  # => boolean
```

### Creation

```elixir
Identifier.new(type, side)
Identifier.new(type, side, state)
Identifier.new(type, side, state, terminal: boolean)
```

### Conversion

```elixir
Identifier.to_string(identifier)  # => String.t()
```

### Transformations

All transformations return new `%Identifier{}` structs:

```elixir
# State
Identifier.enhance(identifier)
Identifier.diminish(identifier)
Identifier.normalize(identifier)

# Side
Identifier.flip(identifier)

# Terminal
Identifier.mark_terminal(identifier)
Identifier.unmark_terminal(identifier)

# Attribute changes
Identifier.with_type(identifier, new_type)
Identifier.with_side(identifier, new_side)
Identifier.with_state(identifier, new_state)
Identifier.with_terminal(identifier, boolean)
```

### Queries

```elixir
# State
Identifier.normal?(identifier)
Identifier.enhanced?(identifier)
Identifier.diminished?(identifier)

# Side
Identifier.first_player?(identifier)
Identifier.second_player?(identifier)

# Terminal
Identifier.terminal?(identifier)

# Comparison
Identifier.same_type?(id1, id2)
Identifier.same_side?(id1, id2)
Identifier.same_state?(id1, id2)
Identifier.same_terminal?(id1, id2)
```

## Data Structure

```elixir
%Sashite.Pin.Identifier{
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
