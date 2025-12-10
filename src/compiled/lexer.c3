<*
    This module is a compile time lexer for regexen
    @require ASCII_ONLY.typeid == bool : "The lexer's only configurable option is if it supports ASCII"
*>
module regex::compiled::lexer;

import regex;
import regex::common::tokens;
import regex::utf8;

struct LexerContext
{
    String view;
    TokenizerMode mode;

    bool has_stored_backtrack;
    RegexToken stored_backtrack;
    
    Options options;
}

macro LexerContext with_mode_view(LexerContext $self, TokenizerMode $mode, String $view) =>
{
    $view,
    $mode,
    $self.has_stored_backtrack,
    $self.stored_backtrack,
    $self.options
};

macro LexerContext on(String $regex, Options $options)
{
    return
    {
        $regex,
        DEFLT,
        false,
        {},
        $options
    };
}

struct TokenizerResult
{
    RegexToken token;
    LexerContext next_context;
}

struct SingleTokenizeResult
{
    RegexToken token;
    String continuation;
}

macro Char32 from_hex(char $hi, char $lo) @private => ((Char32)ascii::HEX_VALUE[$hi] << 4) | ((Char32)ascii::HEX_VALUE[$low]);

macro Char32 from_hex_unicode(char $x) @private => ((Char32)ascii::HEX_VALUE[$x]);

macro bool is_xdigit(char $x) @private => ($x >= '0' &&& $x <= '9') ||| ($x >= 'a' &&& $x <= 'f') ||| ($x >= 'A' &&& $x <= 'F');

macro bool is_digit(char $x) @private => $x >= '0' &&& $x <= '9';

macro ComptimeCharacterResult handle_escape_character(String $after_escape) @private
{
    // $if $after_escape.len == 0:
    //     $error "Invalid escape sequence!";
    // $endif
    $assert $after_escape.len > 0 : "Invalid escape sequence!";

    $switch $after_escape[0]:
        $case 't':
            return
            {
                '\t',
                $after_escape[1..]
            };
        $case 'n':
            return
            {
                '\n',
                $after_escape[1..]
            };
        $case 'v':
            return
            {
                '\v',
                $after_escape[1..]
            };
        $case 'f':
            return
            {
                '\f',
                $after_escape[1..]
            };
        $case 'c':
            $assert $after_escape.len > 1 : "Invalid escape sequence!";
            return
            {
                $after_escape[1] & 31,
                $after_escape[2..]
            };
        $case 'x':
            $assert !($after_escape.len < 3 ||| !is_xdigit($after_escape[1]) ||| !is_xdigit($after_escape[2])) : "Invalid escape sequence!";
            return
            {
                from_hex($after_escape[1], $after_escape[2]),
                $after_escape[3..]
            };
        $case 'u':
            $assert !($after_escape.len < 2 ||| !is_xdigit($after_escape[1])) : "Invalid escape sequence!";
            usz $actually_consumed = 1;
            Char32 $result = 0;
            $for $consumed = 1; $consumed < 7 &&& $consumed < $after_escape.len &&& is_xdigit($after_escape[$consumed]); $consumed++:
                $actually_consumed = $consumed;
                $result <<= 4;
                $result |= from_hex_unicode($after_escape[consumed]);
            $endfor;

            $assert $result <= 0x10FFFF : "Invalid escape sequence!";
            return
            {
                $result,
                $after_escape[$actually_consumed..]
            };
        $case '0':
            return
            {
                0,
                $after_escape[1..]
            };
        $default:
            return
            {
                $after_escape[0],
                $after_escape[1..]
            };
    $endswitch
}

macro bool done(LexerContext $self) => !$self.has_stored_backtrack &&& $self.mode == DEFLT &&& $self.view.len == 0;

macro TokenizerResult get_next_token(LexerContext $self)
{
    $if $self.has_stored_backtrack:
        return
        {
            {
                $self.view,
                $self.mode,
                false,
                {},
                $self.options
            },
            $self.stored_backtrack,
            
        };
    $endif

    $if $self.view.len == 0:
        $switch $self.mode:
            $case TokenizerMode.IN_CG:
                $assert false : "Unterminated character group!";
            $case TokenizerMode.IN_RQ:
                $assert false : "Unterminated range quantifier!";
            $default:
                $assert false : "Unexpected end of input!";
        $endswitch
    $endif

    SingleTokenizeResult $result;
    var $copy;

    $switch $self.mode:
        $case TokenizerMode.DEFLT:
            $result = deflt($self);
            $copy = with_mode_view($self, $result.token.type.next_state_regular, $result.continuation);
        $case TokenizerMode.IN_RQ:
            $result = rq($self);
            $copy = with_mode_view($self, $result.token.type.next_state_rq, $result.continuation);
        $case TokenizerMode.IN_CG:
            $result = cg($self);
            $copy = with_mode_view($self, $result.token.type.next_state_cg, $result.continuation);
    $endswitch

    return
    {
        $result.token,
        $copy
    };
}

macro bool starts_with(String $check, String $prefix) @private
{
    $if $check.len < $prefix.len:
        return false;
    $else
        return $check[0:$prefix.len] == $prefix;
    $endif
}

