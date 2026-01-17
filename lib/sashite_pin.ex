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

  ## Attributes

  A PIN token encodes exactly these attributes:

  - **Piece Name** → one ASCII letter chosen by the Game / Rule System
  - **Piece Side** → the case of that letter (uppercase = first, lowercase = second)
  - **Piece State** → an optional prefix (`+` for enhanced, `-` for diminished)
  - **Terminal status** → an optional suffix (`^`)

  ## Examples

      iex> {:ok, pin} = Sashite.Pin.parse("K")
      iex> pin.type
      :K
      iex> pin.side
      :first

      iex> {:ok, pin} = Sashite.Pin.parse("+R")
      iex> pin.state
      :enhanced

      iex> Sashite.Pin.valid?("K^")
      true

      iex> Sashite.Pin.valid?("invalid")
      false

  @see https://sashite.dev/specs/pin/1.0.0/
  """

  alias Sashite.Pin.{Identifier, Parser}

  # ===========================================================================
  # Parsing
  # ===========================================================================

  @doc """
  Parses a PIN string into an Identifier.

  Returns `{:ok, identifier}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> {:ok, pin} = Sashite.Pin.parse("K")
      iex> pin.type
      :K
      iex> pin.side
      :first
      iex> pin.state
      :normal
      iex> pin.terminal
      false

      iex> {:ok, pin} = Sashite.Pin.parse("+r")
      iex> pin.type
      :R
      iex> pin.side
      :second
      iex> pin.state
      :enhanced

      iex> {:ok, pin} = Sashite.Pin.parse("K^")
      iex> pin.terminal
      true

      iex> Sashite.Pin.parse("")
      {:error, :empty_input}

      iex> Sashite.Pin.parse("invalid")
      {:error, :input_too_long}

  ## Error Reasons

  - `:empty_input` - String length is 0
  - `:input_too_long` - String exceeds 3 characters
  - `:must_contain_one_letter` - Missing or multiple letters
  - `:invalid_state_modifier` - Invalid prefix character
  - `:invalid_terminal_marker` - Invalid suffix character

  """
  @spec parse(String.t()) :: {:ok, Identifier.t()} | {:error, atom()}
  def parse(string) do
    case Parser.parse(string) do
      {:ok, components} ->
        identifier =
          Identifier.new(
            components.type,
            components.side,
            components.state,
            terminal: components.terminal
          )

        {:ok, identifier}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a PIN string into an Identifier, raising on error.

  ## Examples

      iex> pin = Sashite.Pin.parse!("K")
      iex> pin.type
      :K

      iex> pin = Sashite.Pin.parse!("+K^")
      iex> pin.state
      :enhanced
      iex> pin.terminal
      true

  ## Raises

  - `ArgumentError` if the string is not a valid PIN

  """
  @spec parse!(String.t()) :: Identifier.t()
  def parse!(string) do
    case parse(string) do
      {:ok, identifier} ->
        identifier

      {:error, reason} ->
        raise ArgumentError, error_message(reason)
    end
  end

  # ===========================================================================
  # Validation
  # ===========================================================================

  @doc """
  Checks if a string is a valid PIN notation.

  ## Examples

      iex> Sashite.Pin.valid?("K")
      true

      iex> Sashite.Pin.valid?("+R")
      true

      iex> Sashite.Pin.valid?("K^")
      true

      iex> Sashite.Pin.valid?("+K^")
      true

      iex> Sashite.Pin.valid?("")
      false

      iex> Sashite.Pin.valid?("invalid")
      false

      iex> Sashite.Pin.valid?(nil)
      false

  """
  @spec valid?(any()) :: boolean()
  def valid?(string) do
    Parser.valid?(string)
  end

  # ===========================================================================
  # Private - Error Messages
  # ===========================================================================

  defp error_message(:empty_input), do: "empty input"
  defp error_message(:input_too_long), do: "input exceeds 3 characters"
  defp error_message(:must_contain_one_letter), do: "must contain exactly one letter"
  defp error_message(:invalid_state_modifier), do: "invalid state modifier"
  defp error_message(:invalid_terminal_marker), do: "invalid terminal marker"
  defp error_message(:invalid_input_type), do: "input must be a string"
  defp error_message(reason), do: "invalid input: #{inspect(reason)}"
end
