<*
    This module implements a runtime regex parser
*>
module regex::runtime::parsing;

import regex;
import regex::runtime::lexing;
import regex::runtime::character_class;
import regex::character_functions;

<* What type of node is this node *>
enum RegexNodeType : char
{
    WILDCARD,               // .
    CHARACTER,              // A single character, can be repeated any number of times
                            // The lowering step is what will do the eventual character to string conversion
    BACKREF,                // A backreference (\x)
    CONCAT,                 // 2 nodes followed by eachother
    DISJUNCT,               // |
    NEGATIVE_CG,            // [^...]
    POSITIVE_CG,            // [...]
    START_ANCHOR,           // ^
    END_ANCHOR,             // $
    WORD_ANCHOR,            // \w
    NOT_WORD_ANCHOR,        // \W
    AT_LEAST,               // {x,}
    AT_MOST,                // {,y} (this is actually to implement "BETWEEN" which is concat of exactly and at_most)
    ONE_OR_MORE,            // +
    ZERO_OR_MORE,           // *
    ZERO_OR_ONE,            // ?
    EXACTLY,                // {x}
    CAPTURE_GROUP,          // (...)
    POSITIVE_LOOKAHEAD,     // (?=...)
    NEGATIVE_LOOKAHED,      // (?:...)
}

struct RegexNode
{
    RegexNodeType type;
    union
    {
        struct node_and_number
        {
            RegexNode* child;
            uint repeat_count;
        }

        struct backref
        {
            ushort group_id;
            uint repeat_count;
        }

        struct capture_group
        {
            RegexNode* child;
            ushort group_id;
        }

        struct character_group
        {
            CharacterClass class;
            uint repeat_count;
        }

        RegexNode* child;

        struct binary {
            RegexNode* lhs;
            RegexNode* rhs;
        }

        struct character
        {
            Char32 character;
            uint repeat_count;
        }

        uint repeat_count;
    }
}

<*
    Create a disjunction node between 2 regex nodes

    @return "A disjunction node between 2 regex nodes"
*>
macro RegexNode* disjunction(RegexNode* left, RegexNode* right) @private
{
    RegexNode* result = mem::talloc(RegexNode);
    result.type = DISJUNCT;
    result.binary.lhs = left;
    result.binary.rhs = right;
    return result;
}

<*
    Create a concatenation node between 2 regex nodes
    (This will also attempt to just combine nodes that can be combined)

    @return "A node that represents the concatenation of 2 regex nodes"
*>
fn RegexNode* concatenation(RegexNode* left, RegexNode* right) @private
{
    if (left.type == right.type) 
    {
        switch (left.type)
        {
            case CHARACTER:
                if (left.character.character == right.character.character)
                {
                    left.character.repeat_count += right.character.repeat_count;
                    return left;
                }
            case WILDCARD:
                left.repeat_count += right.repeat_count;
                return left;
            case BACKREF:
                if (left.backref.group_id == right.backref.group_id)
                {
                    left.backref.repeat_count += right.backref.repeat_count;
                    return left;
                }
            default:
        }
    }
    if (left.type == CONCAT && left.binary.rhs.type == right.type) {
        switch (right.type)
        {
            case CHARACTER:
                if (left.character.character == right.character.character)
                {
                    left.binary.rhs.character.repeat_count += right.character.repeat_count;
                    return left;
                }
            case WILDCARD:
                left.binary.rhs.repeat_count += right.repeat_count;
                return left;
            case BACKREF:
                if (left.binary.rhs.backref.group_id == right.backref.group_id)
                {
                    left.binary.rhs.backref.repeat_count += right.backref.repeat_count;
                    return left;
                }
            default:
        }
    }
    RegexNode* result = mem::talloc(RegexNode);
    result.type = CONCAT;
    result.binary.lhs = left;
    result.binary.rhs = right;
    return result;
}

<*
    @return "A node that represents a regex node repeated exactly N times"
