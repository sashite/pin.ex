defmodule Sashite.Pin.ParserTest do
  use ExUnit.Case, async: true

  alias Sashite.Pin.Parser

  doctest Sashite.Pin.Parser

  # ===========================================================================
  # Valid Inputs - Simple Letters
  # ===========================================================================

  describe "parse/1 with simple letters" do
    test "parses uppercase letter K" do
      assert {:ok, result} = Parser.parse("K")

      assert result.abbr == :K
      assert result.side == :first
      assert result.state == :normal
      assert result.terminal == false
    end

    test "parses lowercase letter k" do
      assert {:ok, result} = Parser.parse("k")

      assert result.abbr == :K
      assert result.side == :second
      assert result.state == :normal
      assert result.terminal == false
    end

    test "parses all uppercase letters A-Z" do
      for letter <- ?A..?Z do
        input = <<letter>>
        expected_abbr = String.to_atom(input)

        assert {:ok, result} = Parser.parse(input)
        assert result.abbr == expected_abbr
        assert result.side == :first
      end
    end

    test "parses all lowercase letters a-z" do
      for letter <- ?a..?z do
        input = <<letter>>
        expected_abbr = input |> String.upcase() |> String.to_atom()

        assert {:ok, result} = Parser.parse(input)
        assert result.abbr == expected_abbr
        assert result.side == :second
      end
    end
  end

  # ===========================================================================
  # Valid Inputs - State Modifiers
  # ===========================================================================

  describe "parse/1 with state modifiers" do
    test "parses enhanced uppercase +R" do
      assert {:ok, result} = Parser.parse("+R")

      assert result.abbr == :R
      assert result.side == :first
      assert result.state == :enhanced
      assert result.terminal == false
    end

    test "parses enhanced lowercase +r" do
      assert {:ok, result} = Parser.parse("+r")

      assert result.abbr == :R
      assert result.side == :second
      assert result.state == :enhanced
    end

    test "parses diminished uppercase -P" do
      assert {:ok, result} = Parser.parse("-P")

      assert result.abbr == :P
      assert result.side == :first
      assert result.state == :diminished
    end

    test "parses diminished lowercase -p" do
      assert {:ok, result} = Parser.parse("-p")

      assert result.abbr == :P
      assert result.side == :second
      assert result.state == :diminished
    end
  end

  # ===========================================================================
  # Valid Inputs - Terminal Marker
  # ===========================================================================

  describe "parse/1 with terminal marker" do
    test "parses terminal uppercase K^" do
      assert {:ok, result} = Parser.parse("K^")

      assert result.abbr == :K
      assert result.side == :first
      assert result.state == :normal
      assert result.terminal == true
    end

    test "parses terminal lowercase k^" do
      assert {:ok, result} = Parser.parse("k^")

      assert result.abbr == :K
      assert result.side == :second
      assert result.terminal == true
    end
  end

  # ===========================================================================
  # Valid Inputs - Combined
  # ===========================================================================

  describe "parse/1 with combined modifiers" do
    test "parses enhanced terminal +K^" do
      assert {:ok, result} = Parser.parse("+K^")

      assert result.abbr == :K
      assert result.side == :first
      assert result.state == :enhanced
      assert result.terminal == true
    end

    test "parses diminished terminal -k^" do
      assert {:ok, result} = Parser.parse("-k^")

      assert result.abbr == :K
      assert result.side == :second
      assert result.state == :diminished
      assert result.terminal == true
    end
  end

  # ===========================================================================
  # valid?/1
  # ===========================================================================

  describe "valid?/1" do
    test "returns true for valid simple letter" do
      assert Parser.valid?("K") == true
      assert Parser.valid?("k") == true
    end

    test "returns true for valid with modifiers" do
      assert Parser.valid?("+R") == true
      assert Parser.valid?("-p") == true
      assert Parser.valid?("K^") == true
      assert Parser.valid?("+K^") == true
    end

    test "returns false for invalid inputs" do
      assert Parser.valid?("") == false
      assert Parser.valid?("KK") == false
      assert Parser.valid?("invalid") == false
      assert Parser.valid?(nil) == false
    end
  end

  # ===========================================================================
  # Error Cases - Empty Input
  # ===========================================================================

  describe "parse/1 with empty input" do
    test "returns error for empty string" do
      assert {:error, :empty_input} = Parser.parse("")
    end
  end

  # ===========================================================================
  # Error Cases - Input Too Long
  # ===========================================================================

  describe "parse/1 with input too long" do
    test "returns error for 4 characters" do
      assert {:error, :input_too_long} = Parser.parse("+K^X")
    end

    test "returns error for many characters" do
      assert {:error, :input_too_long} = Parser.parse("invalid")
    end
  end

  # ===========================================================================
  # Error Cases - Must Contain One Letter
  # ===========================================================================

  describe "parse/1 with missing letter" do
    test "returns error for modifier only" do
      assert {:error, :must_contain_one_letter} = Parser.parse("+")
    end

    test "returns error for digit only" do
      assert {:error, :must_contain_one_letter} = Parser.parse("1")
    end

    test "returns error for terminal marker only" do
      assert {:error, :must_contain_one_letter} = Parser.parse("^")
    end

    test "returns error for modifier followed by non-letter" do
      assert {:error, :must_contain_one_letter} = Parser.parse("+1")
      assert {:error, :must_contain_one_letter} = Parser.parse("-^")
    end
  end

  # ===========================================================================
  # Error Cases - Invalid State Modifier
  # ===========================================================================

  describe "parse/1 with invalid state modifier" do
    test "returns error for invalid character followed by letter" do
      assert {:error, :invalid_state_modifier} = Parser.parse("*K")
      assert {:error, :invalid_state_modifier} = Parser.parse("!R")
      assert {:error, :invalid_state_modifier} = Parser.parse("1K")
    end

    test "returns error for terminal marker at start" do
      assert {:error, :invalid_state_modifier} = Parser.parse("^K")
      assert {:error, :invalid_state_modifier} = Parser.parse("^K^")
    end

    test "returns error for invalid character in 3-char input" do
      assert {:error, :invalid_state_modifier} = Parser.parse("*K^")
      assert {:error, :invalid_state_modifier} = Parser.parse("1K^")
    end
  end

  # ===========================================================================
  # Error Cases - Invalid Terminal Marker
  # ===========================================================================

  describe "parse/1 with invalid terminal marker" do
    test "returns error for two letters" do
      assert {:error, :invalid_terminal_marker} = Parser.parse("KQ")
    end

    test "returns error for letter followed by invalid character" do
      assert {:error, :invalid_terminal_marker} = Parser.parse("K!")
    end

    test "returns error for letter followed by digit" do
      assert {:error, :invalid_terminal_marker} = Parser.parse("K1")
    end

    test "returns error for letter followed by two chars" do
      assert {:error, :invalid_terminal_marker} = Parser.parse("K1^")
      assert {:error, :invalid_terminal_marker} = Parser.parse("KQR")
    end

    test "returns error for modifier + letter + invalid" do
      assert {:error, :invalid_terminal_marker} = Parser.parse("+K!")
      assert {:error, :invalid_terminal_marker} = Parser.parse("-R1")
    end
  end

  # ===========================================================================
  # Error Cases - Must Contain One Letter (3-char inputs)
  # ===========================================================================

  describe "parse/1 with missing letter in 3-char input" do
    test "returns error for modifier + non-letter + terminal" do
      assert {:error, :must_contain_one_letter} = Parser.parse("+1^")
      assert {:error, :must_contain_one_letter} = Parser.parse("-!^")
    end
  end

  # ===========================================================================
  # Security - Null Byte Injection
  # ===========================================================================

  describe "security: null byte injection" do
    test "rejects null byte at end" do
      assert Parser.valid?("K\x00") == false
    end

    test "rejects null byte at start" do
      assert Parser.valid?("\x00K") == false
    end

    test "rejects null byte in middle" do
      assert Parser.valid?("+\x00K") == false
    end
  end

  # ===========================================================================
  # Security - Control Characters
  # ===========================================================================

  describe "security: control characters" do
    test "rejects newline" do
      assert Parser.valid?("K\n") == false
      assert Parser.valid?("\nK") == false
    end

    test "rejects carriage return" do
      assert Parser.valid?("K\r") == false
      assert Parser.valid?("\r\nK") == false
    end

    test "rejects tab" do
      assert Parser.valid?("K\t") == false
      assert Parser.valid?("\tK") == false
    end

    test "rejects other control characters" do
      # SOH
      assert Parser.valid?("K\x01") == false
      # ESC
      assert Parser.valid?("K\x1b") == false
      # DEL
      assert Parser.valid?("K\x7f") == false
    end
  end

  # ===========================================================================
  # Security - Unicode Lookalikes
  # ===========================================================================

  describe "security: unicode lookalikes" do
    test "rejects Cyrillic lookalikes" do
      # Cyrillic 'К' (U+041A) looks like Latin 'K'
      assert Parser.valid?(<<0xD0, 0x9A>>) == false
      # Cyrillic 'а' (U+0430) looks like Latin 'a'
      assert Parser.valid?(<<0xD0, 0xB0>>) == false
    end

    test "rejects Greek lookalikes" do
      # Greek 'Α' (U+0391) looks like Latin 'A'
      assert Parser.valid?(<<0xCE, 0x91>>) == false
    end

    test "rejects full-width characters" do
      # Full-width 'K' (U+FF2B)
      assert Parser.valid?(<<0xEF, 0xBC, 0xAB>>) == false
      # Full-width 'k' (U+FF4B)
      assert Parser.valid?(<<0xEF, 0xBD, 0x8B>>) == false
    end
  end

  # ===========================================================================
  # Security - Combining Characters
  # ===========================================================================

  describe "security: combining characters" do
    test "rejects combining acute accent" do
      # 'K' + combining acute accent (U+0301)
      assert Parser.valid?("K" <> <<0xCC, 0x81>>) == false
    end

    test "rejects combining diaeresis" do
      # 'K' + combining diaeresis (U+0308)
      assert Parser.valid?("K" <> <<0xCC, 0x88>>) == false
    end
  end

  # ===========================================================================
  # Security - Zero-Width Characters
  # ===========================================================================

  describe "security: zero-width characters" do
    test "rejects zero-width space" do
      # Zero-width space (U+200B)
      assert Parser.valid?("K" <> <<0xE2, 0x80, 0x8B>>) == false
    end

    test "rejects zero-width non-joiner" do
      # Zero-width non-joiner (U+200C)
      assert Parser.valid?("K" <> <<0xE2, 0x80, 0x8C>>) == false
    end

    test "rejects BOM" do
      # Byte order mark (U+FEFF)
      assert Parser.valid?(<<0xEF, 0xBB, 0xBF>> <> "K") == false
    end
  end

  # ===========================================================================
  # Security - Non-String Input
  # ===========================================================================

  describe "security: non-string input" do
    test "rejects nil" do
      assert Parser.valid?(nil) == false
    end

    test "rejects integer" do
      assert Parser.valid?(123) == false
    end

    test "rejects list" do
      assert Parser.valid?([:K]) == false
    end

    test "rejects map" do
      assert Parser.valid?(%{abbr: :K}) == false
    end

    test "rejects atom" do
      assert Parser.valid?(:K) == false
    end
  end

  # ===========================================================================
  # Round-Trip Tests
  # ===========================================================================

  describe "round-trip" do
    alias Sashite.Pin.Identifier

    test "round-trip simple letters" do
      for pin_string <- ~w(K k Q q R r) do
        {:ok, components} = Parser.parse(pin_string)

        identifier =
          Identifier.new(
            components.abbr,
            components.side,
            components.state,
            terminal: components.terminal
          )

        assert Identifier.to_string(identifier) == pin_string
      end
    end

    test "round-trip with state modifiers" do
      for pin_string <- ~w(+K +k -P -p +R -r) do
        {:ok, components} = Parser.parse(pin_string)

        identifier =
          Identifier.new(
            components.abbr,
            components.side,
            components.state,
            terminal: components.terminal
          )

        assert Identifier.to_string(identifier) == pin_string
      end
    end

    test "round-trip with terminal marker" do
      for pin_string <- ~w(K^ k^ Q^ q^) do
        {:ok, components} = Parser.parse(pin_string)

        identifier =
          Identifier.new(
            components.abbr,
            components.side,
            components.state,
            terminal: components.terminal
          )

        assert Identifier.to_string(identifier) == pin_string
      end
    end

    test "round-trip combined" do
      for pin_string <- ~w(+K^ -k^ +Q^ -q^) do
        {:ok, components} = Parser.parse(pin_string)

        identifier =
          Identifier.new(
            components.abbr,
            components.side,
            components.state,
            terminal: components.terminal
          )

        assert Identifier.to_string(identifier) == pin_string
      end
    end
  end
end
