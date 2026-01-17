defmodule Sashite.PinTest do
  use ExUnit.Case, async: true

  doctest Sashite.Pin

  # ===========================================================================
  # parse/1
  # ===========================================================================

  describe "parse/1" do
    test "returns {:ok, identifier} for valid input" do
      assert {:ok, pin} = Sashite.Pin.parse("K")
      assert %Sashite.Pin.Identifier{} = pin
      assert pin.type == :K
      assert pin.side == :first
      assert pin.state == :normal
      assert pin.terminal == false
    end

    test "returns {:ok, identifier} with all attributes" do
      assert {:ok, pin} = Sashite.Pin.parse("+K^")
      assert pin.type == :K
      assert pin.side == :first
      assert pin.state == :enhanced
      assert pin.terminal == true
    end

    test "returns {:error, reason} for invalid input" do
      assert {:error, :empty_input} = Sashite.Pin.parse("")
      assert {:error, :input_too_long} = Sashite.Pin.parse("invalid")
      assert {:error, :must_contain_one_letter} = Sashite.Pin.parse("+")
      assert {:error, :invalid_state_modifier} = Sashite.Pin.parse("*K")
      assert {:error, :invalid_terminal_marker} = Sashite.Pin.parse("K!")
    end
  end

  # ===========================================================================
  # parse!/1
  # ===========================================================================

  describe "parse!/1" do
    test "returns identifier for valid input" do
      pin = Sashite.Pin.parse!("K")
      assert %Sashite.Pin.Identifier{} = pin
      assert pin.type == :K
    end

    test "returns identifier with all attributes" do
      pin = Sashite.Pin.parse!("+K^")
      assert pin.state == :enhanced
      assert pin.terminal == true
    end

    test "raises ArgumentError for empty input" do
      assert_raise ArgumentError, "empty input", fn ->
        Sashite.Pin.parse!("")
      end
    end

    test "raises ArgumentError for input too long" do
      assert_raise ArgumentError, "input exceeds 3 characters", fn ->
        Sashite.Pin.parse!("invalid")
      end
    end

    test "raises ArgumentError for missing letter" do
      assert_raise ArgumentError, "must contain exactly one letter", fn ->
        Sashite.Pin.parse!("+")
      end
    end

    test "raises ArgumentError for invalid state modifier" do
      assert_raise ArgumentError, "invalid state modifier", fn ->
        Sashite.Pin.parse!("*K")
      end
    end

    test "raises ArgumentError for invalid terminal marker" do
      assert_raise ArgumentError, "invalid terminal marker", fn ->
        Sashite.Pin.parse!("K!")
      end
    end

    test "raises ArgumentError for non-string input" do
      assert_raise ArgumentError, "input must be a string", fn ->
        Sashite.Pin.parse!(123)
      end
    end

    test "raises ArgumentError with inspect for unknown error" do
      # This tests the fallback clause - we can't easily trigger it
      # but we ensure the function exists and handles edge cases
      assert_raise ArgumentError, fn ->
        Sashite.Pin.parse!(nil)
      end
    end
  end

  # ===========================================================================
  # valid?/1
  # ===========================================================================

  describe "valid?/1" do
    test "returns true for valid simple letter" do
      assert Sashite.Pin.valid?("K") == true
      assert Sashite.Pin.valid?("k") == true
    end

    test "returns true for valid with modifiers" do
      assert Sashite.Pin.valid?("+R") == true
      assert Sashite.Pin.valid?("-p") == true
      assert Sashite.Pin.valid?("K^") == true
      assert Sashite.Pin.valid?("+K^") == true
    end

    test "returns false for invalid inputs" do
      assert Sashite.Pin.valid?("") == false
      assert Sashite.Pin.valid?("invalid") == false
      assert Sashite.Pin.valid?(nil) == false
    end
  end
end