*>
macro RegexNode* exactly(RegexNode* child, uint repeat) @private
{
    if (repeat == 1) return child;
    switch (child.type)
    {
        case WILDCARD:
            child.repeat_count *= repeat;
            return child;
        case CHARACTER:
            child.character.repeat_count *= repeat;
            return child;
        case BACKREF:
            child.backref.repeat_count *= repeat;
            return child;
        case NEGATIVE_CG:
        case POSITIVE_CG:
            child.character_group.repeat_count *= repeat;
            return child;
        default:
            RegexNode* result = mem::talloc(RegexNode);
            result.type = EXACTLY;
            result.node_and_number.child = child;
            result.node_and_number.repeat_count = repeat;
            return result;
    }
}

<*
    @return "A node representing a capture group"
*>
macro RegexNode* capture_group(RegexNode* child, ushort group_id) @private
{
    RegexNode* result = mem::talloc(RegexNode);
    result.type = CAPTURE_GROUP;
    result.capture_group.child = child;
    result.capture_group.group_id = group_id;
    return result;
}

<*
    @return "A node of a given type with a single child"
*>
macro RegexNode* single_child(RegexNode* child, RegexNodeType type) @private
{
    RegexNode* result = mem::talloc(RegexNode);
    result.type = type;
    result.child = child;
    return result;
}

<*
    @return "A node that represents a regex node repeated at least N times"
*>
macro RegexNode* at_least(RegexNode* child, uint min) @private
{
    RegexNode* true_child;
    switch (child.type)
    {
        case CHARACTER:
        case WILDCARD:
        case BACKREF:
        case NEGATIVE_CG:
        case POSITIVE_CG:
            true_child = mem::talloc(RegexNode);
            *true_child = *child;
        default:
            true_child = child;
    }
    RegexNode* exact = exactly(child, min);
    return concatenation(exact,single_child(true_child, ZERO_OR_MORE));
}

<*
    @return "A node that represents a regex node repeated at most N times"
*>
macro RegexNode* at_most(RegexNode* child, uint max) @private
{
    RegexNode* result = mem::talloc(RegexNode);
    result.type = AT_MOST;
    result.node_and_number.child = child;
    result.node_and_number.repeat_count = max;
    return result;
}

<*
    @return "A node that represents a regex node repeated between min and max times"
*>
macro RegexNode*? between(RegexNode* child, uint min, uint max) @private
{
    if (min > max) 
    {
        return regex::INVALID_RANGE_QUANTIFIER?;
    }

    if (min > 0) 
    {
        RegexNode* true_child;
        switch (child.type)
        {
            case CHARACTER:
            case WILDCARD:
            case BACKREF:
            case NEGATIVE_CG:
            case POSITIVE_CG:
                true_child = mem::talloc(RegexNode);
                *true_child = *child;
            default:
                true_child = child;
        }
        RegexNode* exact = exactly(child, min);
        return concatenation(exact, at_most(true_child, max - min));
    } 
    else 
    {
        return at_most(child, max);
    }
}

<*
    @return "A node that represents a character group [...] or \\d and \\w"
*>
macro RegexNode* character_class(CharacterClass class, RegexNodeType type) @private
{
    RegexNode* node = mem::talloc(RegexNode);
    node.type = type;
    node.character_group.class = class;
    node.character_group.repeat_count = 1;
    return node;
}

<*
    @return "A node that represents a backreference"
*>
macro RegexNode*? backreference(uint num) @private
{
    if (num > 65535) return regex::INVALID_CAPTURE_GROUP_ID?;
    
    RegexNode* node = mem::talloc(RegexNode);
    node.type = BACKREF;
    node.backref.group_id = (ushort)num;
    node.backref.repeat_count = 1;
    return node;
}

const RegexNode WILDCARD_STATIC @private = {
    .type = WILDCARD,
    .repeat_count = 1
};

const RegexNode START_ANCHOR_STATIC @private = {
    .type = START_ANCHOR
};

const RegexNode END_ANCHOR_STATIC @private = {
    .type = END_ANCHOR
};

const RegexNode WORD_ANCHOR_STATIC @private = {
    .type = WORD_ANCHOR
};

