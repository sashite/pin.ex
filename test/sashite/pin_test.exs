defmodule Sashite.PinTest do
  use ExUnit.Case, async: true

  doctest Sashite.Pin

  describe "parse/1" do
    test "parses simple uppercase letter" do
      assert {:ok, id} = Sashite.Pin.parse("K")
      assert id.type == :K
      assert id.side == :first
      assert id.state == :normal
      assert id.terminal == false
    end

    test "parses simple lowercase letter" do
      assert {:ok, id} = Sashite.Pin.parse("k")
      assert id.type == :K
      assert id.side == :second
      assert id.state == :normal
      assert id.terminal == false
    end

    test "parses enhanced state" do
      assert {:ok, id} = Sashite.Pin.parse("+R")
      assert id.type == :R
      assert id.side == :first
      assert id.state == :enhanced
    end

    test "parses diminished state" do
      assert {:ok, id} = Sashite.Pin.parse("-p")
      assert id.type == :P
      assert id.side == :second
      assert id.state == :diminished
    end

    test "parses terminal marker" do
      assert {:ok, id} = Sashite.Pin.parse("K^")
      assert id.type == :K
      assert id.side == :first
      assert id.terminal == true
    end

    test "parses enhanced terminal" do
      assert {:ok, id} = Sashite.Pin.parse("+K^")
      assert id.type == :K
      assert id.side == :first
      assert id.state == :enhanced
      assert id.terminal == true
    end

    test "parses diminished terminal" do
      assert {:ok, id} = Sashite.Pin.parse("-k^")
      assert id.type == :K
      assert id.side == :second
      assert id.state == :diminished
      assert id.terminal == true
    end

    test "returns error for invalid string" do
      assert {:error, _} = Sashite.Pin.parse("invalid")
      assert {:error, _} = Sashite.Pin.parse("KK")
      assert {:error, _} = Sashite.Pin.parse("++K")
      assert {:error, _} = Sashite.Pin.parse("")
      assert {:error, _} = Sashite.Pin.parse("1")
    end

    test "returns error for non-string input" do
      assert {:error, _} = Sashite.Pin.parse(123)
      assert {:error, _} = Sashite.Pin.parse(nil)
    end
  end

  describe "parse!/1" do
    test "returns identifier for valid PIN" do
      id = Sashite.Pin.parse!("K")
      assert id.type == :K
    end

    test "raises ArgumentError for invalid PIN" do
      assert_raise ArgumentError, fn ->
        Sashite.Pin.parse!("invalid")
      end
    end
  end

  describe "valid?/1" do
    test "returns true for valid PIN strings" do
      assert Sashite.Pin.valid?("K")
      assert Sashite.Pin.valid?("k")
      assert Sashite.Pin.valid?("+R")
      assert Sashite.Pin.valid?("-p")
      assert Sashite.Pin.valid?("K^")
      assert Sashite.Pin.valid?("+K^")
      assert Sashite.Pin.valid?("-k^")
    end

    test "returns false for invalid strings" do
      refute Sashite.Pin.valid?("invalid")
      refute Sashite.Pin.valid?("KK")
      refute Sashite.Pin.valid?("++K")
      refute Sashite.Pin.valid?("")
      refute Sashite.Pin.valid?("1")
      refute Sashite.Pin.valid?(nil)
    end
  end

  describe "new/4" do
    test "creates identifier with defaults" do
      id = Sashite.Pin.new(:K, :first)
      assert id.type == :K
      assert id.side == :first
      assert id.state == :normal
      assert id.terminal == false
    end

    test "creates identifier with state" do
      id = Sashite.Pin.new(:R, :second, :enhanced)
      assert id.state == :enhanced
    end

    test "creates identifier with terminal" do
      id = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      assert id.terminal == true
    end

    test "raises for invalid type" do
      assert_raise ArgumentError, fn ->
        Sashite.Pin.new(:invalid, :first)
      end
    end

    test "raises for invalid side" do
      assert_raise ArgumentError, fn ->
        Sashite.Pin.new(:K, :invalid)
      end
    end

    test "raises for invalid state" do
      assert_raise ArgumentError, fn ->
        Sashite.Pin.new(:K, :first, :invalid)
      end
    end
  end

  describe "to_string/1" do
    test "converts normal first player" do
      id = Sashite.Pin.new(:K, :first)
      assert Sashite.Pin.to_string(id) == "K"
    end

    test "converts normal second player" do
      id = Sashite.Pin.new(:K, :second)
      assert Sashite.Pin.to_string(id) == "k"
    end

    test "converts enhanced" do
      id = Sashite.Pin.new(:R, :first, :enhanced)
      assert Sashite.Pin.to_string(id) == "+R"
    end

    test "converts diminished" do
      id = Sashite.Pin.new(:P, :second, :diminished)
      assert Sashite.Pin.to_string(id) == "-p"
    end

    test "converts terminal" do
      id = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      assert Sashite.Pin.to_string(id) == "K^"
    end

    test "converts enhanced terminal" do
      id = Sashite.Pin.new(:K, :first, :enhanced, terminal: true)
      assert Sashite.Pin.to_string(id) == "+K^"
    end

    test "roundtrip preserves value" do
      pins = ["K", "k", "+R", "-p", "K^", "+K^", "-k^"]

      for pin <- pins do
        assert pin == pin |> Sashite.Pin.parse!() |> Sashite.Pin.to_string()
      end
    end
  end

  describe "state transformations" do
    test "enhance/1" do
      id = Sashite.Pin.new(:K, :first)
      enhanced = Sashite.Pin.enhance(id)
      assert enhanced.state == :enhanced
      assert id.state == :normal
    end

    test "enhance/1 is idempotent" do
      id = Sashite.Pin.new(:K, :first, :enhanced)
      assert Sashite.Pin.enhance(id) == id
    end

    test "diminish/1" do
      id = Sashite.Pin.new(:K, :first)
      diminished = Sashite.Pin.diminish(id)
      assert diminished.state == :diminished
    end

    test "normalize/1" do
      id = Sashite.Pin.new(:K, :first, :enhanced)
      normalized = Sashite.Pin.normalize(id)
      assert normalized.state == :normal
    end
  end

  describe "side transformations" do
    test "flip/1 from first to second" do
      id = Sashite.Pin.new(:K, :first)
      flipped = Sashite.Pin.flip(id)
      assert flipped.side == :second
    end

    test "flip/1 from second to first" do
      id = Sashite.Pin.new(:K, :second)
      flipped = Sashite.Pin.flip(id)
      assert flipped.side == :first
    end

    test "flip/1 preserves other attributes" do
      id = Sashite.Pin.new(:K, :first, :enhanced, terminal: true)
      flipped = Sashite.Pin.flip(id)
      assert flipped.type == :K
      assert flipped.state == :enhanced
      assert flipped.terminal == true
    end
  end

  describe "terminal transformations" do
    test "mark_terminal/1" do
      id = Sashite.Pin.new(:K, :first)
      terminal = Sashite.Pin.mark_terminal(id)
      assert terminal.terminal == true
    end

    test "mark_terminal/1 is idempotent" do
      id = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      assert Sashite.Pin.mark_terminal(id) == id
    end

    test "unmark_terminal/1" do
      id = Sashite.Pin.new(:K, :first, :normal, terminal: true)
      non_terminal = Sashite.Pin.unmark_terminal(id)
      assert non_terminal.terminal == false
    end
  end

  describe "attribute transformations" do
    test "with_type/2" do
      id = Sashite.Pin.new(:K, :first)
      queen = Sashite.Pin.with_type(id, :Q)
      assert queen.type == :Q
    end

    test "with_side/2" do
      id = Sashite.Pin.new(:K, :first)
      second = Sashite.Pin.with_side(id, :second)
      assert second.side == :second
    end

    test "with_state/2" do
      id = Sashite.Pin.new(:K, :first)
      enhanced = Sashite.Pin.with_state(id, :enhanced)
      assert enhanced.state == :enhanced
    end

    test "with_terminal/2" do
      id = Sashite.Pin.new(:K, :first)
      terminal = Sashite.Pin.with_terminal(id, true)
      assert terminal.terminal == true
    end
  end

  describe "state queries" do
    test "normal?/1" do
      assert Sashite.Pin.normal?(Sashite.Pin.new(:K, :first))
      refute Sashite.Pin.normal?(Sashite.Pin.new(:K, :first, :enhanced))
    end

    test "enhanced?/1" do
      assert Sashite.Pin.enhanced?(Sashite.Pin.new(:K, :first, :enhanced))
      refute Sashite.Pin.enhanced?(Sashite.Pin.new(:K, :first))
    end

    test "diminished?/1" do
      assert Sashite.Pin.diminished?(Sashite.Pin.new(:K, :first, :diminished))
      refute Sashite.Pin.diminished?(Sashite.Pin.new(:K, :first))
    end
  end

  describe "side queries" do
    test "first_player?/1" do
      assert Sashite.Pin.first_player?(Sashite.Pin.new(:K, :first))
      refute Sashite.Pin.first_player?(Sashite.Pin.new(:K, :second))
    end

    test "second_player?/1" do
      assert Sashite.Pin.second_player?(Sashite.Pin.new(:K, :second))
      refute Sashite.Pin.second_player?(Sashite.Pin.new(:K, :first))
    end
  end

  describe "terminal queries" do
    test "terminal?/1" do
      assert Sashite.Pin.terminal?(Sashite.Pin.new(:K, :first, :normal, terminal: true))
      refute Sashite.Pin.terminal?(Sashite.Pin.new(:K, :first))
    end
  end

  describe "comparison" do
    test "same_type?/2" do
      k1 = Sashite.Pin.parse!("K")
      k2 = Sashite.Pin.parse!("k")
      q = Sashite.Pin.parse!("Q")

      assert Sashite.Pin.same_type?(k1, k2)
      refute Sashite.Pin.same_type?(k1, q)
    end

    test "same_side?/2" do
      k = Sashite.Pin.parse!("K")
      q = Sashite.Pin.parse!("Q")
      k_lower = Sashite.Pin.parse!("k")

      assert Sashite.Pin.same_side?(k, q)
      refute Sashite.Pin.same_side?(k, k_lower)
    end

    test "same_state?/2" do
      enhanced_k = Sashite.Pin.parse!("+K")
      enhanced_q = Sashite.Pin.parse!("+Q")
      normal_k = Sashite.Pin.parse!("K")

      assert Sashite.Pin.same_state?(enhanced_k, enhanced_q)
      refute Sashite.Pin.same_state?(enhanced_k, normal_k)
    end

    test "same_terminal?/2" do
      terminal_k = Sashite.Pin.parse!("K^")
      terminal_q = Sashite.Pin.parse!("Q^")
      normal_k = Sashite.Pin.parse!("K")

      assert Sashite.Pin.same_terminal?(terminal_k, terminal_q)
      refute Sashite.Pin.same_terminal?(terminal_k, normal_k)
    end
  end

  describe "String.Chars protocol" do
    test "to_string/1 works with Kernel.to_string" do
      id = Sashite.Pin.new(:K, :first, :enhanced)
      assert Kernel.to_string(id) == "+K"
    end

    test "string interpolation works" do
      id = Sashite.Pin.new(:K, :first)
      assert "Piece: #{id}" == "Piece: K"
    end
  end

  describe "Inspect protocol" do
    test "inspect shows PIN representation" do
      id = Sashite.Pin.new(:K, :first, :enhanced, terminal: true)
      assert inspect(id) == "#Sashite.Pin<+K^>"
    end
  end
end
