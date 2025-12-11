defmodule Sashite.Pin.IdentifierTest do
  use ExUnit.Case, async: true

  alias Sashite.Pin.Identifier

  doctest Sashite.Pin.Identifier

  describe "parse/1" do
    test "parses simple uppercase letter" do
      assert {:ok, id} = Identifier.parse("K")
      assert id.type == :K
      assert id.side == :first
      assert id.state == :normal
      assert id.terminal == false
    end

    test "parses simple lowercase letter" do
      assert {:ok, id} = Identifier.parse("k")
      assert id.type == :K
      assert id.side == :second
      assert id.state == :normal
      assert id.terminal == false
    end

    test "parses enhanced state" do
      assert {:ok, id} = Identifier.parse("+R")
      assert id.type == :R
      assert id.side == :first
      assert id.state == :enhanced
    end

    test "parses diminished state" do
      assert {:ok, id} = Identifier.parse("-p")
      assert id.type == :P
      assert id.side == :second
      assert id.state == :diminished
    end

    test "parses terminal marker" do
      assert {:ok, id} = Identifier.parse("K^")
      assert id.type == :K
      assert id.side == :first
      assert id.terminal == true
    end

    test "parses enhanced terminal" do
      assert {:ok, id} = Identifier.parse("+K^")
      assert id.type == :K
      assert id.side == :first
      assert id.state == :enhanced
      assert id.terminal == true
    end

    test "parses diminished terminal" do
      assert {:ok, id} = Identifier.parse("-k^")
      assert id.type == :K
      assert id.side == :second
      assert id.state == :diminished
      assert id.terminal == true
    end

    test "returns error for invalid string" do
      assert {:error, _} = Identifier.parse("invalid")
      assert {:error, _} = Identifier.parse("KK")
      assert {:error, _} = Identifier.parse("++K")
      assert {:error, _} = Identifier.parse("")
      assert {:error, _} = Identifier.parse("1")
    end

    test "returns error for non-string input" do
      assert {:error, _} = Identifier.parse(123)
      assert {:error, _} = Identifier.parse(nil)
    end
  end

  describe "parse!/1" do
    test "returns identifier for valid PIN" do
      id = Identifier.parse!("K")
      assert id.type == :K
    end

    test "raises ArgumentError for invalid PIN" do
      assert_raise ArgumentError, fn ->
        Identifier.parse!("invalid")
      end
    end
  end

  describe "valid?/1" do
    test "returns true for valid PIN strings" do
      assert Identifier.valid?("K")
      assert Identifier.valid?("k")
      assert Identifier.valid?("+R")
      assert Identifier.valid?("-p")
      assert Identifier.valid?("K^")
      assert Identifier.valid?("+K^")
      assert Identifier.valid?("-k^")
    end

    test "returns false for invalid strings" do
      refute Identifier.valid?("invalid")
      refute Identifier.valid?("KK")
      refute Identifier.valid?("++K")
      refute Identifier.valid?("")
      refute Identifier.valid?("1")
      refute Identifier.valid?(nil)
    end
  end

  describe "new/4" do
    test "creates identifier with defaults" do
      id = Identifier.new(:K, :first)
      assert id.type == :K
      assert id.side == :first
      assert id.state == :normal
      assert id.terminal == false
    end

    test "creates identifier with state" do
      id = Identifier.new(:R, :second, :enhanced)
      assert id.state == :enhanced
    end

    test "creates identifier with terminal" do
      id = Identifier.new(:K, :first, :normal, terminal: true)
      assert id.terminal == true
    end

    test "raises for invalid type" do
      assert_raise ArgumentError, fn ->
        Identifier.new(:invalid, :first)
      end
    end

    test "raises for invalid side" do
      assert_raise ArgumentError, fn ->
        Identifier.new(:K, :invalid)
      end
    end

    test "raises for invalid state" do
      assert_raise ArgumentError, fn ->
        Identifier.new(:K, :first, :invalid)
      end
    end
  end

  describe "to_string/1" do
    test "converts normal first player" do
      id = Identifier.new(:K, :first)
      assert Identifier.to_string(id) == "K"
    end

    test "converts normal second player" do
      id = Identifier.new(:K, :second)
      assert Identifier.to_string(id) == "k"
    end

    test "converts enhanced" do
      id = Identifier.new(:R, :first, :enhanced)
      assert Identifier.to_string(id) == "+R"
    end

    test "converts diminished" do
      id = Identifier.new(:P, :second, :diminished)
      assert Identifier.to_string(id) == "-p"
    end

    test "converts terminal" do
      id = Identifier.new(:K, :first, :normal, terminal: true)
      assert Identifier.to_string(id) == "K^"
    end

    test "converts enhanced terminal" do
      id = Identifier.new(:K, :first, :enhanced, terminal: true)
      assert Identifier.to_string(id) == "+K^"
    end

    test "roundtrip preserves value" do
      pins = ["K", "k", "+R", "-p", "K^", "+K^", "-k^"]

      for pin <- pins do
        assert pin == pin |> Identifier.parse!() |> Identifier.to_string()
      end
    end
  end

  describe "state transformations" do
    test "enhance/1" do
      id = Identifier.new(:K, :first)
      enhanced = Identifier.enhance(id)
      assert enhanced.state == :enhanced
      assert id.state == :normal
    end

    test "enhance/1 is idempotent" do
      id = Identifier.new(:K, :first, :enhanced)
      assert Identifier.enhance(id) == id
    end

    test "diminish/1" do
      id = Identifier.new(:K, :first)
      diminished = Identifier.diminish(id)
      assert diminished.state == :diminished
    end

    test "normalize/1" do
      id = Identifier.new(:K, :first, :enhanced)
      normalized = Identifier.normalize(id)
      assert normalized.state == :normal
    end
  end

  describe "side transformations" do
    test "flip/1 from first to second" do
      id = Identifier.new(:K, :first)
      flipped = Identifier.flip(id)
      assert flipped.side == :second
    end

    test "flip/1 from second to first" do
      id = Identifier.new(:K, :second)
      flipped = Identifier.flip(id)
      assert flipped.side == :first
    end

    test "flip/1 preserves other attributes" do
      id = Identifier.new(:K, :first, :enhanced, terminal: true)
      flipped = Identifier.flip(id)
      assert flipped.type == :K
      assert flipped.state == :enhanced
      assert flipped.terminal == true
    end
  end

  describe "terminal transformations" do
    test "mark_terminal/1" do
      id = Identifier.new(:K, :first)
      terminal = Identifier.mark_terminal(id)
      assert terminal.terminal == true
    end

    test "mark_terminal/1 is idempotent" do
      id = Identifier.new(:K, :first, :normal, terminal: true)
      assert Identifier.mark_terminal(id) == id
    end

    test "unmark_terminal/1" do
      id = Identifier.new(:K, :first, :normal, terminal: true)
      non_terminal = Identifier.unmark_terminal(id)
      assert non_terminal.terminal == false
    end
  end

  describe "attribute transformations" do
    test "with_type/2" do
      id = Identifier.new(:K, :first)
      queen = Identifier.with_type(id, :Q)
      assert queen.type == :Q
    end

    test "with_side/2" do
      id = Identifier.new(:K, :first)
      second = Identifier.with_side(id, :second)
      assert second.side == :second
    end

    test "with_state/2" do
      id = Identifier.new(:K, :first)
      enhanced = Identifier.with_state(id, :enhanced)
      assert enhanced.state == :enhanced
    end

    test "with_terminal/2" do
      id = Identifier.new(:K, :first)
      terminal = Identifier.with_terminal(id, true)
      assert terminal.terminal == true
    end
  end

  describe "state queries" do
    test "normal?/1" do
      assert Identifier.normal?(Identifier.new(:K, :first))
      refute Identifier.normal?(Identifier.new(:K, :first, :enhanced))
    end

    test "enhanced?/1" do
      assert Identifier.enhanced?(Identifier.new(:K, :first, :enhanced))
      refute Identifier.enhanced?(Identifier.new(:K, :first))
    end

    test "diminished?/1" do
      assert Identifier.diminished?(Identifier.new(:K, :first, :diminished))
      refute Identifier.diminished?(Identifier.new(:K, :first))
    end
  end

  describe "side queries" do
    test "first_player?/1" do
      assert Identifier.first_player?(Identifier.new(:K, :first))
      refute Identifier.first_player?(Identifier.new(:K, :second))
    end

    test "second_player?/1" do
      assert Identifier.second_player?(Identifier.new(:K, :second))
      refute Identifier.second_player?(Identifier.new(:K, :first))
    end
  end

  describe "terminal queries" do
    test "terminal?/1" do
      assert Identifier.terminal?(Identifier.new(:K, :first, :normal, terminal: true))
      refute Identifier.terminal?(Identifier.new(:K, :first))
    end
  end

  describe "comparison" do
    test "same_type?/2" do
      k1 = Identifier.parse!("K")
      k2 = Identifier.parse!("k")
      q = Identifier.parse!("Q")

      assert Identifier.same_type?(k1, k2)
      refute Identifier.same_type?(k1, q)
    end

    test "same_side?/2" do
      k = Identifier.parse!("K")
      q = Identifier.parse!("Q")
      k_lower = Identifier.parse!("k")

      assert Identifier.same_side?(k, q)
      refute Identifier.same_side?(k, k_lower)
    end

    test "same_state?/2" do
      enhanced_k = Identifier.parse!("+K")
      enhanced_q = Identifier.parse!("+Q")
      normal_k = Identifier.parse!("K")

      assert Identifier.same_state?(enhanced_k, enhanced_q)
      refute Identifier.same_state?(enhanced_k, normal_k)
    end

    test "same_terminal?/2" do
      terminal_k = Identifier.parse!("K^")
      terminal_q = Identifier.parse!("Q^")
      normal_k = Identifier.parse!("K")

      assert Identifier.same_terminal?(terminal_k, terminal_q)
      refute Identifier.same_terminal?(terminal_k, normal_k)
    end
  end

  describe "String.Chars protocol" do
    test "to_string/1 works with Kernel.to_string" do
      id = Identifier.new(:K, :first, :enhanced)
      assert Kernel.to_string(id) == "+K"
    end

    test "string interpolation works" do
      id = Identifier.new(:K, :first)
      assert "Piece: #{id}" == "Piece: K"
    end
  end

  describe "Inspect protocol" do
    test "inspect shows PIN representation" do
      id = Identifier.new(:K, :first, :enhanced, terminal: true)
      assert inspect(id) == "#Sashite.Pin.Identifier<+K^>"
    end
  end
end
