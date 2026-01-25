defmodule Sashite.Pin.Identifier do
  @moduledoc """
  Represents a parsed PIN (Piece Identifier Notation) identifier.

  An Identifier encodes four attributes of a piece:
  - Abbr: the piece name abbreviation (A-Z as uppercase atom)
  - Side: the piece side (`:first` or `:second`)
  - State: the piece state (`:normal`, `:enhanced`, or `:diminished`)
  - Terminal: whether the piece is terminal (`true` or `false`)

  All structs are immutable. Transformation functions return new structs.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> pin.abbr
      :K
      iex> pin.side
      :first

      iex> pin = Sashite.Pin.Identifier.new(:R, :second, :enhanced)
      iex> Sashite.Pin.Identifier.to_string(pin)
      "+r"

  """

  alias Sashite.Pin.Constants

  @enforce_keys [:abbr, :side, :state, :terminal]
  defstruct [:abbr, :side, :state, :terminal]

  @type t :: %__MODULE__{
          abbr: atom(),
          side: :first | :second,
          state: :normal | :enhanced | :diminished,
          terminal: boolean()
        }

  # ===========================================================================
  # Constructor
  # ===========================================================================

  @doc """
  Creates a new Identifier instance.

  ## Parameters

  - `abbr` - Piece name abbreviation (`:A` to `:Z`)
  - `side` - Piece side (`:first` or `:second`)
  - `state` - Piece state (`:normal`, `:enhanced`, or `:diminished`), defaults to `:normal`
  - `opts` - Keyword options:
    - `:terminal` - Terminal status (`true` or `false`), defaults to `false`

  ## Examples

      iex> Sashite.Pin.Identifier.new(:K, :first)
      %Sashite.Pin.Identifier{abbr: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.Identifier.new(:R, :second, :enhanced)
      %Sashite.Pin.Identifier{abbr: :R, side: :second, state: :enhanced, terminal: false}

      iex> Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      %Sashite.Pin.Identifier{abbr: :K, side: :first, state: :normal, terminal: true}

  ## Raises

  - `ArgumentError` if any attribute is invalid

  """
  @spec new(atom(), atom(), atom(), keyword()) :: t()
  def new(abbr, side, state \\ :normal, opts \\ []) do
    terminal = Keyword.get(opts, :terminal, false)

    validate_abbr!(abbr)
    validate_side!(side)
    validate_state!(state)
    validate_terminal!(terminal)

    %__MODULE__{
      abbr: abbr,
      side: side,
      state: state,
      terminal: terminal
    }
  end

  # ===========================================================================
  # String Conversion
  # ===========================================================================

  @doc """
  Returns the PIN string representation.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.to_string(pin)
      "K"

      iex> pin = Sashite.Pin.Identifier.new(:R, :second, :enhanced)
      iex> Sashite.Pin.Identifier.to_string(pin)
      "+r"

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.Identifier.to_string(pin)
      "K^"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = identifier) do
    "#{prefix(identifier)}#{letter(identifier)}#{suffix(identifier)}"
  end

  @doc """
  Returns the letter component of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.letter(pin)
      "K"

      iex> pin = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.letter(pin)
      "k"

  """
  @spec letter(t()) :: String.t()
  def letter(%__MODULE__{abbr: abbr, side: :first}) do
    Atom.to_string(abbr)
  end

  def letter(%__MODULE__{abbr: abbr, side: :second}) do
    abbr |> Atom.to_string() |> String.downcase()
  end

  @doc """
  Returns the state prefix of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> Sashite.Pin.Identifier.prefix(pin)
      "+"

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :diminished)
      iex> Sashite.Pin.Identifier.prefix(pin)
      "-"

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.prefix(pin)
      ""

  """
  @spec prefix(t()) :: String.t()
  def prefix(%__MODULE__{state: :enhanced}), do: Constants.enhanced_prefix()
  def prefix(%__MODULE__{state: :diminished}), do: Constants.diminished_prefix()
  def prefix(%__MODULE__{state: :normal}), do: Constants.empty_string()

  @doc """
  Returns the terminal suffix of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.Identifier.suffix(pin)
      "^"

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.suffix(pin)
      ""

  """
  @spec suffix(t()) :: String.t()
  def suffix(%__MODULE__{terminal: true}), do: Constants.terminal_suffix()
  def suffix(%__MODULE__{terminal: false}), do: Constants.empty_string()

  # ===========================================================================
  # State Transformations
  # ===========================================================================

  @doc """
  Returns a new Identifier with enhanced state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> enhanced = Sashite.Pin.Identifier.enhance(pin)
      iex> enhanced.state
      :enhanced

  """
  @spec enhance(t()) :: t()
  def enhance(%__MODULE__{state: :enhanced} = identifier), do: identifier

  def enhance(%__MODULE__{} = identifier) do
    %{identifier | state: :enhanced}
  end

  @doc """
  Returns a new Identifier with diminished state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> diminished = Sashite.Pin.Identifier.diminish(pin)
      iex> diminished.state
      :diminished

  """
  @spec diminish(t()) :: t()
  def diminish(%__MODULE__{state: :diminished} = identifier), do: identifier

  def diminish(%__MODULE__{} = identifier) do
    %{identifier | state: :diminished}
  end

  @doc """
  Returns a new Identifier with normal state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> normalized = Sashite.Pin.Identifier.normalize(pin)
      iex> normalized.state
      :normal

  """
  @spec normalize(t()) :: t()
  def normalize(%__MODULE__{state: :normal} = identifier), do: identifier

  def normalize(%__MODULE__{} = identifier) do
    %{identifier | state: :normal}
  end

  # ===========================================================================
  # Side Transformations
  # ===========================================================================

  @doc """
  Returns a new Identifier with the opposite side.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> flipped = Sashite.Pin.Identifier.flip(pin)
      iex> flipped.side
      :second

      iex> pin = Sashite.Pin.Identifier.new(:K, :second)
      iex> flipped = Sashite.Pin.Identifier.flip(pin)
      iex> flipped.side
      :first

  """
  @spec flip(t()) :: t()
  def flip(%__MODULE__{side: :first} = identifier) do
    %{identifier | side: :second}
  end

  def flip(%__MODULE__{side: :second} = identifier) do
    %{identifier | side: :first}
  end

  # ===========================================================================
  # Terminal Transformations
  # ===========================================================================

  @doc """
  Returns a new Identifier marked as terminal.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> term = Sashite.Pin.Identifier.terminal(pin)
      iex> term.terminal
      true

  """
  @spec terminal(t()) :: t()
  def terminal(%__MODULE__{terminal: true} = identifier), do: identifier

  def terminal(%__MODULE__{} = identifier) do
    %{identifier | terminal: true}
  end

  @doc """
  Returns a new Identifier unmarked as terminal.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> non_term = Sashite.Pin.Identifier.non_terminal(pin)
      iex> non_term.terminal
      false

  """
  @spec non_terminal(t()) :: t()
  def non_terminal(%__MODULE__{terminal: false} = identifier), do: identifier

  def non_terminal(%__MODULE__{} = identifier) do
    %{identifier | terminal: false}
  end

  # ===========================================================================
  # Attribute Transformations
  # ===========================================================================

  @doc """
  Returns a new Identifier with a different abbreviation.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> queen = Sashite.Pin.Identifier.with_abbr(pin, :Q)
      iex> queen.abbr
      :Q

  ## Raises

  - `ArgumentError` if the abbreviation is invalid

  """
  @spec with_abbr(t(), atom()) :: t()
  def with_abbr(%__MODULE__{abbr: abbr} = identifier, abbr), do: identifier

  def with_abbr(%__MODULE__{} = identifier, new_abbr) do
    validate_abbr!(new_abbr)
    %{identifier | abbr: new_abbr}
  end

  @doc """
  Returns a new Identifier with a different side.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> second = Sashite.Pin.Identifier.with_side(pin, :second)
      iex> second.side
      :second

  ## Raises

  - `ArgumentError` if the side is invalid

  """
  @spec with_side(t(), atom()) :: t()
  def with_side(%__MODULE__{side: side} = identifier, side), do: identifier

  def with_side(%__MODULE__{} = identifier, new_side) do
    validate_side!(new_side)
    %{identifier | side: new_side}
  end

  @doc """
  Returns a new Identifier with a different state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> enhanced = Sashite.Pin.Identifier.with_state(pin, :enhanced)
      iex> enhanced.state
      :enhanced

  ## Raises

  - `ArgumentError` if the state is invalid

  """
  @spec with_state(t(), atom()) :: t()
  def with_state(%__MODULE__{state: state} = identifier, state), do: identifier

  def with_state(%__MODULE__{} = identifier, new_state) do
    validate_state!(new_state)
    %{identifier | state: new_state}
  end

  @doc """
  Returns a new Identifier with a different terminal status.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> term = Sashite.Pin.Identifier.with_terminal(pin, true)
      iex> term.terminal
      true

  ## Raises

  - `ArgumentError` if the terminal is not a boolean

  """
  @spec with_terminal(t(), boolean()) :: t()
  def with_terminal(%__MODULE__{terminal: terminal} = identifier, terminal), do: identifier

  def with_terminal(%__MODULE__{} = identifier, new_terminal) do
    validate_terminal!(new_terminal)
    %{identifier | terminal: new_terminal}
  end

  # ===========================================================================
  # State Queries
  # ===========================================================================

  @doc """
  Checks if the Identifier has normal state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.normal?(pin)
      true

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> Sashite.Pin.Identifier.normal?(pin)
      false

  """
  @spec normal?(t()) :: boolean()
  def normal?(%__MODULE__{state: :normal}), do: true
  def normal?(%__MODULE__{}), do: false

  @doc """
  Checks if the Identifier has enhanced state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> Sashite.Pin.Identifier.enhanced?(pin)
      true

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.enhanced?(pin)
      false

  """
  @spec enhanced?(t()) :: boolean()
  def enhanced?(%__MODULE__{state: :enhanced}), do: true
  def enhanced?(%__MODULE__{}), do: false

  @doc """
  Checks if the Identifier has diminished state.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :diminished)
      iex> Sashite.Pin.Identifier.diminished?(pin)
      true

      iex> pin = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.diminished?(pin)
      false

  """
  @spec diminished?(t()) :: boolean()
  def diminished?(%__MODULE__{state: :diminished}), do: true
  def diminished?(%__MODULE__{}), do: false

  # ===========================================================================
  # Side Queries
  # ===========================================================================

  @doc """
  Checks if the Identifier belongs to the first player.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.first_player?(pin)
      true

      iex> pin = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.first_player?(pin)
      false

  """
  @spec first_player?(t()) :: boolean()
  def first_player?(%__MODULE__{side: :first}), do: true
  def first_player?(%__MODULE__{}), do: false

  @doc """
  Checks if the Identifier belongs to the second player.

  ## Examples

      iex> pin = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.second_player?(pin)
      true

      iex> pin = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.second_player?(pin)
      false

  """
  @spec second_player?(t()) :: boolean()
  def second_player?(%__MODULE__{side: :second}), do: true
  def second_player?(%__MODULE__{}), do: false

  # ===========================================================================
  # Comparison Queries
  # ===========================================================================

  @doc """
  Checks if two Identifiers have the same abbreviation.

  ## Examples

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first)
      iex> pin2 = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.same_abbr?(pin1, pin2)
      true

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first)
      iex> pin2 = Sashite.Pin.Identifier.new(:Q, :first)
      iex> Sashite.Pin.Identifier.same_abbr?(pin1, pin2)
      false

  """
  @spec same_abbr?(t(), t()) :: boolean()
  def same_abbr?(%__MODULE__{abbr: abbr}, %__MODULE__{abbr: abbr}), do: true
  def same_abbr?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two Identifiers have the same side.

  ## Examples

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first)
      iex> pin2 = Sashite.Pin.Identifier.new(:Q, :first)
      iex> Sashite.Pin.Identifier.same_side?(pin1, pin2)
      true

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first)
      iex> pin2 = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.same_side?(pin1, pin2)
      false

  """
  @spec same_side?(t(), t()) :: boolean()
  def same_side?(%__MODULE__{side: side}, %__MODULE__{side: side}), do: true
  def same_side?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two Identifiers have the same state.

  ## Examples

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> pin2 = Sashite.Pin.Identifier.new(:Q, :second, :enhanced)
      iex> Sashite.Pin.Identifier.same_state?(pin1, pin2)
      true

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> pin2 = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.same_state?(pin1, pin2)
      false

  """
  @spec same_state?(t(), t()) :: boolean()
  def same_state?(%__MODULE__{state: state}, %__MODULE__{state: state}), do: true
  def same_state?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two Identifiers have the same terminal status.

  ## Examples

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> pin2 = Sashite.Pin.Identifier.new(:Q, :second, :enhanced, terminal: true)
      iex> Sashite.Pin.Identifier.same_terminal?(pin1, pin2)
      true

      iex> pin1 = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> pin2 = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: false)
      iex> Sashite.Pin.Identifier.same_terminal?(pin1, pin2)
      false

  """
  @spec same_terminal?(t(), t()) :: boolean()
  def same_terminal?(%__MODULE__{terminal: terminal}, %__MODULE__{terminal: terminal}), do: true
  def same_terminal?(%__MODULE__{}, %__MODULE__{}), do: false

  # ===========================================================================
  # Private Validation
  # ===========================================================================

  defp validate_abbr!(abbr) do
    unless Constants.valid_abbr?(abbr) do
      raise ArgumentError, "abbr must be an atom from :A to :Z"
    end
  end

  defp validate_side!(side) do
    unless Constants.valid_side?(side) do
      raise ArgumentError, "side must be :first or :second"
    end
  end

  defp validate_state!(state) do
    unless Constants.valid_state?(state) do
      raise ArgumentError, "state must be :normal, :enhanced, or :diminished"
    end
  end

  defp validate_terminal!(terminal) when is_boolean(terminal), do: :ok

  defp validate_terminal!(_terminal) do
    raise ArgumentError, "terminal must be true or false"
  end
end

# ===========================================================================
# String.Chars Protocol Implementation
# ===========================================================================

defimpl String.Chars, for: Sashite.Pin.Identifier do
  def to_string(identifier) do
    Sashite.Pin.Identifier.to_string(identifier)
  end
end
