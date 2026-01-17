defmodule Sashite.Pin.IdentifierTest do
  use ExUnit.Case, async: true

  alias Sashite.Pin.Identifier

  doctest Sashite.Pin.Identifier

  # ===========================================================================
  # Constructor
  # ===========================================================================

  describe "new/4" do
    test "creates identifier with type and side" do
      pin = Identifier.new(:K, :first)

      assert pin.type == :K
      assert pin.side == :first
      assert pin.state == :normal
      assert pin.terminal == false
    end

    test "creates identifier with state" do
      pin = Identifier.new(:R, :second, :enhanced)

      assert pin.type == :R
      assert pin.side == :second
      assert pin.state == :enhanced
      assert pin.terminal == false
    end

    test "creates identifier with terminal" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)

      assert pin.type == :K
      assert pin.side == :first
      assert pin.state == :normal
      assert pin.terminal == true
    end

    test "creates identifier with all attributes" do
      pin = Identifier.new(:Q, :second, :diminished, terminal: true)

      assert pin.type == :Q
      assert pin.side == :second
      assert pin.state == :diminished
      assert pin.terminal == true
    end

    test "accepts all valid types A-Z" do
      for type <- ~w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)a do
        pin = Identifier.new(type, :first)
        assert pin.type == type
      end
    end

    test "raises on invalid type" do
      assert_raise ArgumentError, "type must be an atom from :A to :Z", fn ->
        Identifier.new(:invalid, :first)
      end
    end

    test "raises on lowercase type symbol" do
      assert_raise ArgumentError, "type must be an atom from :A to :Z", fn ->
        Identifier.new(:k, :first)
      end
    end

    test "raises on string type" do
      assert_raise ArgumentError, "type must be an atom from :A to :Z", fn ->
        Identifier.new("K", :first)
      end
    end

    test "raises on invalid side" do
      assert_raise ArgumentError, "side must be :first or :second", fn ->
        Identifier.new(:K, :invalid)
      end
    end

    test "raises on invalid state" do
      assert_raise ArgumentError, "state must be :normal, :enhanced, or :diminished", fn ->
        Identifier.new(:K, :first, :invalid)
      end
    end

    test "raises on non-boolean terminal" do
      assert_raise ArgumentError, "terminal must be true or false", fn ->
        Identifier.new(:K, :first, :normal, terminal: "true")
      end
    end

    test "raises on nil terminal" do
      assert_raise ArgumentError, "terminal must be true or false", fn ->
        Identifier.new(:K, :first, :normal, terminal: nil)
      end
    end

    test "raises on integer terminal" do
      assert_raise ArgumentError, "terminal must be true or false", fn ->
        Identifier.new(:K, :first, :normal, terminal: 1)
      end
    end
  end

  # ===========================================================================
  # String Conversion - to_string
  # ===========================================================================

  describe "to_string/1" do
    test "formats simple first player" do
      pin = Identifier.new(:K, :first)
      assert Identifier.to_string(pin) == "K"
    end

    test "formats simple second player" do
      pin = Identifier.new(:K, :second)
      assert Identifier.to_string(pin) == "k"
    end

    test "formats enhanced first player" do
      pin = Identifier.new(:R, :first, :enhanced)
      assert Identifier.to_string(pin) == "+R"
    end

    test "formats enhanced second player" do
      pin = Identifier.new(:R, :second, :enhanced)
      assert Identifier.to_string(pin) == "+r"
    end

    test "formats diminished first player" do
      pin = Identifier.new(:P, :first, :diminished)
      assert Identifier.to_string(pin) == "-P"
    end

    test "formats diminished second player" do
      pin = Identifier.new(:P, :second, :diminished)
      assert Identifier.to_string(pin) == "-p"
    end

    test "formats terminal first player" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      assert Identifier.to_string(pin) == "K^"
    end

    test "formats terminal second player" do
      pin = Identifier.new(:K, :second, :normal, terminal: true)
      assert Identifier.to_string(pin) == "k^"
    end

    test "formats enhanced terminal" do
      pin = Identifier.new(:K, :first, :enhanced, terminal: true)
      assert Identifier.to_string(pin) == "+K^"
    end

    test "formats diminished terminal" do
      pin = Identifier.new(:K, :second, :diminished, terminal: true)
      assert Identifier.to_string(pin) == "-k^"
    end
  end

  # ===========================================================================
  # String Conversion - Components
  # ===========================================================================

  describe "letter/1" do
    test "returns uppercase for first player" do
      pin = Identifier.new(:K, :first)
      assert Identifier.letter(pin) == "K"
    end

    test "returns lowercase for second player" do
      pin = Identifier.new(:K, :second)
      assert Identifier.letter(pin) == "k"
    end
  end

  describe "prefix/1" do
    test "returns empty for normal" do
      pin = Identifier.new(:K, :first, :normal)
      assert Identifier.prefix(pin) == ""
    end

    test "returns + for enhanced" do
      pin = Identifier.new(:K, :first, :enhanced)
      assert Identifier.prefix(pin) == "+"
    end

    test "returns - for diminished" do
      pin = Identifier.new(:K, :first, :diminished)
      assert Identifier.prefix(pin) == "-"
    end
  end

  describe "suffix/1" do
    test "returns empty for non-terminal" do
      pin = Identifier.new(:K, :first)
      assert Identifier.suffix(pin) == ""
    end

    test "returns ^ for terminal" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      assert Identifier.suffix(pin) == "^"
    end
  end

  # ===========================================================================
  # String.Chars Protocol
  # ===========================================================================

  describe "String.Chars protocol" do
    test "to_string/1 works via protocol" do
      pin = Identifier.new(:K, :first, :enhanced)
      assert to_string(pin) == "+K"
    end

    test "string interpolation works" do
      pin = Identifier.new(:K, :first)
      assert "Piece: #{pin}" == "Piece: K"
    end
  end

  # ===========================================================================
  # State Transformations
  # ===========================================================================

  describe "enhance/1" do
    test "returns enhanced identifier" do
      pin = Identifier.new(:K, :first)
      enhanced = Identifier.enhance(pin)

      assert enhanced.state == :enhanced
      assert enhanced.type == :K
      assert enhanced.side == :first
    end

    test "returns same struct if already enhanced" do
      pin = Identifier.new(:K, :first, :enhanced)
      enhanced = Identifier.enhance(pin)

      assert enhanced == pin
    end

    test "preserves terminal" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      enhanced = Identifier.enhance(pin)

      assert enhanced.terminal == true
    end
  end

  describe "diminish/1" do
    test "returns diminished identifier" do
      pin = Identifier.new(:K, :first)
      diminished = Identifier.diminish(pin)

      assert diminished.state == :diminished
    end

    test "returns same struct if already diminished" do
      pin = Identifier.new(:K, :first, :diminished)
      diminished = Identifier.diminish(pin)

      assert diminished == pin
    end
  end

  describe "normalize/1" do
    test "returns normal identifier" do
      pin = Identifier.new(:K, :first, :enhanced)
      normalized = Identifier.normalize(pin)

      assert normalized.state == :normal
    end

    test "returns same struct if already normal" do
      pin = Identifier.new(:K, :first, :normal)
      normalized = Identifier.normalize(pin)

      assert normalized == pin
    end
  end

  # ===========================================================================
  # Side Transformations
  # ===========================================================================

  describe "flip/1" do
    test "changes first to second" do
      pin = Identifier.new(:K, :first)
      flipped = Identifier.flip(pin)

      assert flipped.side == :second
      assert flipped.type == :K
    end

    test "changes second to first" do
      pin = Identifier.new(:K, :second)
      flipped = Identifier.flip(pin)

      assert flipped.side == :first
    end

    test "preserves state" do
      pin = Identifier.new(:K, :first, :enhanced)
      flipped = Identifier.flip(pin)

      assert flipped.state == :enhanced
    end

    test "preserves terminal" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      flipped = Identifier.flip(pin)

      assert flipped.terminal == true
    end
  end

  # ===========================================================================
  # Terminal Transformations
  # ===========================================================================

  describe "mark_terminal/1" do
    test "returns terminal identifier" do
      pin = Identifier.new(:K, :first)
      terminal = Identifier.mark_terminal(pin)

      assert terminal.terminal == true
    end

    test "returns same struct if already terminal" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      terminal = Identifier.mark_terminal(pin)

      assert terminal == pin
    end
  end

  describe "unmark_terminal/1" do
    test "returns non-terminal identifier" do
      pin = Identifier.new(:K, :first, :normal, terminal: true)
      non_terminal = Identifier.unmark_terminal(pin)

      assert non_terminal.terminal == false
    end

    test "returns same struct if not terminal" do
      pin = Identifier.new(:K, :first)
      non_terminal = Identifier.unmark_terminal(pin)

      assert non_terminal == pin
    end
  end

  # ===========================================================================
  # Attribute Transformations
  # ===========================================================================

  describe "with_type/2" do
    test "returns identifier with new type" do
      pin = Identifier.new(:K, :first)
      queen = Identifier.with_type(pin, :Q)

      assert queen.type == :Q
      assert queen.side == :first
    end

    test "returns same struct if same type" do
      pin = Identifier.new(:K, :first)
      same = Identifier.with_type(pin, :K)

      assert same == pin
    end

    test "raises on invalid type" do
      pin = Identifier.new(:K, :first)

      assert_raise ArgumentError, "type must be an atom from :A to :Z", fn ->
        Identifier.with_type(pin, :invalid)
      end
    end
  end

  describe "with_side/2" do
    test "returns identifier with new side" do
      pin = Identifier.new(:K, :first)
      second = Identifier.with_side(pin, :second)

      assert second.side == :second
    end

    test "returns same struct if same side" do
      pin = Identifier.new(:K, :first)
      same = Identifier.with_side(pin, :first)

      assert same == pin
    end

    test "raises on invalid side" do
      pin = Identifier.new(:K, :first)

      assert_raise ArgumentError, "side must be :first or :second", fn ->
        Identifier.with_side(pin, :third)
      end
    end
  end

  describe "with_state/2" do
    test "returns identifier with new state" do
      pin = Identifier.new(:K, :first)
      enhanced = Identifier.with_state(pin, :enhanced)

      assert enhanced.state == :enhanced
    end

    test "returns same struct if same state" do
      pin = Identifier.new(:K, :first, :normal)
      same = Identifier.with_state(pin, :normal)

      assert same == pin
    end

    test "raises on invalid state" do
      pin = Identifier.new(:K, :first)

      assert_raise ArgumentError, "state must be :normal, :enhanced, or :diminished", fn ->
        Identifier.with_state(pin, :promoted)
      end
    end
  end

  describe "with_terminal/2" do
    test "returns identifier with new terminal" do
      pin = Identifier.new(:K, :first)
      terminal = Identifier.with_terminal(pin, true)

      assert terminal.terminal == true
    end

    test "returns same struct if same terminal" do
      pin = Identifier.new(:K, :first)
      same = Identifier.with_terminal(pin, false)

      assert same == pin
    end

    test "raises on non-boolean" do
      pin = Identifier.new(:K, :first)

      assert_raise ArgumentError, "terminal must be true or false", fn ->
        Identifier.with_terminal(pin, "true")
      end
    end
  end

  # ===========================================================================
  # State Queries
  # ===========================================================================

  describe "normal?/1" do
    test "returns true for normal state" do
      pin = Identifier.new(:K, :first, :normal)
      assert Identifier.normal?(pin) == true
    end

    test "returns false for enhanced state" do
      pin = Identifier.new(:K, :first, :enhanced)
      assert Identifier.normal?(pin) == false
    end

    test "returns false for diminished state" do
      pin = Identifier.new(:K, :first, :diminished)
      assert Identifier.normal?(pin) == false
    end
  end

  describe "enhanced?/1" do
    test "returns true for enhanced state" do
      pin = Identifier.new(:K, :first, :enhanced)
      assert Identifier.enhanced?(pin) == true
    end

    test "returns false for other states" do
      assert Identifier.enhanced?(Identifier.new(:K, :first, :normal)) == false
      assert Identifier.enhanced?(Identifier.new(:K, :first, :diminished)) == false
    end
  end

  describe "diminished?/1" do
    test "returns true for diminished state" do
      pin = Identifier.new(:K, :first, :diminished)
      assert Identifier.diminished?(pin) == true
    end

    test "returns false for other states" do
      assert Identifier.diminished?(Identifier.new(:K, :first, :normal)) == false
      assert Identifier.diminished?(Identifier.new(:K, :first, :enhanced)) == false
    end
  end

  # ===========================================================================
  # Side Queries
  # ===========================================================================

  describe "first_player?/1" do
    test "returns true for first side" do
      pin = Identifier.new(:K, :first)
      assert Identifier.first_player?(pin) == true
    end

    test "returns false for second side" do
      pin = Identifier.new(:K, :second)
      assert Identifier.first_player?(pin) == false
    end
  end

  describe "second_player?/1" do
    test "returns true for second side" do
      pin = Identifier.new(:K, :second)
      assert Identifier.second_player?(pin) == true
    end

    test "returns false for first side" do
      pin = Identifier.new(:K, :first)
      assert Identifier.second_player?(pin) == false
    end
  end

  # ===========================================================================
  # Comparison Queries
  # ===========================================================================

  describe "same_type?/2" do
    test "returns true for same type" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:K, :second)

      assert Identifier.same_type?(pin1, pin2) == true
    end

    test "returns false for different type" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:Q, :first)

      assert Identifier.same_type?(pin1, pin2) == false
    end
  end

  describe "same_side?/2" do
    test "returns true for same side" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:Q, :first)

      assert Identifier.same_side?(pin1, pin2) == true
    end

    test "returns false for different side" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:K, :second)

      assert Identifier.same_side?(pin1, pin2) == false
    end
  end

  describe "same_state?/2" do
    test "returns true for same state" do
      pin1 = Identifier.new(:K, :first, :enhanced)
      pin2 = Identifier.new(:Q, :second, :enhanced)

      assert Identifier.same_state?(pin1, pin2) == true
    end

    test "returns false for different state" do
      pin1 = Identifier.new(:K, :first, :enhanced)
      pin2 = Identifier.new(:K, :first, :normal)

      assert Identifier.same_state?(pin1, pin2) == false
    end
  end

  describe "same_terminal?/2" do
    test "returns true for same terminal" do
      pin1 = Identifier.new(:K, :first, :normal, terminal: true)
      pin2 = Identifier.new(:Q, :second, :enhanced, terminal: true)

      assert Identifier.same_terminal?(pin1, pin2) == true
    end

    test "returns false for different terminal" do
      pin1 = Identifier.new(:K, :first, :normal, terminal: true)
      pin2 = Identifier.new(:K, :first, :normal, terminal: false)

      assert Identifier.same_terminal?(pin1, pin2) == false
    end
  end

  # ===========================================================================
  # Struct Equality
  # ===========================================================================

  describe "struct equality" do
    test "equal structs are equal" do
      pin1 = Identifier.new(:K, :first, :normal, terminal: false)
      pin2 = Identifier.new(:K, :first, :normal, terminal: false)

      assert pin1 == pin2
    end

    test "different type makes structs unequal" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:Q, :first)

      assert pin1 != pin2
    end

    test "different side makes structs unequal" do
      pin1 = Identifier.new(:K, :first)
      pin2 = Identifier.new(:K, :second)

      assert pin1 != pin2
    end

    test "different state makes structs unequal" do
      pin1 = Identifier.new(:K, :first, :normal)
      pin2 = Identifier.new(:K, :first, :enhanced)

      assert pin1 != pin2
    end

    test "different terminal makes structs unequal" do
      pin1 = Identifier.new(:K, :first, :normal, terminal: false)
      pin2 = Identifier.new(:K, :first, :normal, terminal: true)

      assert pin1 != pin2
    end
  end

  # ===========================================================================
  # Map Key Usage
  # ===========================================================================

  describe "map key usage" do
    test "can be used as map key" do
      pin = Identifier.new(:K, :first)
      map = %{pin => "value"}
      lookup = Identifier.new(:K, :first)

      assert map[lookup] == "value"
    end
  end
end
