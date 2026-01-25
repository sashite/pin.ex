defmodule Sashite.Pin.ConstantsTest do
  use ExUnit.Case, async: true

  alias Sashite.Pin.Constants

  doctest Sashite.Pin.Constants

  # ===========================================================================
  # Valid Abbrs
  # ===========================================================================

  describe "valid_abbrs/0" do
    test "returns all 26 uppercase letter atoms" do
      abbrs = Constants.valid_abbrs()

      assert length(abbrs) == 26
      assert :A in abbrs
      assert :Z in abbrs
      assert :K in abbrs
    end

    test "returns atoms in alphabetical order" do
      abbrs = Constants.valid_abbrs()

      assert Enum.at(abbrs, 0) == :A
      assert Enum.at(abbrs, 25) == :Z
    end
  end

  # ===========================================================================
  # Valid Sides
  # ===========================================================================

  describe "valid_sides/0" do
    test "returns :first and :second" do
      sides = Constants.valid_sides()

      assert sides == [:first, :second]
    end
  end

  # ===========================================================================
  # Valid States
  # ===========================================================================

  describe "valid_states/0" do
    test "returns :normal, :enhanced, and :diminished" do
      states = Constants.valid_states()

      assert states == [:normal, :enhanced, :diminished]
    end
  end

  # ===========================================================================
  # Max String Length
  # ===========================================================================

  describe "max_string_length/0" do
    test "returns 3" do
      assert Constants.max_string_length() == 3
    end
  end

  # ===========================================================================
  # Formatting Constants
  # ===========================================================================

  describe "enhanced_prefix/0" do
    test "returns +" do
      assert Constants.enhanced_prefix() == "+"
    end
  end

  describe "diminished_prefix/0" do
    test "returns -" do
      assert Constants.diminished_prefix() == "-"
    end
  end

  describe "empty_string/0" do
    test "returns empty string" do
      assert Constants.empty_string() == ""
    end
  end

  describe "terminal_suffix/0" do
    test "returns ^" do
      assert Constants.terminal_suffix() == "^"
    end
  end

  # ===========================================================================
  # Abbr Validation
  # ===========================================================================

  describe "valid_abbr?/1" do
    test "returns true for valid uppercase atoms A-Z" do
      assert Constants.valid_abbr?(:A) == true
      assert Constants.valid_abbr?(:K) == true
      assert Constants.valid_abbr?(:Z) == true
    end

    test "returns false for lowercase atoms" do
      assert Constants.valid_abbr?(:a) == false
      assert Constants.valid_abbr?(:k) == false
    end

    test "returns false for invalid atoms" do
      assert Constants.valid_abbr?(:invalid) == false
      assert Constants.valid_abbr?(:AA) == false
    end

    test "returns false for non-atoms" do
      assert Constants.valid_abbr?("K") == false
      assert Constants.valid_abbr?(75) == false
    end
  end

  # ===========================================================================
  # Side Validation
  # ===========================================================================

  describe "valid_side?/1" do
    test "returns true for :first" do
      assert Constants.valid_side?(:first) == true
    end

    test "returns true for :second" do
      assert Constants.valid_side?(:second) == true
    end

    test "returns false for invalid atoms" do
      assert Constants.valid_side?(:third) == false
      assert Constants.valid_side?(:invalid) == false
    end

    test "returns false for non-atoms" do
      assert Constants.valid_side?("first") == false
      assert Constants.valid_side?(1) == false
    end
  end

  # ===========================================================================
  # State Validation
  # ===========================================================================

  describe "valid_state?/1" do
    test "returns true for :normal" do
      assert Constants.valid_state?(:normal) == true
    end

    test "returns true for :enhanced" do
      assert Constants.valid_state?(:enhanced) == true
    end

    test "returns true for :diminished" do
      assert Constants.valid_state?(:diminished) == true
    end

    test "returns false for invalid atoms" do
      assert Constants.valid_state?(:promoted) == false
      assert Constants.valid_state?(:invalid) == false
    end

    test "returns false for non-atoms" do
      assert Constants.valid_state?("normal") == false
      assert Constants.valid_state?(0) == false
    end
  end
end
