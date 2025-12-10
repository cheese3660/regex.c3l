<*
    This is a compile time implementation of the concept of a character class
*>
module regex::compiled::class;

import regex::character_functions;

struct ComptimeRange
{
    Char32 min;
    Char32 max;
}

struct ComptimeClass
{
    Char32[] with;
    ComptimeRange[] ranges;
    bool is_word;
    bool is_alnum;
    bool is_space;
    bool is_digit;
    bool is_alpha;
    bool is_blank;
    bool is_cntrl;
    bool is_graph;
    bool is_lower;
    bool is_upper;
    bool is_print;
    bool is_xdigit;
    bool is_punct;
}

macro ComptimeClass with(ComptimeClass $self, Char32 ch)
{
    return
    {
        $self.with +++ {ch},
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass range(ComptimeClass $self, Char32 $min, Char32 $max)
{
    return
    {
        $self.with,
        $self.ranges +++ (ComptimeRange[]){{$min,$max}},
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_word(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        true,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_alnum(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        true,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_space(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        true,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_digit(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        true,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_alpha(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        true,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}


macro ComptimeClass is_blank(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        true,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_cntrl(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        true,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_graph(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        true,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_lower(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        true,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_upper(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        true,
        $self.is_print,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_print(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        true,
        $self.is_xdigit,
        $self.is_punct
    };
}

macro ComptimeClass is_xdigit(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        true,
        $self.is_punct
    };
}

macro ComptimeClass is_punct(ComptimeClass $self)
{
    return
    {
        $self.with,
        $self.ranges,
        $self.is_word,
        $self.is_alnum,
        $self.is_space,
        $self.is_digit,
        $self.is_alpha,
        $self.is_blank,
        $self.is_cntrl,
        $self.is_graph,
        $self.is_lower,
        $self.is_upper,
        $self.is_print,
        $self.is_xdigit,
        true,
    };
}

macro ComptimeClass codegen(ComptimeClass $self, bool $ignore_case, Char32 check)
{
    $if $ignore_case:
        codegen($self, false, check < 128 ? ((char)check.to_lower()) : check) || codegen($self, false, check < 128 ? ((char)check.to_upper()) : check); 
    $else
        $foreach $ch : $self.with:
            if (check == ch) return true;
        $endforeach

        $foreach $r : $self.ranges:
            if (check >= $r.min && check <= $r.max) return true;
        $endforeach

        $if $self.is_word:
            if (character_functions::is_word(check)) return true;
        $endif

        $if $self.is_alnum:
            if (character_functions::is_alnum(check)) return true;
        $endif

        $if $self.is_space:
            if (character_functions::is_space(check)) return true;
        $endif

        $if $self.is_digit:
            if (character_functions::is_digit(check)) return true;
        $endif

        $if $self.is_alpha:
            if (character_functions::is_alpha(check)) return true;
        $endif

        $if $self.is_blank:
            if (character_functions::is_blank(check)) return true;
        $endif

        $if $self.is_cntrl:
            if (character_functions::is_cntrl(check)) return true;
        $endif

        $if $self.is_graph:
            if (character_functions::is_graph(check)) return true;
        $endif

        $if $self.is_lower:
            if (character_functions::is_lower(check)) return true;
        $endif

        $if $self.is_upper:
            if (character_functions::is_upper(check)) return true;
        $endif

        $if $self.is_print:
            if (character_functions::is_print(check)) return true;
        $endif

        $if $self.is_punct:
            if (character_functions::is_punct(check)) return true;
        $endif

    $endif
    return false;
}