macro uint to_integer(String $to_convert) @private
{
    uint $result = 0;
    $foreach $ch : $to_convert:
        $result *= 10;
        $result += $ch - '0';
    $endforeach
    return $result;
}

/*
    Because the bounds check doesn't allow you to make empty strings...
*/
macro String substr(String $from, usz $start, usz $end = usz.max) @private
{
    $if $start >= $from.len:
        return "";
    $else
        $if $end >= $from.len:
            return $from[$start..];
        $else
            return $from[$start..$end-1];
        $endif
    $endif
}

macro SingleTokenizeResult deflt(LexerContext $self) @private
{
    String $regex = $self.view;
    
    $for usz $i = 0; $i < tokens::TOP_LEVEL_TOKEN_MAP.len; $i++:
        var $entry = tokens::TOP_LEVEL_TOKEN_MAP[$i];
        $if starts_with($regex, $entry.prefix):
            return
            {
                {
                    .type = $entry.type
                },
                substr($regex, $entry.prefix.len)
            };
        $endif
    $endfor

    $if starts_with($regex, tokens::ESCAPE_SEQUENCE):
        $assert $regex.len > tokens::ESCAPE_SEQUENCE.len : "Invalid escape sequence!";

        $if is_digit($regex[tokens::ESCAPE_SEQUENCE.len]) &&& $regex[tokens::ESCAPE_SEQUENCE.len] != '0':
            usz $end = tokens::ESCAPE_SEQUENCE.len + 1;
            $for usz $i = $end; $i < $regex.len &&& is_digit($regex[$i]); i++:
                $end = $i;
            $endfor
            uint $num = to_integer(substr($regex, 1, end_index));
            $assert $num < ushort.max : "Invalid capture group ID!";
            return
            {
                {
                    .type = BACKREFERENCE,
                    .context = {.num = $num}
                },
                $regex[$end..]
            };
        $else
            ComptimeCharacterResult $char_result = handle_escape_character(substr($regex, 1));
            return
            {
                {
                    .type = CHARACTER,
                    .context = {.ch = $char_result.result}
                },
                $char_result.continuation
            };
        $endif
    $endif

    $if $self.options & Options.ASCII_ONLY == 0:
        ComptimeCharacterResult $char_result = utf8::get_character_comptime($regex);
        return
        {
            {
                .type = CHARACTER,
                .context = {.ch = $char_result.result}
            },
            $char_result.continuation
        };
    $else
        return
        {
            {
                .type = CHARACTER,
                .context = {.ch = $regex[0]}
            },
            substr($regex, 1)
        };
    $endif;
}

macro SingleTokenizeResult rq(LexerContext $self) @private
{

    String $regex = $self.view;

    $if $regex[0] == '}':
        return
        {
            {
                .type = RQ_END
            },
            $regex[1..]
        };
    $else
        $if $regex[0] == ',':
            return
            {
                {
                    .type = RQ_SEPARATOR
                },
                $regex[1..]
            };
        $else
            $assert is_digit($regex[0]) : "Unexpected character!";

            usz $end = 0;

            $for usz $i = $end; $i < $regex.len &&& is_digit($regex[$i]); $i++:
                $end = $i;
            $endfor


            uint $num = to_integer(substr($regex, 0, $end+1));

            return
            {
                {
                    .type = RQ_NUMBER,
                    .context = {.num = $num}
                },
                substr($regex, $end + 1)
            };
        $endif
    $endif
}

macro SingleTokenizeResult cg(LexerContext $self) @private
{
    String $regex = $self.view;


    $for usz $i = 0; $i < tokens::CG_TOKEN_MAP.len; $i++:
        var $entry = tokens::CG_TOKEN_MAP[$i];
        $if starts_with($regex, $entry.prefix):
            return
            {
                {
                    .type = entry.type
                },
                substr($regex, $entry.len)
            };
        $endif
    $endfor

    $if starts_with($regex, tokens::ESCAPE_SEQUENCE):
        $assert $regex.len > tokens::ESCAPE_SEQUENCE.len : "Invalid escape sequence!";
        ComptimeCharacterResult $char_result = handle_escape_character(substr($regex,1));
        return
        {
            {
                .type = CHARACTER,
                .context = {.ch = $char_result.result}
            },
            $char_result.continuation
        };
    $else
        $if $self.options & Options.ASCII_ONLY == 0:
            ComptimeCharacterResult $char_result = utf8::get_character_comptime($regex);
            return
            {
                {
                    .type = CHARACTER,
                    .context = {.ch = $char_result.result}
                },
                $char_result.continuation
            };
        $else
            return
            {
                {
                    .type = CHARACTER,
                    .context = {.ch = $regex[0]}
                },
                substr($regex,1)
            };
        $endif;
    $endif
}

macro LexerContext backtrack(LexerContext $self, RegexToken $token) =>
{
    $self.view,
    $self.mode,
    true,
    $token,
    $self.options
};


// macro dump_lex(String $string, Options $options = NONE)
// {
//     $for LexerContext $context = on($string, $options); !done($context); $context = $context:
//         TokenizerResult $result = get_next_token($context);
//         $context = $result.next_context;
//         $echo $result.token.type;
//     $endfor
// }

// fn void fake_lex() @export
// {
//     dump_lex(`(?:\d{3})+`);
// }