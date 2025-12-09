module regex::ascii::units;
import regex::test_common;
import regex;


fn void wildcard() @test
{
    test_common::regex_expect_match_full(`...`,Options.ASCII_ONLY, "123","456","789");
    test_common::regex_expectnt_match_full(`...`, Options.ASCII_ONLY, "12");
    test_common::regex_expectnt_match_full(`...`, Options.ASCII_ONLY, "\n\n\n");
    test_common::regex_expect(`.`, Options.ASCII_ONLY, "12345678910", "1", "2", "3", "4", "5", "6", "7", "8", "9", "1", "0");
}

fn void characters() @test
{
    test_common::regex_expect_match_full(`abc`,Options.ASCII_ONLY, "abc");
    test_common::regex_expectnt_match_full(`abc`, Options.ASCII_ONLY, "xyz");
    test_common::regex_expect(`a`, Options.ASCII_ONLY, "a | b | a", "a", "a");
}

fn void digits() @test
{
    test_common::regex_expect_match_full(`\d\d\d`, Options.ASCII_ONLY, "123", "456", "789");
    test_common::regex_expectnt_match_full(`\d\d\d`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`\d`, Options.ASCII_ONLY, "1a2b3c4d5e6f7g8h9i10j", "1", "2", "3", "4", "5", "6", "7", "8", "9", "1", "0");
}

