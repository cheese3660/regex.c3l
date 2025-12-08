<*
    This module lexes a regex
*>
module regex::runtime::lexing;

import std::collections::list;
import regex;


enum RegexTokenType : char (TokenizerMode next_state_regular, TokenizerMode next_state_cg, TokenizerMode next_state_rq) 
{
    CHARACTER = {DEFLT,IN_CG,IN_RQ},           // Any sequence of characters
    POS_CG_BEGIN = {IN_CG,IN_CG,IN_RQ},       // [
    NEG_CG_BEGIN = {IN_CG,IN_CG,IN_RQ},       // [^
    CG_END = {DEFLT,DEFLT,DEFLT},             // ]
    WILDCARD = {DEFLT,IN_CG,IN_RQ},           // .
    DASH = {DEFLT,IN_CG,IN_RQ},               // - in character group
    WORD = {DEFLT,IN_CG,IN_RQ},               // \w
    NON_WORD = {DEFLT,IN_CG,IN_RQ},           // \W
    WHITESPACE = {DEFLT,IN_CG,IN_RQ},         // \s
    NON_WHITESPACE = {DEFLT,IN_CG,IN_RQ},     // \S
    DIGIT = {DEFLT,IN_CG,IN_RQ},              // \d
    NON_DIGIT = {DEFLT,IN_CG,IN_RQ},          // \D
    BACKREFERENCE = {DEFLT,IN_CG,IN_RQ},      // \int where n > 0
    GROUP_OPEN = {DEFLT,IN_CG,IN_RQ},         // (
    NO_BR_GROUP_OPEN = {DEFLT,IN_CG,IN_RQ},   // (?:
    GROUP_END = {DEFLT,IN_CG,IN_RQ},          // )
    ZERO_OR_MORE = {DEFLT,IN_CG,IN_RQ},       // *
    ONE_OR_MORE = {DEFLT,IN_CG,IN_RQ},        // +
    ZERO_OR_ONE = {DEFLT,IN_CG,IN_RQ},        // ?
    RQ_BEGIN = {IN_RQ,IN_CG,IN_RQ},           // {
    RQ_END = {DEFLT,IN_CG,DEFLT},             // }
    RQ_NUMBER = {DEFLT,IN_CG,IN_RQ},          // int
    RQ_SEPARATOR = {DEFLT,IN_CG,IN_RQ},       // ,
    BEGINNING = {DEFLT,IN_CG,IN_RQ},          // ^
    END = {DEFLT,IN_CG,IN_RQ},                // $
    WORD_BOUNDARY = {DEFLT,IN_CG,IN_RQ},      // \b
    NOT_WORD_BOUNDARY = {DEFLT,IN_CG,IN_RQ},  // \B
    POS_LOOK = {DEFLT,IN_CG,IN_RQ},           // (?=
    NEG_LOOK = {DEFLT,IN_CG,IN_RQ},           // (?!
    SEPARATOR = {DEFLT,IN_CG,IN_RQ},          // |
    ALNUM_CLASS = {DEFLT,IN_CG,IN_RQ},        // :alnum:,   :w:
    ALPHA_CLASS = {DEFLT,IN_CG,IN_RQ},        // :alpha:,   :a:
    BLANK_CLASS = {DEFLT,IN_CG,IN_RQ},        // :blank:,   :b:
    CNTRL_CLASS = {DEFLT,IN_CG,IN_RQ},        // :cntrl:,   :c:
    DIGIT_CLASS = {DEFLT,IN_CG,IN_RQ},        // :digit:,   :d:
    GRAPH_CLASS = {DEFLT,IN_CG,IN_RQ},        // :graph:,   :g:
    LOWER_CLASS = {DEFLT,IN_CG,IN_RQ},        // :lower:,   :l:
    PRINT_CLASS = {DEFLT,IN_CG,IN_RQ},        // :print:, :p:
    SPACE_CLASS = {DEFLT,IN_CG,IN_RQ},        // :space:,   :s:
    UPPER_CLASS = {DEFLT,IN_CG,IN_RQ},        // :upper:,   :u:
    XDIGT_CLASS = {DEFLT,IN_CG,IN_RQ},        // :xdigit:,  :x:
}

struct RegexToken 
{
    RegexTokenType type;
    union context 
    {
        uint num;
        char ch;
    }
}

enum TokenizerMode @private 
{
    DEFLT,
    IN_CG,
    IN_RQ
}

struct TokenMapEntry @private
{
    String prefix;
    RegexTokenType type;
}

