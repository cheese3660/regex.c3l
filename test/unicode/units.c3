<*
    This contains utf8 specific regex tests

    That specifically hit the utf8 specific logic
*>
module regex::utf8::units;

import regex::test_common;
import regex;


fn void single_character() @test
{
    test_common::regex_expect_match_full(`.`, Options.NONE, "a" /* 1 byte */, "γ" /* 2 bytes */, "ꬰ" /* 3 bytes */, "𐀀" /* 4 bytes */);
}

fn void string() @test
{
    test_common::regex_expect(`γꬰ5`, Options.NONE, "γꬰ5 γꬰ6", "γꬰ5");
}

fn void backref() @test
{
    test_common::regex_expect(`(γ+)\1`, Options.NONE, "γγγγ γγ","γγγγ", "γγ");
}

fn void character_class() @test
{
    test_common::regex_expect(`[ΑΩ]`, Options.NONE, "ΑγΩ", "Α", "Ω");
}

fn void character_range() @test
{
    test_common::regex_expect(`[Α-Ω]`, Options.NONE, "ΑΦΩ", "Α", "Φ", "Ω");
}