fn void not_digits() @test
{
    test_common::regex_expect_match_full(`\D\D\D`, Options.ASCII_ONLY, "abc", "def", "hij");
    test_common::regex_expectnt_match_full(`\D\D\D`, Options.ASCII_ONLY, "123");
    test_common::regex_expect(`\D`, Options.ASCII_ONLY, "1a2b3c4d5e6f7g8h9i10j", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j");
}

fn void whitespace() @test
{
    test_common::regex_expect_match_full(`\s\s\s`, Options.ASCII_ONLY, " \n\t", "\v \n", "\r\n\r");
    test_common::regex_expectnt_match_full(`\s\s\s`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`\s`, Options.ASCII_ONLY,"\tSome words\n\v\r", "\t", " ", "\n", "\v", "\r");
}

fn void not_whitespace() @test
{
    test_common::regex_expect_match_full(`\S\S\S`, Options.ASCII_ONLY, "ABC", "123", "...");
    test_common::regex_expectnt_match_full(`\S\S\S`, Options.ASCII_ONLY, "   ");
    test_common::regex_expect(`\S`, Options.ASCII_ONLY,"\tSome words\n\v\r", "S", "o", "m", "e", "w", "o", "r", "d", "s");
}

fn void word() @test
{
    test_common::regex_expect_match_full(`\w\w\w`, Options.ASCII_ONLY, "123", "abc", "A_b");
    test_common::regex_expectnt_match_full(`\w\w\w`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`\w`, Options.ASCII_ONLY, ".abc _123", "a", "b", "c", "_", "1", "2", "3");
}

fn void not_word() @test
{
    test_common::regex_expect_match_full(`\W\W\W`, Options.ASCII_ONLY, " .?", "\t\t\t", ".!.");
    test_common::regex_expectnt_match_full(`\W\W\W`, Options.ASCII_ONLY, "abc");
    test_common::regex_expect(`\W`, Options.ASCII_ONLY, ".abc _123", ".", " ");
}

fn void character_class() @test
{
    test_common::regex_expect_match_full(`[+-][+-][+-]`, Options.ASCII_ONLY, "+-+", "-+-");
    test_common::regex_expectnt_match_full(`[+-][+-][+-]`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`[+-]`, Options.ASCII_ONLY, "+5, -32", "+", "-");
}

fn void not_character_class() @test
{
    test_common::regex_expect_match_full(`[^+-][^+-][^+-]`, Options.ASCII_ONLY, "abc", "def");
    test_common::regex_expectnt_match_full(`[^+-][^+-][^+-]`, Options.ASCII_ONLY, "+++");
    test_common::regex_expect(`[^+-]`, Options.ASCII_ONLY, "+5, -32", "5", ",", " ", "3", "2");
}

fn void character_range() @test
{
    test_common::regex_expect_match_full(`[1-3][1-3][1-3]`, Options.ASCII_ONLY, "123", "321");
    test_common::regex_expectnt_match_full(`[1-3][1-3][1-3]`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`[1-3]`, Options.ASCII_ONLY, "0123456789", "1", "2", "3");
}

fn void character_class_w() @test
{
    test_common::regex_expect_match_full(`[:w:][:w:][:w:]`, Options.ASCII_ONLY, "123", "abc", "Aeb");
    test_common::regex_expectnt_match_full(`[:w:][:w:][:w:]`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`[:w:]`, Options.ASCII_ONLY, ".abc _123", "a", "b", "c", "1", "2", "3");
}

fn void character_class_a() @test
{
    test_common::regex_expect_match_full(`[:a:][:a:][:a:]`, Options.ASCII_ONLY, "abc", "Aeb");
    test_common::regex_expectnt_match_full(`[:a:][:a:][:a:]`, Options.ASCII_ONLY, "...");
    test_common::regex_expect(`[:a:]`, Options.ASCII_ONLY, ".abc _123", "a", "b", "c");
}

fn void character_class_b() @test
{
    test_common::regex_expect_match_full(`[:b:][:b:][:b:]`, Options.ASCII_ONLY, "\t  ");
    test_common::regex_expectnt_match_full(`[:b:][:b:][:b:]`, Options.ASCII_ONLY, "abc");
    test_common::regex_expect(`[:b:]`, Options.ASCII_ONLY, ".abc _123", " ");
}

fn void character_class_c() @test
{
    test_common::regex_expect_match_full(`[:c:][:c:][:c:]`, Options.ASCII_ONLY, "\e\e\e");
    test_common::regex_expectnt_match_full(`[:c:][:c:][:c:]`, Options.ASCII_ONLY, "abc");
    test_common::regex_expect(`[:c:]`, Options.ASCII_ONLY, ".abc\n_123", "\n");
}

fn void character_class_d() @test
{
    test_common::regex_expect_match_full(`[:d:][:d:][:d:]`, Options.ASCII_ONLY, "123", "456", "789");
    test_common::regex_expectnt_match_full(`[:d:][:d:][:d:]`, Options.ASCII_ONLY, "abc");
    test_common::regex_expect(`[:d:]`, Options.ASCII_ONLY, "1a2b3c4d5e6f7g8h9i10j", "1", "2", "3", "4", "5", "6", "7", "8", "9", "1", "0");
}

fn void character_class_g() @test
{
    test_common::regex_expect_match_full(`[:g:][:g:][:g:]`, Options.ASCII_ONLY, "123", "abc", ".?5");
    test_common::regex_expectnt_match_full(`[:g:][:g:][:g:]`, Options.ASCII_ONLY, "\0\0\0");
    test_common::regex_expect(`[:g:]`, Options.ASCII_ONLY, ".abc\n_123", ".", "a", "b", "c", "_", "1", "2", "3");
}

fn void character_class_l() @test
{
    test_common::regex_expect_match_full(`[:l:][:l:][:l:]`, Options.ASCII_ONLY, "dog", "cat");
    test_common::regex_expectnt_match_full(`[:l:][:l:][:l:]`, Options.ASCII_ONLY, "HIJ", "ABC");
    test_common::regex_expect(`[:l:]`, Options.ASCII_ONLY, "AaBbCc", "a", "b", "c");
}

fn void character_class_p() @test
{

    test_common::regex_expect_match_full(`[:p:][:p:][:p:]`, Options.ASCII_ONLY, "123", "abc", ".?5");
    test_common::regex_expectnt_match_full(`[:p:][:p:][:p:]`, Options.ASCII_ONLY, "\0\0\0");
    test_common::regex_expect(`[:p:]`, Options.ASCII_ONLY, ".abc\n_123", ".", "a", "b", "c", "_", "1", "2", "3");
}

fn void character_class_punct() @test
{
    test_common::regex_expect_match_full(`[:.:][:.:][:.:]`, Options.ASCII_ONLY, ".?!", ",,,");
    test_common::regex_expectnt_match_full(`[:.:][:.:][:.:]`, Options.ASCII_ONLY, "hij", "abc");
    test_common::regex_expect(`[:.:]`, Options.ASCII_ONLY, "Hello! My name is Lexi. May I ask, how is this day treating you?","!",".",",","?");
}

fn void character_class_u() @test
{
    test_common::regex_expect_match_full(`[:u:][:u:][:u:]`, Options.ASCII_ONLY, "DOG", "CAT");
    test_common::regex_expectnt_match_full(`[:u:][:u:][:u:]`, Options.ASCII_ONLY, "hij", "...");
    test_common::regex_expect(`[:u:]`, Options.ASCII_ONLY, "AaBbCc", "A", "B", "C");
}

fn void character_class_x() @test
{
    test_common::regex_expect_match_full(`[:x:][:x:][:x:]`, Options.ASCII_ONLY, "A3f", "FEE");
    test_common::regex_expectnt_match_full(`[:x:][:x:][:x:]`, Options.ASCII_ONLY, "hij", "...");
    test_common::regex_expect(`[:x:]`, Options.ASCII_ONLY, "xCAFE134", "C", "A", "F", "E", "1", "3", "4");
}

fn void quantifier_star() @test
{
    test_common::regex_expect_match_full(`\d*`, Options.ASCII_ONLY, "", "1", "123");
    test_common::regex_expectnt_match_full(`\d*`, Options.ASCII_ONLY, "abc");
    test_common::regex_expect(`\d*`, Options.ASCII_ONLY, "1234", "1234");
}

fn void quantifier_plus() @test
{
    test_common::regex_expect_match_full(`\d+`, Options.ASCII_ONLY, "1", "12", "123");
    test_common::regex_expectnt_match_full(`d+`, Options.ASCII_ONLY, "", "abc");
    test_common::regex_expect(`\d+`, Options.ASCII_ONLY, "1234 5678", "1234", "5678");
}

fn void quantifier_question() @test
{
    test_common::regex_expect_match_full(`\d?`, Options.ASCII_ONLY, "1", "", "5");
    test_common::regex_expectnt_match_full(`\d?`, Options.ASCII_ONLY, "12", "a");
}

fn void quantifier_exact() @test
{
    test_common::regex_expect_match_full(`\d{5}`, Options.ASCII_ONLY, "12345", "67890");
    test_common::regex_expectnt_match_full(`\d{5}`, Options.ASCII_ONLY, "abcdef", "1234", "123456");
    test_common::regex_expect(`\d{5}`, Options.ASCII_ONLY, "1234567890", "12345", "67890");
}

fn void quantifier_least() @test
{
    test_common::regex_expect_match_full(`\d{3,}`, Options.ASCII_ONLY, "123", "12345", "1234567890");
    test_common::regex_expectnt_match_full(`\d{3,}`, Options.ASCII_ONLY, "abc", "1", "12");
    test_common::regex_expect(`\d{3,}`, Options.ASCII_ONLY, "1 12 123 1234 12345 123456 1234567", "123", "1234", "12345", "123456", "1234567");
}

fn void quantifier_between() @test
{
    test_common::regex_expect_match_full(`\d{3,5}`, Options.ASCII_ONLY, "123", "12345");
    test_common::regex_expectnt_match_full(`\d{3,5}`, Options.ASCII_ONLY, "12", "123456");
    test_common::regex_expect(`\d{3,5}`, Options.ASCII_ONLY, "1 12 123 1234 12345 123456 1234567", "123", "1234", "12345", "12345", "12345");
}

fn void group() @test
{
    test_common::regex_expect_match_full(`(\d{3})+`, Options.ASCII_ONLY, "123", "123456");
    test_common::regex_expectnt_match_full(`(\d{3})+`, Options.ASCII_ONLY, "12", "1234", "1234567");
    test_common::regex_expect(`(\d{3})+`, Options.ASCII_ONLY, "1 12 123 1234 12345 123456 1234567", "123", "123", "123", "123456", "123456");
}

fn void group_captures() @test
{
    // Test multiple capture groups
    test_common::regex_expect_capture_groups(`(\d{3})-(\d{3})-(\d{4})`, Options.ASCII_ONLY, "888-867-5309", "888", "867", "5309");
    // Test behaviour that it is the first group matched
    test_common::regex_expect_capture_groups(`(\d{3})+`, Options.ASCII_ONLY, "111222333444555666", "111");
}

fn void non_capturing_group() @test
{
    test_common::regex_expect_match_full(`(?:\d{3})+`, Options.ASCII_ONLY, "123", "123456");
    test_common::regex_expectnt_match_full(`(?:\d{3})+`, Options.ASCII_ONLY, "12", "1234", "1234567");
    test_common::regex_expect(`(?:\d{3})+`, Options.ASCII_ONLY, "1 12 123 1234 12345 123456 1234567", "123", "123", "123", "123456", "123456");
}

fn void backreferences() @test
{
    test_common::regex_expect_match_full(`(\d+)\.\1`, Options.ASCII_ONLY, "123.123", "456.456", "3660.3660");
    test_common::regex_expectnt_match_full(`(\d+)\.\1`, Options.ASCII_ONLY, "123.456", "456.789");
    test_common::regex_expect(`(\d+)\.\1`, Options.ASCII_ONLY, "123.123 123.456 456.456 456.789 3660.3660", "123.123", "456.456", "3660.3660");
}

fn void assert_beginning() @test
{
    test_common::regex_expect(`^\d+`,  Options.ASCII_ONLY, "123 456 789 321", "123");
}

fn void assert_end() @test
{
    test_common::regex_expect(`\d+$`,  Options.ASCII_ONLY, "123 456 789 321", "321");
}

fn void assert_word_boundary() @test
{
    test_common::regex_expect(`\b\d{3}\b`, Options.ASCII_ONLY, "1 12 123 1234 12345 567", "123", "567");
}

fn void assert_not_word_boundary() @test
{
    test_common::regex_expect(`\B\d{3}\B`, Options.ASCII_ONLY, "1 12 123 1234 12345 567", "234");
}

fn void positive_lookahead() @test
{
    test_common::regex_expect(`123(?=456).`, Options.ASCII_ONLY, "123567 123456", "1234");
}

fn void negative_lookahead() @test
{
    test_common::regex_expect(`123(?!456).`, Options.ASCII_ONLY, "123567 123456", "1235");
}

fn void alternatives() @test
{
    test_common::regex_expect(`123|456`, Options.ASCII_ONLY, "123 456 789", "123", "456");
}