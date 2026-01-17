defmodule Sashite.Pin.Parser do
  @moduledoc """
  Security-hardened parser for PIN (Piece Identifier Notation) strings.

  This module provides parsing and validation functions for PIN strings.
  The parser uses byte-level validation without regex to prevent ReDoS attacks.

  ## Format

      [<state-modifier>]<letter>[<terminal-marker>]

  - **Letter** (`A-Z`, `a-z`): Piece type and side
  - **State modifier**: `+` (enhanced), `-` (diminished), or none (normal)
  - **Terminal marker**: `^` (terminal piece) or none

  ## Examples

      iex> Sashite.Pin.Parser.parse("K")
      {:ok, %{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.Parser.parse("+r")
      {:ok, %{type: :R, side: :second, state: :enhanced, terminal: false}}

      iex> Sashite.Pin.Parser.parse("")
      {:error, :empty_input}

  """

  alias Sashite.Pin.Constants

  # ===========================================================================
  # Public API
  # ===========================================================================

  @doc """
  Parses a PIN string into a map of components.

  Returns `{:ok, components}` on success or `{:error, reason}` on failure.

  ## Components

  The returned map contains:
  - `:type` - Piece type as uppercase atom (`:A` to `:Z`)
  - `:side` - Player side (`:first` or `:second`)
  - `:state` - Piece state (`:normal`, `:enhanced`, or `:diminished`)
  - `:terminal` - Terminal status (`true` or `false`)

  ## Examples

      iex> Sashite.Pin.Parser.parse("K")
      {:ok, %{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.Parser.parse("k")
      {:ok, %{type: :K, side: :second, state: :normal, terminal: false}}

      iex> Sashite.Pin.Parser.parse("+R")
      {:ok, %{type: :R, side: :first, state: :enhanced, terminal: false}}

      iex> Sashite.Pin.Parser.parse("-p")
      {:ok, %{type: :P, side: :second, state: :diminished, terminal: false}}

      iex> Sashite.Pin.Parser.parse("K^")
      {:ok, %{type: :K, side: :first, state: :normal, terminal: true}}

      iex> Sashite.Pin.Parser.parse("+K^")
      {:ok, %{type: :K, side: :first, state: :enhanced, terminal: true}}

      iex> Sashite.Pin.Parser.parse("")
      {:error, :empty_input}

      iex> Sashite.Pin.Parser.parse("invalid")
      {:error, :input_too_long}

  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, atom()}
  def parse(input) when is_binary(input) do
    with :ok <- validate_not_empty(input),
         :ok <- validate_length(input) do
      parse_components(input)
    end
  end

  def parse(_input), do: {:error, :invalid_input_type}

  @doc """
  Checks if a string is a valid PIN notation.

  ## Examples

      iex> Sashite.Pin.Parser.valid?("K")
      true

      iex> Sashite.Pin.Parser.valid?("+R")
      true

      iex> Sashite.Pin.Parser.valid?("K^")
      true

      iex> Sashite.Pin.Parser.valid?("")
      false

      iex> Sashite.Pin.Parser.valid?("invalid")
      false

      iex> Sashite.Pin.Parser.valid?(nil)
      false

  """
  @spec valid?(any()) :: boolean()
  def valid?(input) do
    case parse(input) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  # ===========================================================================
  # Private - Validation
  # ===========================================================================

  defp validate_not_empty(""), do: {:error, :empty_input}
  defp validate_not_empty(_), do: :ok

  defp validate_length(input) do
    if byte_size(input) > Constants.max_string_length() do
      {:error, :input_too_long}
    else
      :ok
    end
  end

  # ===========================================================================
  # Private - Parsing
  # ===========================================================================

  # Length 1: single letter
  defp parse_components(<<byte>>) do
    case classify_byte(byte) do
      {:letter, type, side} ->
        {:ok, %{type: type, side: side, state: :normal, terminal: false}}

      {:modifier, _} ->
        {:error, :must_contain_one_letter}

      :terminal ->
        {:error, :must_contain_one_letter}

      :invalid ->
        {:error, :must_contain_one_letter}
    end
  end

  # Length 2: modifier + letter OR letter + terminal
  defp parse_components(<<first, second>>) do
    case {classify_byte(first), classify_byte(second)} do
      # modifier + letter
      {{:modifier, state}, {:letter, type, side}} ->
        {:ok, %{type: type, side: side, state: state, terminal: false}}

      # letter + terminal
      {{:letter, type, side}, :terminal} ->
        {:ok, %{type: type, side: side, state: :normal, terminal: true}}

      # modifier + non-letter
      {{:modifier, _}, _} ->
        {:error, :must_contain_one_letter}

      # letter + invalid
      {{:letter, _, _}, _} ->
        {:error, :invalid_terminal_marker}

      # invalid first byte (not letter, not modifier) -> invalid state modifier
      {:invalid, _} ->
        {:error, :invalid_state_modifier}

      # terminal marker at start -> invalid state modifier
      {:terminal, _} ->
        {:error, :invalid_state_modifier}
    end
  end

  # Length 3: modifier + letter + terminal
  defp parse_components(<<first, second, third>>) do
    case {classify_byte(first), classify_byte(second), classify_byte(third)} do
      {{:modifier, state}, {:letter, type, side}, :terminal} ->
        {:ok, %{type: type, side: side, state: state, terminal: true}}

      {{:modifier, _}, {:letter, _, _}, _} ->
        {:error, :invalid_terminal_marker}

      {{:modifier, _}, _, _} ->
        {:error, :must_contain_one_letter}

      {{:letter, _, _}, _, _} ->
        {:error, :invalid_terminal_marker}

      # invalid first byte (not letter, not modifier) -> invalid state modifier
      {:invalid, _, _} ->
        {:error, :invalid_state_modifier}

      # terminal marker at start -> invalid state modifier
      {:terminal, _, _} ->
        {:error, :invalid_state_modifier}
    end
  end

  # Fallback (should not reach due to length validation)
  defp parse_components(_), do: {:error, :invalid_input}

  # ===========================================================================
  # Private - Byte Classification
  # ===========================================================================

  # Uppercase letters (A-Z: 0x41-0x5A)
  defp classify_byte(byte) when byte >= 0x41 and byte <= 0x5A do
    type = <<byte>> |> String.to_atom()
    {:letter, type, :first}
  end

  # Lowercase letters (a-z: 0x61-0x7A)
  defp classify_byte(byte) when byte >= 0x61 and byte <= 0x7A do
    type = <<byte>> |> String.upcase() |> String.to_atom()
    {:letter, type, :second}
  end

  # Enhanced modifier (+: 0x2B)
  defp classify_byte(0x2B), do: {:modifier, :enhanced}

  # Diminished modifier (-: 0x2D)
  defp classify_byte(0x2D), do: {:modifier, :diminished}

  # Terminal marker (^: 0x5E)
  defp classify_byte(0x5E), do: :terminal

  # Any other byte is invalid
  defp classify_byte(_), do: :invalid
end
