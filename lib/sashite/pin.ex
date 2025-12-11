defmodule Sashite.Pin do
  @moduledoc """
  PIN (Piece Identifier Notation) implementation for Elixir.

  PIN provides an ASCII-based format for representing pieces in abstract strategy
  board games. It translates piece attributes from the Game Protocol into a compact,
  portable notation system.

  ## Format

      [<state-modifier>]<letter>[<terminal-marker>]

  - **Letter** (`A-Z`, `a-z`): Piece type and side
  - **State modifier**: `+` (enhanced), `-` (diminished), or none (normal)
  - **Terminal marker**: `^` (terminal piece) or none

  ## Examples

      iex> Sashite.Pin.parse("K")
      {:ok, %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.parse!("+R")
      %Sashite.Pin.Identifier{type: :R, side: :first, state: :enhanced, terminal: false}

      iex> Sashite.Pin.valid?("K^")
      true

  See the [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) for details.
  """

  alias Sashite.Pin.Identifier

  @doc """
  Parses a PIN string into an Identifier struct.

  Returns `{:ok, identifier}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Pin.parse("K")
      {:ok, %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.parse("+r")
      {:ok, %Sashite.Pin.Identifier{type: :R, side: :second, state: :enhanced, terminal: false}}

      iex> Sashite.Pin.parse("K^")
      {:ok, %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: true}}

      iex> Sashite.Pin.parse("invalid")
      {:error, "Invalid PIN string: invalid"}

  """
  @spec parse(String.t()) :: {:ok, Identifier.t()} | {:error, String.t()}
  defdelegate parse(pin_string), to: Identifier

  @doc """
  Parses a PIN string into an Identifier struct.

  Returns the identifier on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Pin.parse!("K")
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.parse!("invalid")
      ** (ArgumentError) Invalid PIN string: invalid

  """
  @spec parse!(String.t()) :: Identifier.t()
  defdelegate parse!(pin_string), to: Identifier

  @doc """
  Checks if a string is a valid PIN notation.

  ## Examples

      iex> Sashite.Pin.valid?("K")
      true

      iex> Sashite.Pin.valid?("+R")
      true

      iex> Sashite.Pin.valid?("K^")
      true

      iex> Sashite.Pin.valid?("invalid")
      false

  """
  @spec valid?(String.t()) :: boolean()
  defdelegate valid?(pin_string), to: Identifier

  @doc """
  Creates a new Identifier struct.

  ## Parameters

  - `type` - Piece type (`:A` to `:Z`)
  - `side` - Player side (`:first` or `:second`)
  - `state` - Piece state (`:normal`, `:enhanced`, or `:diminished`). Defaults to `:normal`.
  - `terminal` - Whether the piece is terminal. Defaults to `false`.

  ## Examples

      iex> Sashite.Pin.new(:K, :first)
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.new(:R, :second, :enhanced)
      %Sashite.Pin.Identifier{type: :R, side: :second, state: :enhanced, terminal: false}

      iex> Sashite.Pin.new(:K, :first, :normal, terminal: true)
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: true}

  """
  @spec new(Identifier.piece_type(), Identifier.side(), Identifier.state(), keyword()) ::
          Identifier.t()
  defdelegate new(type, side, state \\ :normal, opts \\ []), to: Identifier
end
