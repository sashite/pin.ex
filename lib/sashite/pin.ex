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

      iex> Sashite.Pin.parse("K")
      {:ok, %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.parse!("+R")
      %Sashite.Pin{type: :R, side: :first, state: :enhanced, terminal: false}

      iex> Sashite.Pin.parse!("k^")
      %Sashite.Pin{type: :K, side: :second, state: :normal, terminal: true}

      iex> Sashite.Pin.valid?("K^")
      true

      iex> Sashite.Pin.valid?("invalid")
      false

  See the [PIN Specification](https://sashite.dev/specs/pin/1.0.0/) for details.
  """

  @type piece_type ::
          :A | :B | :C | :D | :E | :F | :G | :H | :I | :J | :K | :L | :M
          | :N | :O | :P | :Q | :R | :S | :T | :U | :V | :W | :X | :Y | :Z

  @type side :: :first | :second
  @type state :: :normal | :enhanced | :diminished

  @type t :: %__MODULE__{
          type: piece_type(),
          side: side(),
          state: state(),
          terminal: boolean()
        }

  @enforce_keys [:type, :side, :state, :terminal]
  defstruct [:type, :side, :state, :terminal]

  @valid_types ~w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)a
  @valid_sides [:first, :second]
  @valid_states [:normal, :enhanced, :diminished]

  @pin_pattern ~r/\A(?<prefix>[-+])?(?<letter>[a-zA-Z])(?<terminal>\^)?\z/

  # ==========================================================================
  # Creation and Parsing
  # ==========================================================================

  @doc """
  Creates a new PIN struct.

  ## Parameters

  - `type` - Piece type (`:A` to `:Z`)
  - `side` - Player side (`:first` or `:second`)
  - `state` - Piece state (`:normal`, `:enhanced`, or `:diminished`). Defaults to `:normal`.
  - `opts` - Options keyword list. Supports `:terminal` (boolean, defaults to `false`).

  ## Examples

      iex> Sashite.Pin.new(:K, :first)
      %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.new(:R, :second, :enhanced)
      %Sashite.Pin{type: :R, side: :second, state: :enhanced, terminal: false}

      iex> Sashite.Pin.new(:K, :first, :normal, terminal: true)
      %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: true}

  """
  @spec new(piece_type(), side(), state(), keyword()) :: t()
  def new(type, side, state \\ :normal, opts \\ []) do
    terminal = Keyword.get(opts, :terminal, false)

    validate_type!(type)
    validate_side!(side)
    validate_state!(state)

    %__MODULE__{
      type: type,
      side: side,
      state: state,
      terminal: !!terminal
    }
  end

  @doc """
  Parses a PIN string into a PIN struct.

  Returns `{:ok, pin}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Pin.parse("K")
      {:ok, %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.parse("+r")
      {:ok, %Sashite.Pin{type: :R, side: :second, state: :enhanced, terminal: false}}

      iex> Sashite.Pin.parse("K^")
      {:ok, %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: true}}

      iex> Sashite.Pin.parse("invalid")
      {:error, "Invalid PIN string: invalid"}

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(pin_string) when is_binary(pin_string) do
    case Regex.named_captures(@pin_pattern, pin_string) do
      nil ->
        {:error, "Invalid PIN string: #{pin_string}"}

      captures ->
        letter = captures["letter"]
        prefix = captures["prefix"]
        terminal_marker = captures["terminal"]

        type = letter |> String.upcase() |> String.to_atom()
        side = if letter == String.upcase(letter), do: :first, else: :second

        state =
          case prefix do
            "+" -> :enhanced
            "-" -> :diminished
            _ -> :normal
          end

        terminal = terminal_marker == "^"

        {:ok, %__MODULE__{type: type, side: side, state: state, terminal: terminal}}
    end
  end

  def parse(pin_string) do
    {:error, "Invalid PIN string: #{inspect(pin_string)}"}
  end

  @doc """
  Parses a PIN string into a PIN struct.

  Returns the PIN struct on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Pin.parse!("K")
      %Sashite.Pin{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.parse!("invalid")
      ** (ArgumentError) Invalid PIN string: invalid

  """
  @spec parse!(String.t()) :: t()
  def parse!(pin_string) do
    case parse(pin_string) do
      {:ok, pin} -> pin
      {:error, reason} -> raise ArgumentError, reason
    end
  end

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
  def valid?(pin_string) when is_binary(pin_string) do
    Regex.match?(@pin_pattern, pin_string)
  end

  def valid?(_), do: false

  # ==========================================================================
  # Conversion
  # ==========================================================================

  @doc """
  Converts a PIN struct to its string representation.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> Sashite.Pin.to_string(pin)
      "K"

      iex> pin = Sashite.Pin.new(:R, :second, :enhanced)
      iex> Sashite.Pin.to_string(pin)
      "+r"

      iex> pin = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.to_string(pin)
      "K^"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = pin) do
    prefix(pin) <> letter(pin) <> suffix(pin)
  end

  @doc """
  Returns the letter representation of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> Sashite.Pin.letter(pin)
      "K"

      iex> pin = Sashite.Pin.new(:K, :second)
      iex> Sashite.Pin.letter(pin)
      "k"

  """
  @spec letter(t()) :: String.t()
  def letter(%__MODULE__{type: type, side: :first}) do
    Atom.to_string(type)
  end

  def letter(%__MODULE__{type: type, side: :second}) do
    type |> Atom.to_string() |> String.downcase()
  end

  @doc """
  Returns the state prefix of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :enhanced)
      iex> Sashite.Pin.prefix(pin)
      "+"

      iex> pin = Sashite.Pin.new(:K, :first, :diminished)
      iex> Sashite.Pin.prefix(pin)
      "-"

      iex> pin = Sashite.Pin.new(:K, :first, :normal)
      iex> Sashite.Pin.prefix(pin)
      ""

  """
  @spec prefix(t()) :: String.t()
  def prefix(%__MODULE__{state: :enhanced}), do: "+"
  def prefix(%__MODULE__{state: :diminished}), do: "-"
  def prefix(%__MODULE__{state: :normal}), do: ""

  @doc """
  Returns the terminal suffix of the PIN.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.suffix(pin)
      "^"

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> Sashite.Pin.suffix(pin)
      ""

  """
  @spec suffix(t()) :: String.t()
  def suffix(%__MODULE__{terminal: true}), do: "^"
  def suffix(%__MODULE__{terminal: false}), do: ""

  # ==========================================================================
  # State Transformations
  # ==========================================================================

  @doc """
  Returns a new PIN with enhanced state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> enhanced = Sashite.Pin.enhance(pin)
      iex> enhanced.state
      :enhanced

  """
  @spec enhance(t()) :: t()
  def enhance(%__MODULE__{state: :enhanced} = pin), do: pin
  def enhance(%__MODULE__{} = pin), do: %{pin | state: :enhanced}

  @doc """
  Returns a new PIN with diminished state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> diminished = Sashite.Pin.diminish(pin)
      iex> diminished.state
      :diminished

  """
  @spec diminish(t()) :: t()
  def diminish(%__MODULE__{state: :diminished} = pin), do: pin
  def diminish(%__MODULE__{} = pin), do: %{pin | state: :diminished}

  @doc """
  Returns a new PIN with normal state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :enhanced)
      iex> normalized = Sashite.Pin.normalize(pin)
      iex> normalized.state
      :normal

  """
  @spec normalize(t()) :: t()
  def normalize(%__MODULE__{state: :normal} = pin), do: pin
  def normalize(%__MODULE__{} = pin), do: %{pin | state: :normal}

  # ==========================================================================
  # Side Transformations
  # ==========================================================================

  @doc """
  Returns a new PIN with the opposite side.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> flipped = Sashite.Pin.flip(pin)
      iex> flipped.side
      :second

  """
  @spec flip(t()) :: t()
  def flip(%__MODULE__{side: :first} = pin), do: %{pin | side: :second}
  def flip(%__MODULE__{side: :second} = pin), do: %{pin | side: :first}

  # ==========================================================================
  # Terminal Transformations
  # ==========================================================================

  @doc """
  Returns a new PIN marked as terminal.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> terminal = Sashite.Pin.mark_terminal(pin)
      iex> terminal.terminal
      true

  """
  @spec mark_terminal(t()) :: t()
  def mark_terminal(%__MODULE__{terminal: true} = pin), do: pin
  def mark_terminal(%__MODULE__{} = pin), do: %{pin | terminal: true}

  @doc """
  Returns a new PIN unmarked as terminal.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      iex> non_terminal = Sashite.Pin.unmark_terminal(pin)
      iex> non_terminal.terminal
      false

  """
  @spec unmark_terminal(t()) :: t()
  def unmark_terminal(%__MODULE__{terminal: false} = pin), do: pin
  def unmark_terminal(%__MODULE__{} = pin), do: %{pin | terminal: false}

  # ==========================================================================
  # Attribute Transformations
  # ==========================================================================

  @doc """
  Returns a new PIN with a different type.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> queen = Sashite.Pin.with_type(pin, :Q)
      iex> queen.type
      :Q

  """
  @spec with_type(t(), piece_type()) :: t()
  def with_type(%__MODULE__{type: type} = pin, type), do: pin

  def with_type(%__MODULE__{} = pin, new_type) do
    validate_type!(new_type)
    %{pin | type: new_type}
  end

  @doc """
  Returns a new PIN with a different side.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> second = Sashite.Pin.with_side(pin, :second)
      iex> second.side
      :second

  """
  @spec with_side(t(), side()) :: t()
  def with_side(%__MODULE__{side: side} = pin, side), do: pin

  def with_side(%__MODULE__{} = pin, new_side) do
    validate_side!(new_side)
    %{pin | side: new_side}
  end

  @doc """
  Returns a new PIN with a different state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> enhanced = Sashite.Pin.with_state(pin, :enhanced)
      iex> enhanced.state
      :enhanced

  """
  @spec with_state(t(), state()) :: t()
  def with_state(%__MODULE__{state: state} = pin, state), do: pin

  def with_state(%__MODULE__{} = pin, new_state) do
    validate_state!(new_state)
    %{pin | state: new_state}
  end

  @doc """
  Returns a new PIN with a different terminal status.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> terminal = Sashite.Pin.with_terminal(pin, true)
      iex> terminal.terminal
      true

  """
  @spec with_terminal(t(), boolean()) :: t()
  def with_terminal(%__MODULE__{terminal: terminal} = pin, terminal), do: pin
  def with_terminal(%__MODULE__{} = pin, new_terminal), do: %{pin | terminal: !!new_terminal}

  # ==========================================================================
  # State Queries
  # ==========================================================================

  @doc """
  Checks if the PIN has normal state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> Sashite.Pin.normal?(pin)
      true

  """
  @spec normal?(t()) :: boolean()
  def normal?(%__MODULE__{state: :normal}), do: true
  def normal?(%__MODULE__{}), do: false

  @doc """
  Checks if the PIN has enhanced state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :enhanced)
      iex> Sashite.Pin.enhanced?(pin)
      true

  """
  @spec enhanced?(t()) :: boolean()
  def enhanced?(%__MODULE__{state: :enhanced}), do: true
  def enhanced?(%__MODULE__{}), do: false

  @doc """
  Checks if the PIN has diminished state.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :diminished)
      iex> Sashite.Pin.diminished?(pin)
      true

  """
  @spec diminished?(t()) :: boolean()
  def diminished?(%__MODULE__{state: :diminished}), do: true
  def diminished?(%__MODULE__{}), do: false

  # ==========================================================================
  # Side Queries
  # ==========================================================================

  @doc """
  Checks if the PIN belongs to the first player.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first)
      iex> Sashite.Pin.first_player?(pin)
      true

  """
  @spec first_player?(t()) :: boolean()
  def first_player?(%__MODULE__{side: :first}), do: true
  def first_player?(%__MODULE__{}), do: false

  @doc """
  Checks if the PIN belongs to the second player.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :second)
      iex> Sashite.Pin.second_player?(pin)
      true

  """
  @spec second_player?(t()) :: boolean()
  def second_player?(%__MODULE__{side: :second}), do: true
  def second_player?(%__MODULE__{}), do: false

  # ==========================================================================
  # Terminal Queries
  # ==========================================================================

  @doc """
  Checks if the PIN is a terminal piece.

  ## Examples

      iex> pin = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.terminal?(pin)
      true

  """
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{terminal: true}), do: true
  def terminal?(%__MODULE__{}), do: false

  # ==========================================================================
  # Comparison
  # ==========================================================================

  @doc """
  Checks if two PINs have the same type.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("K")
      iex> pin2 = Sashite.Pin.parse!("k")
      iex> Sashite.Pin.same_type?(pin1, pin2)
      true

  """
  @spec same_type?(t(), t()) :: boolean()
  def same_type?(%__MODULE__{type: type}, %__MODULE__{type: type}), do: true
  def same_type?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two PINs have the same side.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("K")
      iex> pin2 = Sashite.Pin.parse!("Q")
      iex> Sashite.Pin.same_side?(pin1, pin2)
      true

  """
  @spec same_side?(t(), t()) :: boolean()
  def same_side?(%__MODULE__{side: side}, %__MODULE__{side: side}), do: true
  def same_side?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two PINs have the same state.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("+K")
      iex> pin2 = Sashite.Pin.parse!("+Q")
      iex> Sashite.Pin.same_state?(pin1, pin2)
      true

  """
  @spec same_state?(t(), t()) :: boolean()
  def same_state?(%__MODULE__{state: state}, %__MODULE__{state: state}), do: true
  def same_state?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two PINs have the same terminal status.

  ## Examples

      iex> pin1 = Sashite.Pin.parse!("K^")
      iex> pin2 = Sashite.Pin.parse!("Q^")
      iex> Sashite.Pin.same_terminal?(pin1, pin2)
      true

  """
  @spec same_terminal?(t(), t()) :: boolean()
  def same_terminal?(%__MODULE__{terminal: terminal}, %__MODULE__{terminal: terminal}), do: true
  def same_terminal?(%__MODULE__{}, %__MODULE__{}), do: false

  # ==========================================================================
  # Private Validation
  # ==========================================================================

  defp validate_type!(type) do
    unless type in @valid_types do
      raise ArgumentError, "Type must be an atom from :A to :Z, got: #{inspect(type)}"
    end
  end

  defp validate_side!(side) do
    unless side in @valid_sides do
      raise ArgumentError, "Side must be :first or :second, got: #{inspect(side)}"
    end
  end

  defp validate_state!(state) do
    unless state in @valid_states do
      raise ArgumentError, "State must be :normal, :enhanced, or :diminished, got: #{inspect(state)}"
    end
  end
end

defimpl String.Chars, for: Sashite.Pin do
  def to_string(pin) do
    Sashite.Pin.to_string(pin)
  end
end

defimpl Inspect, for: Sashite.Pin do
  def inspect(pin, _opts) do
    "#Sashite.Pin<#{Sashite.Pin.to_string(pin)}>"
  end
end
