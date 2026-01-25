defmodule Sashite.Pin.Constants do
  @moduledoc """
  Constants for PIN (Piece Identifier Notation).

  This module defines the valid values for PIN attributes and formatting constants.
  """

  # ===========================================================================
  # Valid Values
  # ===========================================================================

  @valid_abbrs ~w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)a
  @valid_sides ~w(first second)a
  @valid_states ~w(normal enhanced diminished)a

  # ===========================================================================
  # Limits
  # ===========================================================================

  @max_string_length 3

  # ===========================================================================
  # Formatting
  # ===========================================================================

  @enhanced_prefix "+"
  @diminished_prefix "-"
  @empty_string ""
  @terminal_suffix "^"

  # ===========================================================================
  # Public API - Valid Values
  # ===========================================================================

  @doc """
  Returns the list of valid piece name abbreviations.

  ## Examples

      iex> Sashite.Pin.Constants.valid_abbrs()
      [:A, :B, :C, :D, :E, :F, :G, :H, :I, :J, :K, :L, :M, :N, :O, :P, :Q, :R, :S, :T, :U, :V, :W, :X, :Y, :Z]

  """
  @spec valid_abbrs() :: [atom()]
  def valid_abbrs, do: @valid_abbrs

  @doc """
  Returns the list of valid player sides.

  ## Examples

      iex> Sashite.Pin.Constants.valid_sides()
      [:first, :second]

  """
  @spec valid_sides() :: [atom()]
  def valid_sides, do: @valid_sides

  @doc """
  Returns the list of valid piece states.

  ## Examples

      iex> Sashite.Pin.Constants.valid_states()
      [:normal, :enhanced, :diminished]

  """
  @spec valid_states() :: [atom()]
  def valid_states, do: @valid_states

  # ===========================================================================
  # Public API - Limits
  # ===========================================================================

  @doc """
  Returns the maximum length of a valid PIN string.

  ## Examples

      iex> Sashite.Pin.Constants.max_string_length()
      3

  """
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: @max_string_length

  # ===========================================================================
  # Public API - Formatting
  # ===========================================================================

  @doc """
  Returns the prefix for enhanced state.

  ## Examples

      iex> Sashite.Pin.Constants.enhanced_prefix()
      "+"

  """
  @spec enhanced_prefix() :: String.t()
  def enhanced_prefix, do: @enhanced_prefix

  @doc """
  Returns the prefix for diminished state.

  ## Examples

      iex> Sashite.Pin.Constants.diminished_prefix()
      "-"

  """
  @spec diminished_prefix() :: String.t()
  def diminished_prefix, do: @diminished_prefix

  @doc """
  Returns an empty string (for normal state prefix).

  ## Examples

      iex> Sashite.Pin.Constants.empty_string()
      ""

  """
  @spec empty_string() :: String.t()
  def empty_string, do: @empty_string

  @doc """
  Returns the terminal marker suffix.

  ## Examples

      iex> Sashite.Pin.Constants.terminal_suffix()
      "^"

  """
  @spec terminal_suffix() :: String.t()
  def terminal_suffix, do: @terminal_suffix

  # ===========================================================================
  # Public API - Validation Helpers
  # ===========================================================================

  @doc """
  Checks if an abbreviation is valid.

  ## Examples

      iex> Sashite.Pin.Constants.valid_abbr?(:K)
      true

      iex> Sashite.Pin.Constants.valid_abbr?(:invalid)
      false

  """
  @spec valid_abbr?(atom()) :: boolean()
  def valid_abbr?(abbr), do: abbr in @valid_abbrs

  @doc """
  Checks if a side is valid.

  ## Examples

      iex> Sashite.Pin.Constants.valid_side?(:first)
      true

      iex> Sashite.Pin.Constants.valid_side?(:invalid)
      false

  """
  @spec valid_side?(atom()) :: boolean()
  def valid_side?(side), do: side in @valid_sides

  @doc """
  Checks if a state is valid.

  ## Examples

      iex> Sashite.Pin.Constants.valid_state?(:normal)
      true

      iex> Sashite.Pin.Constants.valid_state?(:invalid)
      false

  """
  @spec valid_state?(atom()) :: boolean()
  def valid_state?(state), do: state in @valid_states
end