const RegexNode NOT_WORD_ANCHOR_STATIC @private = {
    .type = NOT_WORD_ANCHOR
};


<*
    Allocates on tmem so make sure a pool is set up

    @param regex : "The regex to be parsed"
    @param options : "The options to be passed to the regex parser"

    @return "A parsed regex"
*>
fn RegexNode*? parse_regex(String regex, Options options)
{
    RegexParser parser = {
        lexing::on(regex, options),
        1
    };
    return parser.expr();
}

struct RegexParser @private
{
    TokenizerContext tokenizer;
    ushort capture_group;
}

<*
    @return? regex::REGEX_TOO_COMPLEX : "The regex has gone over 65534 capture groups"

    @return "Next capture group id"
*>
fn ushort? RegexParser.next_cg(&self) @private
{
    if (self.capture_group == ushort.max) return regex::REGEX_TOO_COMPLEX?;
    return self.capture_group++;
}


<*
    Parse a top level expression

    @return "A regex node allocated using tmem"
*>
fn RegexNode*? RegexParser.expr(&self, bool return_on_gp_end = false) @private
{
    RegexNode* previous = self.quantified()!;
    while (!self.tokenizer.done())
    {
        RegexToken next = self.tokenizer.get_next_token()!;
        if (return_on_gp_end && next.type == GROUP_END)
        {
            return previous;
        }
        if (!return_on_gp_end && next.type == GROUP_END)
        {
            return regex::EXTRANEOUS_PARENTHESES?;
        }
        if (next.type == SEPARATOR)
        {
            return disjunction(previous, self.expr(return_on_gp_end)!);
        }
        self.tokenizer.backtrack(next);
        previous = concatenation(previous, self.quantified()!);
    }
    if (return_on_gp_end)
    {
        return regex::UNTERMINATED_SUBEXPRESSION?;
    }
    return previous;
}

<*
    Parse a quantified expression (that is a primary with a number amount)

    @return "A regex node allocated using tmem"
*>
fn RegexNode*? RegexParser.quantified(&self) @private
{
    
    RegexNode* primary = self.primary()!;

    if (self.tokenizer.done()) return primary;

    RegexToken peek = self.tokenizer.get_next_token()!;
    switch (peek.type)
    {
        case RQ_BEGIN:
            peek = self.tokenizer.get_next_token()!;
            if (peek.type == RQ_END) return regex::UNFILLED_RANGE_QUANTIFIER?;
            if (peek.type == RQ_SEPARATOR) return regex::INVALID_RANGE_QUANTIFIER?;
            uint begin = peek.context.num;
            peek = self.tokenizer.get_next_token()!;
            if (peek.type == RQ_END)
            {
                return exactly(primary, begin);
            }
            peek = self.tokenizer.get_next_token()!;
            if (peek.type == RQ_END)
            {
                return at_least(primary, begin);
            }
            uint end = peek.context.num;
            peek = self.tokenizer.get_next_token()!;
            if (peek.type == RQ_END)
            {
                return between(primary, begin, end)!;
            }
            return regex::INVALID_RANGE_QUANTIFIER?;
        case ONE_OR_MORE:
            return single_child(primary, ONE_OR_MORE);
        case ZERO_OR_MORE:
            return single_child(primary, ZERO_OR_MORE);
        case ZERO_OR_ONE:
            return single_child(primary, ZERO_OR_ONE);
        default:
            self.tokenizer.backtrack(peek);
            return primary;
    }
}

<*
    Parse a primary regex node (that is one that defines what exactly to match)

    @return "A regex node allocated using tmem"
