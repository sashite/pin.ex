defmodule Sashite.Pin.Identifier do
  @moduledoc """
  Represents a piece identifier in PIN (Piece Identifier Notation) format.

  An identifier consists of:
  - A single ASCII letter (`A-Z` or `a-z`)
  - An optional state modifier prefix (`+` or `-`)
  - An optional terminal marker suffix (`^`)

  The letter case determines the side:
  - Uppercase (`A-Z`): first player
  - Lowercase (`a-z`): second player

  ## Examples

      iex> {:ok, id} = Sashite.Pin.Identifier.parse("K")
      iex> id.type
      :K
      iex> id.side
      :first

      iex> {:ok, id} = Sashite.Pin.Identifier.parse("+r")
      iex> id.state
      :enhanced
      iex> id.side
      :second

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

  # --- Creation and Parsing ---

  @doc """
  Creates a new Identifier struct.

  ## Parameters

  - `type` - Piece type (`:A` to `:Z`)
  - `side` - Player side (`:first` or `:second`)
  - `state` - Piece state (`:normal`, `:enhanced`, or `:diminished`). Defaults to `:normal`.
  - `opts` - Options keyword list. Supports `:terminal` (boolean, defaults to `false`).

  ## Examples

      iex> Sashite.Pin.Identifier.new(:K, :first)
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.Identifier.new(:R, :second, :enhanced)
      %Sashite.Pin.Identifier{type: :R, side: :second, state: :enhanced, terminal: false}

      iex> Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: true}

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
  Parses a PIN string into an Identifier struct.

  Returns `{:ok, identifier}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> Sashite.Pin.Identifier.parse("K")
      {:ok, %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}}

      iex> Sashite.Pin.Identifier.parse("+r")
      {:ok, %Sashite.Pin.Identifier{type: :R, side: :second, state: :enhanced, terminal: false}}

      iex> Sashite.Pin.Identifier.parse("K^")
      {:ok, %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: true}}

      iex> Sashite.Pin.Identifier.parse("invalid")
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
  Parses a PIN string into an Identifier struct.

  Returns the identifier on success, raises `ArgumentError` on failure.

  ## Examples

      iex> Sashite.Pin.Identifier.parse!("K")
      %Sashite.Pin.Identifier{type: :K, side: :first, state: :normal, terminal: false}

      iex> Sashite.Pin.Identifier.parse!("invalid")
      ** (ArgumentError) Invalid PIN string: invalid

  """
  @spec parse!(String.t()) :: t()
  def parse!(pin_string) do
    case parse(pin_string) do
      {:ok, identifier} -> identifier
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Checks if a string is a valid PIN notation.

  ## Examples

      iex> Sashite.Pin.Identifier.valid?("K")
      true

      iex> Sashite.Pin.Identifier.valid?("+R")
      true

      iex> Sashite.Pin.Identifier.valid?("K^")
      true

      iex> Sashite.Pin.Identifier.valid?("invalid")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(pin_string) when is_binary(pin_string) do
    Regex.match?(@pin_pattern, pin_string)
  end

  def valid?(_), do: false

  # --- Conversion ---

  @doc """
  Converts an Identifier to its PIN string representation.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.to_string(id)
      "K"

      iex> id = Sashite.Pin.Identifier.new(:R, :second, :enhanced)
      iex> Sashite.Pin.Identifier.to_string(id)
      "+r"

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.Identifier.to_string(id)
      "K^"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = identifier) do
    prefix(identifier) <> letter(identifier) <> suffix(identifier)
  end

  @doc """
  Returns the letter representation of the identifier.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.letter(id)
      "K"

      iex> id = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.letter(id)
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
  Returns the state prefix of the identifier.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> Sashite.Pin.Identifier.prefix(id)
      "+"

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :diminished)
      iex> Sashite.Pin.Identifier.prefix(id)
      "-"

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :normal)
      iex> Sashite.Pin.Identifier.prefix(id)
      ""

  """
  @spec prefix(t()) :: String.t()
  def prefix(%__MODULE__{state: :enhanced}), do: "+"
  def prefix(%__MODULE__{state: :diminished}), do: "-"
  def prefix(%__MODULE__{state: :normal}), do: ""

  @doc """
  Returns the terminal suffix of the identifier.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.Identifier.suffix(id)
      "^"

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.suffix(id)
      ""

  """
  @spec suffix(t()) :: String.t()
  def suffix(%__MODULE__{terminal: true}), do: "^"
  def suffix(%__MODULE__{terminal: false}), do: ""

  # --- State Transformations ---

  @doc """
  Returns a new identifier with enhanced state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> enhanced = Sashite.Pin.Identifier.enhance(id)
      iex> enhanced.state
      :enhanced

  """
  @spec enhance(t()) :: t()
  def enhance(%__MODULE__{state: :enhanced} = identifier), do: identifier
  def enhance(%__MODULE__{} = identifier), do: %{identifier | state: :enhanced}

  @doc """
  Returns a new identifier with diminished state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> diminished = Sashite.Pin.Identifier.diminish(id)
      iex> diminished.state
      :diminished

  """
  @spec diminish(t()) :: t()
  def diminish(%__MODULE__{state: :diminished} = identifier), do: identifier
  def diminish(%__MODULE__{} = identifier), do: %{identifier | state: :diminished}

  @doc """
  Returns a new identifier with normal state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> normalized = Sashite.Pin.Identifier.normalize(id)
      iex> normalized.state
      :normal

  """
  @spec normalize(t()) :: t()
  def normalize(%__MODULE__{state: :normal} = identifier), do: identifier
  def normalize(%__MODULE__{} = identifier), do: %{identifier | state: :normal}

  # --- Side Transformations ---

  @doc """
  Returns a new identifier with the opposite side.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> flipped = Sashite.Pin.Identifier.flip(id)
      iex> flipped.side
      :second

  """
  @spec flip(t()) :: t()
  def flip(%__MODULE__{side: :first} = identifier), do: %{identifier | side: :second}
  def flip(%__MODULE__{side: :second} = identifier), do: %{identifier | side: :first}

  # --- Terminal Transformations ---

  @doc """
  Returns a new identifier marked as terminal.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> terminal = Sashite.Pin.Identifier.mark_terminal(id)
      iex> terminal.terminal
      true

  """
  @spec mark_terminal(t()) :: t()
  def mark_terminal(%__MODULE__{terminal: true} = identifier), do: identifier
  def mark_terminal(%__MODULE__{} = identifier), do: %{identifier | terminal: true}

  @doc """
  Returns a new identifier unmarked as terminal.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> non_terminal = Sashite.Pin.Identifier.unmark_terminal(id)
      iex> non_terminal.terminal
      false

  """
  @spec unmark_terminal(t()) :: t()
  def unmark_terminal(%__MODULE__{terminal: false} = identifier), do: identifier
  def unmark_terminal(%__MODULE__{} = identifier), do: %{identifier | terminal: false}

  # --- Attribute Transformations ---

  @doc """
  Returns a new identifier with a different type.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> queen = Sashite.Pin.Identifier.with_type(id, :Q)
      iex> queen.type
      :Q

  """
  @spec with_type(t(), piece_type()) :: t()
  def with_type(%__MODULE__{type: type} = identifier, type), do: identifier

  def with_type(%__MODULE__{} = identifier, new_type) do
    validate_type!(new_type)
    %{identifier | type: new_type}
  end

  @doc """
  Returns a new identifier with a different side.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> second = Sashite.Pin.Identifier.with_side(id, :second)
      iex> second.side
      :second

  """
  @spec with_side(t(), side()) :: t()
  def with_side(%__MODULE__{side: side} = identifier, side), do: identifier

  def with_side(%__MODULE__{} = identifier, new_side) do
    validate_side!(new_side)
    %{identifier | side: new_side}
  end

  @doc """
  Returns a new identifier with a different state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> enhanced = Sashite.Pin.Identifier.with_state(id, :enhanced)
      iex> enhanced.state
      :enhanced

  """
  @spec with_state(t(), state()) :: t()
  def with_state(%__MODULE__{state: state} = identifier, state), do: identifier

  def with_state(%__MODULE__{} = identifier, new_state) do
    validate_state!(new_state)
    %{identifier | state: new_state}
  end

  @doc """
  Returns a new identifier with a different terminal status.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> terminal = Sashite.Pin.Identifier.with_terminal(id, true)
      iex> terminal.terminal
      true

  """
  @spec with_terminal(t(), boolean()) :: t()
  def with_terminal(%__MODULE__{terminal: terminal} = identifier, terminal), do: identifier
  def with_terminal(%__MODULE__{} = identifier, new_terminal), do: %{identifier | terminal: !!new_terminal}

  # --- State Queries ---

  @doc """
  Checks if the identifier has normal state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.normal?(id)
      true

  """
  @spec normal?(t()) :: boolean()
  def normal?(%__MODULE__{state: :normal}), do: true
  def normal?(%__MODULE__{}), do: false

  @doc """
  Checks if the identifier has enhanced state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :enhanced)
      iex> Sashite.Pin.Identifier.enhanced?(id)
      true

  """
  @spec enhanced?(t()) :: boolean()
  def enhanced?(%__MODULE__{state: :enhanced}), do: true
  def enhanced?(%__MODULE__{}), do: false

  @doc """
  Checks if the identifier has diminished state.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :diminished)
      iex> Sashite.Pin.Identifier.diminished?(id)
      true

  """
  @spec diminished?(t()) :: boolean()
  def diminished?(%__MODULE__{state: :diminished}), do: true
  def diminished?(%__MODULE__{}), do: false

  # --- Side Queries ---

  @doc """
  Checks if the identifier belongs to the first player.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first)
      iex> Sashite.Pin.Identifier.first_player?(id)
      true

  """
  @spec first_player?(t()) :: boolean()
  def first_player?(%__MODULE__{side: :first}), do: true
  def first_player?(%__MODULE__{}), do: false

  @doc """
  Checks if the identifier belongs to the second player.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :second)
      iex> Sashite.Pin.Identifier.second_player?(id)
      true

  """
  @spec second_player?(t()) :: boolean()
  def second_player?(%__MODULE__{side: :second}), do: true
  def second_player?(%__MODULE__{}), do: false

  # --- Terminal Queries ---

  @doc """
  Checks if the identifier is a terminal piece.

  ## Examples

      iex> id = Sashite.Pin.Identifier.new(:K, :first, :normal, terminal: true)
      iex> Sashite.Pin.Identifier.terminal?(id)
      true

  """
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{terminal: true}), do: true
  def terminal?(%__MODULE__{}), do: false

  # --- Comparison ---

  @doc """
  Checks if two identifiers have the same type.

  ## Examples

      iex> id1 = Sashite.Pin.Identifier.parse!("K")
      iex> id2 = Sashite.Pin.Identifier.parse!("k")
      iex> Sashite.Pin.Identifier.same_type?(id1, id2)
      true

  """
  @spec same_type?(t(), t()) :: boolean()
  def same_type?(%__MODULE__{type: type}, %__MODULE__{type: type}), do: true
  def same_type?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two identifiers have the same side.

  ## Examples

      iex> id1 = Sashite.Pin.Identifier.parse!("K")
      iex> id2 = Sashite.Pin.Identifier.parse!("Q")
      iex> Sashite.Pin.Identifier.same_side?(id1, id2)
      true

  """
  @spec same_side?(t(), t()) :: boolean()
  def same_side?(%__MODULE__{side: side}, %__MODULE__{side: side}), do: true
  def same_side?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two identifiers have the same state.

  ## Examples

      iex> id1 = Sashite.Pin.Identifier.parse!("+K")
      iex> id2 = Sashite.Pin.Identifier.parse!("+Q")
      iex> Sashite.Pin.Identifier.same_state?(id1, id2)
      true

  """
  @spec same_state?(t(), t()) :: boolean()
  def same_state?(%__MODULE__{state: state}, %__MODULE__{state: state}), do: true
  def same_state?(%__MODULE__{}, %__MODULE__{}), do: false

  @doc """
  Checks if two identifiers have the same terminal status.

  ## Examples

      iex> id1 = Sashite.Pin.Identifier.parse!("K^")
      iex> id2 = Sashite.Pin.Identifier.parse!("Q^")
      iex> Sashite.Pin.Identifier.same_terminal?(id1, id2)
      true

  """
  @spec same_terminal?(t(), t()) :: boolean()
  def same_terminal?(%__MODULE__{terminal: terminal}, %__MODULE__{terminal: terminal}), do: true
  def same_terminal?(%__MODULE__{}, %__MODULE__{}), do: false

  # --- Private Validation ---

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

defimpl String.Chars, for: Sashite.Pin.Identifier do
  def to_string(identifier) do
    Sashite.Pin.Identifier.to_string(identifier)
  end
end

defimpl Inspect, for: Sashite.Pin.Identifier do
  def inspect(identifier, _opts) do
    "#Sashite.Pin.Identifier<#{Sashite.Pin.Identifier.to_string(identifier)}>"
  end
end
