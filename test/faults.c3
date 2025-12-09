module regex::faults;
import regex::test_common;
import regex;

fn void invalid_escape_sequence() @test
{
    test_common::regex_expect_fault(`\`, Options.ASCII_ONLY, regex::INVALID_ESCAPE_SEQUENCE);
    test_common::regex_expect_fault(`\x.`, Options.ASCII_ONLY, regex::INVALID_ESCAPE_SEQUENCE);
    test_common::regex_expect_fault(`\c`, Options.ASCII_ONLY, regex::INVALID_ESCAPE_SEQUENCE);
    test_common::regex_expect_fault(`\u`, Options.ASCII_ONLY, regex::INVALID_ESCAPE_SEQUENCE);
    test_common::regex_expect_fault(`\u110000`, Options.ASCII_ONLY, regex::INVALID_ESCAPE_SEQUENCE);
}

fn void unterminated_character_group() @test
{
    test_common::regex_expect_fault(`[abc`, Options.ASCII_ONLY, regex::UNTERMINATED_CHARACTER_GROUP);
}

fn void unterminated_range_quantifier() @test
{
    test_common::regex_expect_fault(`e{`, Options.ASCII_ONLY, regex::UNTERMINATED_RANGE_QUANTIFIER);
}

fn void unexpected_character() @test
{
    test_common::regex_expect_fault(`e{e`, Options.ASCII_ONLY, regex::UNEXPECTED_CHARACTER);
}

fn void unfilled_range_quantifier() @test
{
    test_common::regex_expect_fault(`e{}`, Options.ASCII_ONLY, regex::UNFILLED_RANGE_QUANTIFIER);
}

fn void unexpected_end_of_input() @test
{
    test_common::regex_expect_fault(``, Options.ASCII_ONLY, regex::UNEXPECTED_END_OF_INPUT);
}

fn void invalid_range_quantifier() @test
{
    test_common::regex_expect_fault(`y{,}`, Options.ASCII_ONLY, regex::INVALID_RANGE_QUANTIFIER);
    test_common::regex_expect_fault(`y{1,2,}`, Options.ASCII_ONLY, regex::INVALID_RANGE_QUANTIFIER);
}

fn void unexpected_token() @test
{
    test_common::regex_expect_fault(`?`, Options.ASCII_ONLY, regex::UNEXPECTED_TOKEN);
    test_common::regex_expect_fault(`*`, Options.ASCII_ONLY, regex::UNEXPECTED_TOKEN);
    test_common::regex_expect_fault(`+`, Options.ASCII_ONLY, regex::UNEXPECTED_TOKEN);
}

fn void unterminated_subexpression() @test
{
    test_common::regex_expect_fault(`(x`, Options.ASCII_ONLY, regex::UNTERMINATED_SUBEXPRESSION);
    test_common::regex_expect_fault(`(?:x`, Options.ASCII_ONLY, regex::UNTERMINATED_SUBEXPRESSION);
    test_common::regex_expect_fault(`(?=x`, Options.ASCII_ONLY, regex::UNTERMINATED_SUBEXPRESSION);
    test_common::regex_expect_fault(`(?!x`, Options.ASCII_ONLY, regex::UNTERMINATED_SUBEXPRESSION);
}

fn void invalid_capture_group_id() @test
{
    test_common::regex_expect_fault(`\1`, Options.ASCII_ONLY, regex::INVALID_CAPTURE_GROUP_ID);
}

fn void extraneous_parentheses() @test
{
    test_common::regex_expect_fault(`x)`, Options.ASCII_ONLY, regex::EXTRANEOUS_PARENTHESES);
}

<*
    This one is going to be a slow one to test as this is a last ditch effort
*>
fn void regex_too_complex() @test
{
    test_common::regex_expect_fault(`.{0,17000000}`, Options.ASCII_ONLY, regex::REGEX_TOO_COMPLEX);
}