*>
fn RegexNode*? RegexParser.primary(&self) @private
{
    
    RegexToken original = self.tokenizer.get_next_token()!;
    
    switch (original.type)
    {
        case CHARACTER:
        {
            // Build a string finally
            RegexNode* result = mem::talloc(RegexNode);
            result.type = CHARACTER;
            result.character.character = original.context.ch;
            result.character.repeat_count = 1;
            return result;
        }
        case POS_CG_BEGIN:
            return character_class(self.class()!, POSITIVE_CG);
        case NEG_CG_BEGIN:
            return character_class(self.class()!, NEGATIVE_CG);
        case WILDCARD:
            RegexNode* copy = mem::talloc(RegexNode);
            *copy = WILDCARD_STATIC;
            return copy;
        case WORD:
            CharacterClass result;
            result.add_fn(&character_functions::is_word);
            return character_class(result, POSITIVE_CG);
        case NON_WORD:
            CharacterClass result;
            result.add_fn(&character_functions::is_word);
            return character_class(result, NEGATIVE_CG);
        case WHITESPACE:
            CharacterClass result;
            result.add_fn(&character_functions::is_space);
            return character_class(result, POSITIVE_CG);
        case NON_WHITESPACE:
            CharacterClass result;
            result.add_fn(&character_functions::is_space);
            return character_class(result, NEGATIVE_CG);
        case DIGIT:
            CharacterClass result;
            result.add_fn(&character_functions::is_digit);
            return character_class(result, POSITIVE_CG);
        case NON_DIGIT:
            CharacterClass result;
            result.add_fn(&character_functions::is_digit);
            return character_class(result, NEGATIVE_CG);
        case BEGINNING:
            return &START_ANCHOR_STATIC;
        case END:
            return &END_ANCHOR_STATIC;
        case WORD_BOUNDARY:
            return &WORD_ANCHOR_STATIC;
        case NOT_WORD_BOUNDARY:
            return &NOT_WORD_ANCHOR_STATIC;
        case GROUP_OPEN:
            ushort group_id = self.next_cg()!;
            return capture_group(self.expr(true)!,group_id);
        case NO_BR_GROUP_OPEN:
            return self.expr(true)!;
        case POS_LOOK:
            return single_child(self.expr(true)!,POSITIVE_LOOKAHEAD);
        case NEG_LOOK:
            return single_child(self.expr(true)!,NEGATIVE_LOOKAHED);
        case BACKREFERENCE:
            return backreference(original.context.num)!;
        default:
            return regex::UNEXPECTED_TOKEN?;
    }
}

fn CharacterClass? RegexParser.class(&self) @private
{
    RegexToken next = self.tokenizer.get_next_token()!;
    CharacterClass class;
    while (next.type != CG_END)
    {
        switch (next.type) {
            case ALNUM_CLASS:
                class.add_fn(&character_functions::is_alnum);
            case ALPHA_CLASS:
                class.add_fn(&character_functions::is_alpha);
            case BLANK_CLASS:
                class.add_fn(&character_functions::is_blank);
            case CNTRL_CLASS:
                class.add_fn(&character_functions::is_cntrl);
            case GRAPH_CLASS:
                class.add_fn(&character_functions::is_graph);
            case LOWER_CLASS:
                class.add_fn(&character_functions::is_lower);
            case PRINT_CLASS:
                class.add_fn(&character_functions::is_print);
            case SPACE_CLASS:
                class.add_fn(&character_functions::is_space);
            case UPPER_CLASS:
                class.add_fn(&character_functions::is_upper);
            case XDIGT_CLASS:
                class.add_fn(&character_functions::is_xdigit);
            case PUNCT_CLASS:
                class.add_fn(&character_functions::is_punct);
            case DIGIT_CLASS:
                class.add_fn(&character_functions::is_digit);
            case DASH:
                class.add_character('-');
            case CHARACTER:
                RegexToken possibleDash = self.tokenizer.get_next_token()!;
                if (possibleDash.type == DASH) {
                    RegexToken range_end = self.tokenizer.get_next_token()!;
                    if (range_end.type == CHARACTER)
                    {
                        class.add_range(next.context.ch, range_end.context.ch);
                    } else {
                        self.tokenizer.backtrack(range_end);
                        class.add_character(next.context.ch);
                        class.add_character('-');
                    }
                } else {
                    self.tokenizer.backtrack(possibleDash);
                    class.add_character(next.context.ch);
                }
            default:
                return regex::UNEXPECTED_CHARACTER?;
        }
        next = self.tokenizer.get_next_token()!;
    }
    return class;
}