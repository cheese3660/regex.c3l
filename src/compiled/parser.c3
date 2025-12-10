<*
    This module contains a compile time implementation of a regex parser (meant for code generated regexen)
*>
module regex::compiled::parser;

import regex::compiled::lexer;
import regex::compiled::class;
import regex::compiled::array;
import regex::common::nodes;
import regex::common::tokens;

<*
    This defines a nodes implementation
*>
struct Node
{
    NodeType type;
    uint[] children; // These are the indices of the nodes children
    uint repeat_count;
    uint group_id;
    ComptimeClass class;
    Char32 character;
}

macro Node repeat_count(Node $self, uint $new_repeat_count)
{
    return
    {
        $self.type,
        $self.children,
        $new_repeat_count,
        $self.group_id,
        $self.class,
        $self.character
    };
}

macro Node combine_children(Node $self, Node $other)
{
    return
    {
        $self.type,
        $self.children +++ $other.children,
        $self.repeat_count,
        $self.group_id,
        $self.class,
        $self.character
    };
}

macro Node prepend_child(Node $self, uint $index)
{
    return
    {
        $self.type,
        (uint[]){$index} +++ $self.children,
        $self.repeat_count,
        $self.group_id,
        $self.class,
        $self.character
    };
}

macro Node postpend_child(Node $self, uint $index)
{
    return
    {
        $self.type,
        $self.children +++ (uint[]){$index},
        $self.repeat_count,
        $self.group_id,
        $self.class,
        $self.character
    };
}

<*
    This stores a regex AST
*>
struct SyntaxTree
{
    Node[] nodes;
    uint root;
}

macro SyntaxTree st_rep_node(SyntaxTree $self, uint $pos, Node $new)
{
    return
    {
        array::replace{Node}($self.nodes, $pos, $new),
        $self.root
    };
}

struct StNewNode
{
    uint index;
    SyntaxTree new_tree;
}

macro StNewNode st_add_node(SyntaxTree $self, Node $new)
{
    return
    {
        (uint)$self.nodes.len,
        {
            array::push{Node}($self.nodes, $new),
            $self.root
        }
    };
}

<*
    Let's not do as fancy a memory thing as the runtime parser, as it doesn't entirely matter
*>
struct ParserContext
{
    LexerContext lexer;
    SyntaxTree tree;
    ushort capture_group;
}

macro ParserContext backtrack(ParserContext $self, RegexToken $token)
{
    return
    {
        lexer::backtrack($self.lexer,$token),
        $self.tree,
        $self.capture_group
    };
}

struct NextToken
{
    RegexToken token;
    ParserContext context;
}

macro NextToken next(ParserContext $self)
{
    TokenizerResult $result = lexer::get_next_token($self.lexer);
    return
    {
        $result.token,
        {
            $result.next_context,
            $self.tree,
            $self.capture_group
        }
    };
}

macro bool done(ParserContext $self) => lexer::done($self.lexer);

struct NewNode
{
    uint index;
    ParserContext context;
}

macro NewNode new(ParserContext $self, Node $value)
{
    StNewNode $result = st_add_node($self.tree, $value);
    return
    {
        $result.index,
        {
            $self.lexer,
            $result.new_tree,
            $self.capture_group
        }
    };
}

struct NewCaptureGroup
{
    ushort index;
    ParserContext context;
}

macro NewCaptureGroup next_cg(ParserContext $self)
{
    $assert $self.capture_group < ushort.max - 1 : "Regex is too complex!";
    ushort $result = $self.capture_group + 1;
    return
    {
        $result,
        {
            $self.lexer,
            $self.tree,
            $result
        }
    };
}

macro ParserContext replace(ParserContext $self, uint $index, Node $value)
{
    return
    {
        $self.lexer,
        st_rep_node($self.tree, $index, $value),
        $self.capture_group
    };
}

macro NewNode disjunction(ParserContext $self, uint $left_index, uint $right_index)
{

    var $left = $self.tree.nodes[$left_index];
    var $right = $self.tree.nodes[$right_index];
    $if $left.type == DISJUNCT:
        $if $right.type == DISJUNCT:
            return
            {
                $left_index,
                replace($self, $left_index, combine_children($left, $right))
            };
        $else
            return
            {
                $left_index,
                replace($self, $left_index, postpend_child($left, $right_index))
            };
        $endif
    $else
        $if $right.type == DISJUNCT:
            return
            {
                $right_index,
                replace($self, $right_index, prepend_child($right, $left_index))
            };
        $else
            return new($self, {.type = DISJUNCT, .children = (uint[]){$left_index,$right_index}});
        $endif
    $endif
}