const TokenMapEntry[*] TOP_LEVEL_TOKEN_MAP @private = {
    {"[^", NEG_CG_BEGIN},
    {"[", POS_CG_BEGIN},
    {"]", CG_END},
    {".", WILDCARD},
    {"\\w", WORD},
    {"\\W", NON_WORD},
    {"\\s", WHITESPACE},
    {"\\S", NON_WHITESPACE},
    {"\\d", DIGIT},
    {"\\D", NON_DIGIT},
    {"(?:", NO_BR_GROUP_OPEN},
    {"(?=", POS_LOOK},
    {"(?!", NEG_LOOK},
    {"(", GROUP_OPEN},
    {")", GROUP_END},
    {"*", ZERO_OR_MORE},
    {"+", ONE_OR_MORE},
    {"?", ZERO_OR_ONE},
    {"{", RQ_BEGIN},
    {"}", RQ_END},
    {"^", BEGINNING},
    {"$", END},
    {"\\b", WORD_BOUNDARY},
    {"\\B", NOT_WORD_BOUNDARY},
    {"|", SEPARATOR}
};

const TokenMapEntry[*] CG_TOKEN_MAP @private = {
    {"[", POS_CG_BEGIN},
    {"]", CG_END},
    {"-", DASH},
    {":alnum:", ALNUM_CLASS}, {":w:", ALNUM_CLASS},
    {":alpha:", ALPHA_CLASS}, {":a:", ALPHA_CLASS},
    {":blank:", BLANK_CLASS}, {":b:", BLANK_CLASS},
    {":cntrl:", CNTRL_CLASS}, {":c:", CNTRL_CLASS},
    {":digit:", DIGIT_CLASS}, {":d:", DIGIT_CLASS},
    {":graph:", GRAPH_CLASS}, {":g:", GRAPH_CLASS},
    {":lower:", LOWER_CLASS}, {":l:", LOWER_CLASS},
    {":print:", PRINT_CLASS}, {":p:", PRINT_CLASS},
    {":space:", SPACE_CLASS}, {":s:", SPACE_CLASS},
    {":upper:", UPPER_CLASS}, {":u:", UPPER_CLASS},
    {":xdigit:",XDIGT_CLASS}, {":x:", XDIGT_CLASS},
};


// <*
//     Tokenize a regex into a list using the defa
// *>
// fn TokenList? tokenize_regex(String regex, Options options) {
//     TokenList result;
//     result.tinit(regex.len >> 1);
// }

struct TokenizerContext 
{
    String tokenizing;
    TokenizerMode mode;

    bool has_stored_backtrack;
    RegexToken stored_back_track;
}

fn TokenizerContext on(String regex) 
{
    return {
        regex,
        DEFLT,
        false,
        {},
    };
}

macro char from_hex(char hi, char low) @private {
    return (ascii::HEX_VALUE[hi] << 4) | ascii::HEX_VALUE[low];
}

<*
    @param after_slash       : "The part after the slash of the escape sequence being handled"
    @param [&out] consumed   : "How much of the string after the slash is consumed"

    @return? regex::INVALID_ESCAPE_SEQUENCE : "If the escape sequence is invalid"
*>
fn char? handle_escape_character(String after_slash, usz* consumed) @private
{
    if (after_slash.len == 0) return regex::INVALID_ESCAPE_SEQUENCE?;

    *consumed = 1;
    
    switch (after_slash[0])
    {
        case 't':
            return '\t';
        case 'n':
            return '\n';
        case 'v':
            return '\v';
        case 'f':
            return '\f';
        case 'r':
            return '\r';
        case 'c':
            if (after_slash.len == 1) return regex::INVALID_ESCAPE_SEQUENCE?;
            *consumed = 2;
            return after_slash[1] & 31;
        case 'x':
            *consumed = 3;
            if (after_slash.len < 3) return regex::INVALID_ESCAPE_SEQUENCE?;
            if (!after_slash[1].is_xdigit() || !after_slash[2].is_xdigit()) return regex::INVALID_ESCAPE_SEQUENCE?;
            return from_hex(after_slash[1], after_slash[2]);
        case '0':
            return 0;
        default:
            return after_slash[0];
    }
}


<*
    @return "Is the tokenizer done tokenizing"
    @pure
*>
fn bool TokenizerContext.done(&self) @inline => !self.has_stored_backtrack && self.mode == DEFLT && self.tokenizing.len == 0;

<*
    @return? regex::UNTERMINATED_CHARACTER_GROUP : "[ was not matched with ]"
    @return? regex::UNTERMINATED_RANGE_QUANTIFIER : "{ was not matched with }"
    @return? regex::UNEXPECTED_CHARACTER : "There was an unexpected character in the sequence"
    @return? regex::INVALID_ESCAPE_SEQUENCE : "The regex had an invalid escape sequence"
    @return? regex::UNEXPECTED_END_OF_INPUT : "The tokenizer is being requested to get more tokens than are in the input"
    @return? regex::INVALID_CAPTURE_GROUP_ID : "If the regex has a back reference to a capture group of index 65536 or greater"
