module regex::basic_concepts;
import regex::test_common;
import regex;


fn void test_wildcard() @test
{
    test_common::regex_expect_match_full("...",Options.ASCII_ONLY, "123","456","789");
    test_common::regex_expect(".", Options.ASCII_ONLY, "12345678910", "1", "2", "3", "4", "5", "6", "7", "8", "9", "1", "0");
}

fn void characters() @test
{
    test_common::regex_expect_match_full("abc",Options.ASCII_ONLY, "abc");
    test_common::regex_expect("a", Options.ASCII_ONLY, "a | b | a", "a", "a");
}