macro NewNode concatenation(ParserContext $self, uint $left_index, uint $right_index)
{
    var $left = $self.tree.nodes[$left_index];
    var $right = $self.tree.nodes[$right_index];
    bool $continue = true;
    $if $left.type == $right.type:
        $switch $left.type:
            $case NodeType.CONCAT:
                $continue = false;
                return
                {
                    $left_index,
                    replace($self, $left_index, combine_children($left, $right))
                };
            $case NodeType.CHARACTER:
                $if $left.character == $right.character:
                    $continue = false;
                    return
                    {
                        $left_index,
                        replace($self, $left_index, repeat_count($left, $left.repeat_count + $right.repeat_count))
                    };
                $endif
            $case NodeType.WILDCARD:
                $continue = false;
                return
                {
                    $left_index,
                    replace($self, $left_index, repeat_count($left, $left.repeat_count + $right.repeat_count))
                };
            $case NodeType.BACKREF:
                $continue = false;
                $if $left.group_id == $right.group_id:
                    return
                    {
                        $left_index,
                        replace($self, $left_index, repeat_count($left.repeat_count + $right.repeat_count))
                    };
                $endif
        $endswitch
    $endif
    $if $continue &&& $left.type == CONCAT:
        $continue = false;
        Node $last = $self.tree.nodes[$left.children[$left.children.len-1]];
        $switch:
            $case $last.type == CHARACTER &&& $right.type == CHARACTER &&& $left.character == $right.character:
                return
                {
                    $left_index,
                    replace($self, $left.children[$left.children.len-1], repeat_count($last, $last.repeat_count + $right.repeat_count))
                };
            $case $last.type == WILDCARD &&& $right.type == WILDCARD:
                return
                {
                    $left_index,
                    replace($self, $left.children[$left.children.len-1], repeat_count($last, $last.repeat_count + $right.repeat_count))
                };
            $case $last.type == BACKREF &&& $right.type == BACKREF &&& $left.group_id == $right.group_id:
                return
                {
                    $left_index,
                    replace($self, $left.children[$left.children.len-1], repeat_count($last, $last.repeat_count + $right.repeat_count))
                };
            $default:
                return
                {
                    $left_index,
                    replace($self, $left_index, postpend_child($left, $right_index))
                };
        $endswitch
    $endif
    $if $continue &&& $right.type == CONCAT:
        $continue = false;
        return
        {
            $right_index,
            replace($self, $right_index, prepend_child($right,$left_index))
        };
    $endif
    $if $continue:
        return new($self,
            {
                .type = CONCAT,
                .children = (uint[]){$left_index, $right_index}
            }
        );
    $endif
}

macro NewNode exactly(ParserContext $self, uint $child_index, uint $repeat)
{
    $if $repeat == 1:
        return {
            $child_index,
            $self
        };
    $else
        var $child = $self.tree.nodes[$child_index];
        $switch $child.type:
            $case WILDCARD:
            $case CHARACTER:
            $case BACKREF:
            $case NEGATIVE_CG:
            $case POSITIVE_CG:
            $case EXACTLY:
                return
                {
                    $child_index,
                    replace($self, $child_index, repeat_count($child, $child.repeat_count * $repeat))
                };
            $default:
                return new($self,
                    {
                        .type = EXACTLY,
                        .children = (uint[]){$child_index},
                        .repeat_count = $repeat
                    }
                );
        $endswitch
    $endif
}

macro NewNode at_least(ParserContext $self, uint $child_index, uint $min)
{
    var $child = $self.tree.nodes[$child_index];
    uint $true_child;
    $switch $child.type:
        $case CHARACTER:
        $case WILDCARD:
        $case BACKREF:
        $case NEGATIVE_CG:
        $case POSITIVE_CG:
        $case EXACLTY:
            var $result = new($self, $child);
            $true_child = $result.index;
            $self = $result.context;
        $default:
            $true_child = $child_index;
    $endswitch
    var $exact = exactly($self, $child_index, $min);
    $self = $exact.context;
    var $zero_or_more = new($self, {.type = ZERO_OR_MORE, .children = (uint[]){$true_child}});
    $self = $zero_or_more.context;
    return concatenation($self, $exact.index, $zero_or_more.index);
}

macro NewNode between(ParserContext $self, uint $child_index, uint $min, uint $max)
{
    $assert $min < $max : "Invalid range quantifier!";

    var $child = $self.tree.nodes[$child_index];
    $if $min > 0:
        uint $true_child;
        $switch $child.type:
            $case CHARACTER:
            $case WILDCARD:
            $case BACKREF:
            $case NEGATIVE_CG:
            $case POSITIVE_CG:
            $case EXACLTY:
                var $result = new($self, $child);
                $true_child = $result.index;
                $self = $result.context;
            $default:
                $true_child = $child_index;
        $endswitch
        var $exact = exactly($self, $child_index, $min);
        $self = $exact.context;
        var $at_most = new($self, {.type = AT_MOST, .children = (uint[]){$true_child}, .repeat_count = $max - $min});
        $self = $at_most.context;
        return concatenation($self, $exact.index, $at_most.index);
    $else
        return new($self, {.type = AT_MOST, .first_child = $child_index, .repeat_count = $max });
    $endif
}