*>
fn RegexToken? TokenizerContext.get_next_token(&self) 
{
    if (self.has_stored_backtrack)
    {
        self.has_stored_backtrack = false;
        return self.stored_back_track;
    }

    if (self.tokenizing.len == 0)
    {
        switch (self.mode) 
        {
            case IN_CG:
                self.mode = DEFLT;
                return regex::UNTERMINATED_CHARACTER_GROUP?;
            case IN_RQ:
                self.mode = DEFLT;
                return regex::UNTERMINATED_RANGE_QUANTIFIER?;
            default:
                return regex::UNEXPECTED_END_OF_INPUT?;
        }
    }
    usz consumed = 0;
    RegexToken result;
    switch (self.mode) 
    {
        case DEFLT:
            result = self.deflt(&consumed)!;
            self.mode = result.type.next_state_regular;
        case IN_RQ:
            result = self.rq(&consumed)!;
            self.mode = result.type.next_state_rq;
        case IN_CG:
            result = self.cg(&consumed)!;
            self.mode = result.type.next_state_cg;
    }
    self.tokenizing = self.tokenizing[consumed..];
    return result;
}

<*
    @param [&inout] consumed : "How much data was consumed"

    @return "The next regex token in the default mode"
*>
fn RegexToken? TokenizerContext.deflt(&self, usz* consumed) @private
{
    String regex = self.tokenizing;

    foreach (entry : TOP_LEVEL_TOKEN_MAP) 
    {
        if (regex.starts_with(entry.prefix)) 
        {
            *consumed = entry.prefix.len;
            RegexToken result;
            result.type = entry.type;
            return result;
        }
    }

    if (regex[0] == '\\') 
    {
        if (regex.len == 1) return regex::INVALID_ESCAPE_SEQUENCE?;
        if (regex[1].is_digit() && regex[1] != '0') 
        {
            usz end_index = 2;
            for (usz i = end_index; i < regex.len && regex[i].is_digit(); i++) 
            {
                end_index = i;
            }
            *consumed = end_index;
            RegexToken result;
            result.type = BACKREFERENCE;
            result.context.num = regex[1..end_index - 1].to_integer(uint)!;
            if (result.context.num > 65535) return regex::INVALID_CAPTURE_GROUP_ID?;
            return result;
        } 
        else 
        {
            RegexToken result;
            result.type = CHARACTER;
            result.context.ch = handle_escape_character(regex[1..], consumed)!;
            *consumed += 1;
            return result;
        }
    }

    RegexToken result;
    result.type = CHARACTER;
    result.context.ch = regex[0];
    *consumed = 1;
    return result;
}

<*
    @param [&inout] consumed : "How much data was consumed"

    @return "The next regex token in the range qualifier mode"
*>
fn RegexToken? TokenizerContext.rq(&self, usz* consumed) @private
{
    String regex = self.tokenizing;

    if (regex[0] == '}') 
    {
        RegexToken result;
        result.type = RQ_END;
        *consumed = 1;
        return result;
    }
    else if (regex[0] == ',') 
    {
        RegexToken result;
        result.type = RQ_SEPARATOR;
        *consumed = 1;
        return result;
    }

    if (!regex[0].is_digit()) 
    {
        return regex::UNEXPECTED_CHARACTER?;
    }

    while (*consumed < regex.len && regex[*consumed].is_digit()) 
    {
        *consumed += 1;
    }

    RegexToken result;
    result.type = RQ_NUMBER;
    result.context.num = regex[..*consumed - 1].to_integer(uint)!;
    return result;
}

<*
    @param [&inout] consumed : "How much data was consumed"

    @return "The next regex token in the character group mode"
*>
fn RegexToken? TokenizerContext.cg(&self, usz* consumed) @private
{
    String regex = self.tokenizing;

    foreach (entry : CG_TOKEN_MAP) 
    {
        if (regex.starts_with(entry.prefix))
        {
            *consumed = entry.prefix.len;
            RegexToken result;
            result.type = entry.type;
            return result;
        }
    }

    if (!regex.starts_with("\\")) {
        RegexToken result;
        result.type = CHARACTER;
        result.context.ch = regex[0];
        *consumed = 1;
        return result;
    }

    RegexToken result;
    result.type = CHARACTER;
    result.context.ch = handle_escape_character(regex[1..],consumed)!;
    *consumed += 1;

    return result;
}

<*
    Backtrack one regex token

    @require !self.has_stored_backtrack : "This tokenizer can only backtrack one token"
*>
fn void TokenizerContext.backtrack(&self, RegexToken token)
{
    self.has_stored_backtrack = true;
    self.stored_back_track = token;
}