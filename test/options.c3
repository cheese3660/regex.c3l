<*
    This module contains tests that hit the options of the regex engine
*>
module regex::options;

import regex::test_common;
import regex;

fn void multiline() @test
{
    test_common::regex_expect(`^\d{3}$`, Options.MULTILINE, "123\n456\n789", "123", "456", "789");
}

fn void single_line() @test
{
    test_common::regex_expect_match_full(`...`, Options.SINGLE_LINE, "1\n3");
}


fn void ignore_case() @test
{
    test_common::regex_expect_match_full(`alphA`, Options.IGNORE_CASE, "aLpHa", "alpha", "AlpHa", "ALPHA");
    test_common::regex_expect_match_full(`(.)\1`, Options.IGNORE_CASE, "aa", "aA", "Aa", "AA");
    test_common::regex_expect_match_full(`[a]`, Options.IGNORE_CASE, "a", "A");
    test_common::regex_expect_match_full(`[a-z]`, Options.IGNORE_CASE, "A", "a", "f", "F", "z", "Z");
}