macro SyntaxTree parse(String $regex, Options $options)
{
    ParserContext $start = {lexer::on($regex, $options), {}, {}};
    NewNode $result = expr($start);
    return
    {
        $result.context.tree.nodes,
        $result.index
    };
}

macro NewNode expr(ParserContext $self, bool $return_on_gp_end = false, bool $return_on_separator = false)
{
    NewNode $previous_n = quantified($self);
    $self = $previous_n.context;
    uint $previous = $previous_n.index;
    bool $running = true;
    // We want a while loop here basically
    $for var $i = 0; $running &&& !done($self); $i++:
        NextToken $next_t = next($self);
        $self = $next_t.context;
        RegexToken $next = $next_t.token;

        $switch:
            $case $return_on_gp_end &&& $next.type == GROUP_END:
                $running = false;
                return
                {
                    $previous,
                    $self
                };

            $case !$return_on_gp_end &&& $next.type == GROUP_END:
                $error "Extraneous parentheses!";
            $case $next.type == SEPARATOR &&& !$return_on_separator:
                NewNode $expr_n = expr($self, $return_on_gp_end, true);
                $self = $expr_n.context;
                uint $expr = $expr_n.index;
                $previous_n = disjunction($self, $previous, $expr);
                $self = $previous_n.context;
                $previous = $previous_n.index;

            $case $next.type == SEPARATOR &&& $return_on_separator:
                $running = false;
                $self = backtrack($self, $next);
                return
                {
                    $previous,
                    $self
                };

            $default:
                $self = backtrack($self,$next);
                NewNode $quantified_n = quantified($self);
                $self = $quantified_n.context;
                uint $quantified = $quantified_n.index;
                $previous_n = concatenation($self, $previous, $quantified);
                $self = $previous_n.context;
                $previous = $previous_n.index;
        $endswitch
    $endfor

    $assert !($running &&& $return_on_gp_end) : "Unterminated subexpression!";

    return
    {
        $previous,
        $self
    };
}

macro NewNode quantified(ParserContext $self)
{
    NewNode $primary_n = primary($self);
    $self = $primary_n.context;
    $if done($primary_n.context):
        return $primary_n;
    $else
        NextToken $peek_n = next($self);
        $self = $peek_n.context;
        $switch $peek_n.token.type:
            $case RQ_BEGIN:
                $peek_n = next($self);
                $assert $peek_n.token.type != RQ_END && $peek_n.token.type != RQ_SEPARATOR : "Invalid range quantifier!";
                $self = $peek_n.context;
                uint $begin = $peek_n.token.context.num;
                
                $peek_n = next($self);
                $self = $peek_n.context;
                $if $peek_n.token.type == RQ_END:
                    return exactly($self, $primary_n.index, $begin);
                $else
                    $peek_n = next($self);
                    $self = $peek_n.context;
                    $if $peek_n.token.type == RQ_END:
                        return at_least($self, $primary_n.index, $begin);
                    $else
                        uint $end = $peek_n.token.context.num;
                        $peek_n = next($self);
                        $self = $peek_n.context;
                        $if $peek_n.token.type == RQ_END:
                            return between($self, $primary_n.index, $begin, $end);
                        $else
                            $error "Invalid range quantifier!";
                        $endif
                    $endif
                $endif
            $case ONE_OR_MORE:
                return new($self, {.type = ONE_OR_MORE, .children = (uint[]){$primary_n.index}});
            $case ZERO_OR_MORE:
                return new($self, {.type = ZERO_OR_MORE, .children = (uint[]){$primary_n.index}});
            $case ZERO_OR_ONE:
                return new($self, {.type = ZERO_OR_ONE, .children = (uint[]){$primary_n.index}});
            $default:
                return $primary_n;
        $endswitch
    $endif
}

macro NewNode primary(ParserContext $self)
{
    NextToken $peek_n = next($self);
    $self = $peek_n.context;
    $switch $peek_n.token.type:
        $case CHARACTER:
            return new($self, {.type = CHARACTER, .character = $peek_n.token.context.ch, .repeat_count = 1});
        $case POS_CG_BEGIN:
            NewClass $class_n = class($self);
            return new($class_n.context, {.type = POSITIVE_CG, .class = $class_n.class, .repeat_count = 1});
        $case NEG_CG_BEGIN:
            NewClass $class_n = class($self);
            return new($class_n.context, {.type = NEGATIVE_CG, .class = $class_n.class, .repeat_count = 1});
        $case WILDCARD:
            return new($self, {.type = WILDCARD, .repeat_count = 1});
        $case WORD:
            return new($self, {.type = POSITIVE_CG, .class = class::is_word({}), .repeat_count = 1});
        $case NON_WORD:
            return new($self, {.type = NEGATIVE_CG, .class = class::is_word({}), .repeat_count = 1});
        $case WHITESPACE:
            return new($self, {.type = POSITIVE_CG, .class = class::is_space({}), .repeat_count = 1});
        $case NON_WHITESPACE:
            return new($self, {.type = NEGATIVE_CG, .class = class::is_space({}), .repeat_count = 1});
        $case DIGIT:
            return new($self, {.type = POSITIVE_CG, .class = class::is_digit({}), .repeat_count = 1});
        $case NON_DIGIT:
            return new($self, {.type = NEGATIVE_CG, .class = class::is_digit({}), .repeat_count = 1});
        $case BEGINNING:
            return new($self, {.type = START_ANCHOR});
        $case END:
            return new($self, {.type = END_ANCHOR});
        $case WORD_BOUNDARY:
            return new($self, {.type = WORD_ANCHOR});
        $case NOT_WORD_BOUNDARY:
            return new($self, {.type = NOT_WORD_ANCHOR});
        $case GROUP_OPEN:
            NewCaptureGroup $group_n = next_cg($self);
            NewNode $expr_n = expr($group_n.context,true);
            return new($expr_n.context, {.type = CAPTURE_GROUP, .group_id = $group_n.index, .children = (uint[]){$expr_n.index}});
        $case NO_BR_GROUP_OPEN:
            return expr($self,true);
        $case POS_LOOK:
            NewNode $expr_n = expr($self,true);
            return new($expr_n.context, {.type = POSITIVE_LOOKAHEAD, .children = (uint[]){$expr_n.index}});
        $case NEGATIVE_LOOKAHEAD:
            NewNode $expr_n = expr($self,true);
            return new($expr_n.context, {.type = NEGATIVE_LOOKAHEAD, .children = (uint[]){$expr_n.index}});
        $case BACKREFERENCE:
            $assert $self.capture_group >= $peek.token.context.num : "Invalid capture group ID for backreference!";
            return new($self, {.type = BACKREF, .group_id = (ushort)$peek.token.context.num});
        $default:
            $error "Unexpected token!";
    $endswitch
}

struct NewClass
{
    ComptimeClass class;
    ParserContext context;
}

macro NewClass class(ParserContext $self)
{
    ComptimeClass $class;

    NextToken $next_n = next($self);
    $self = $next_n.context;

    // Similar while loop
    $for usz $i = 0; $next_n.token.type != CG_END; $i++:
        $switch $next_n.token.type:
            $case ALNUM_CLASS:
                $class = class::is_alnum($class);
            $case ALPHA_CLASS:
                $class = class::is_alpha($class);
            $case BLANK_CLASS:
                $class = class::is_blank($class);
            $case CNTRL_CLASS:
                $class = class::is_cntrl($class);
            $case GRAPH_CLASS:
                $class = class::is_graph($class);
            $case LOWER_CLASS:
                $class = class::is_lower($class);
            $case PRINT_CLASS:
                $class = class::is_print($class);
            $case SPACE_CLASS:
                $class = class::is_space($class);
            $case UPPER_CLASS:
                $class = class::is_upper($class);
            $case XDIGT_CLASS:
                $class = class::is_xdigt($class);
            $case PUNCT_CLASS:
                $class = class::is_punct($class);
            $case DIGIT_CLASS:
                $class = class::is_digit($class);
            $case DASH:
                $class = class::with($class, '-');
            $case CHARACTER:
                NextToken $pos_dash = next($self);
                $if $pos_dash.token.type == DASH:
                    NextToken $range_end = next($pos_dash.context);
                    $if $range_end.token.type == CHARACTER:
                        $class = class::range($class, $next_n.token.context.ch, $range_end.token.context.ch);
                        $self = $range_end.context;
                    $else
                        $class = class::with($class, $next_n.token.context.ch);
                    $endif
                $else
                    $class = class::with($class, $next_n.token.context.ch);
                $endif
            $default:
                $error "Unexpected character!";
        $endswitch
        $next_n = next($self);
        $self = $next_n.context;
    $endfor

    return
    {
        $class,
        $self
    };
}

// fn void dump_parse()
// {
//     parse(`^(?=(?:.*[A-Z]){2})(?=(?:.*[a-z]){2})(?=.*\\d).{8,15}$`,NONE);
// }