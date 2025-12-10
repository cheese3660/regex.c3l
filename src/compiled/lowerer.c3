<*
    This module contains macros for lowering regexen into a compile time structure

    We can modify our previous tree syntax to make recursion depth minimal in this step, only adding a new step really on `(` and `|`
*>
module regex::compiled::lowerer;
import regex::common::states;
import regex::compiled::array;
import regex::compiled::class;
import regex::compiled::parser;
import regex;

struct Edge
{
    TransitionType transition_type;
    uint next_state;
    uint backref_id;
    uint repeat_count;
    ushort subautomaton_id;
    Char32[] string;
    ComptimeClass character_class;
    ushort open_cg;
    ushort close_cg;
}

macro Edge remap(Edge $self, uint $new_next_state)
{
    return
    {
        $self.transition_type,
        $new_next_state,
        $self.backref_id,
        $self.repeat_count,
        $self.subautomaton_id,
        $self.string,
        $self.character_class,
        $self.open_cg,
        $self.close_cg
    };
}

struct State
{
    uint[] edges;
}

struct ComptimeAutomaton
{
    uint begin;
    uint end;
    State[] states;
    Edge[] edges;
}

macro ComptimeAutomaton ct_begin_end(ComptimeAutomaton $self, uint $begin, uint $end)
{
    return
    {
        $begin,
        $end,
        $self.states,
        $self.edges
    };
}

macro ComptimeAutomaton ct_add_edge(ComptimeAutomaton $self, uint $state, Edge $edge)
{
    return
    {
        $self.begin,
        $self.end,
        array::replace{State}($self.states, $state ,(State){$self.states[$state].edges +++ (uint[]){(uint)$self.edges.len}}),
        $self.edges +++ (Edge[]){$edge}
    };
}

macro ComptimeAutomaton ct_repl_edge(ComptimeAutomaton $self, uint $i, Edge $edge)
{
    return
    {
        $self.begin,
        $self.end,
        $self.states,
        array::replace {Edge}($self.edges, $i, $edge)
    };
}

struct CtNewState
{
    uint state_id;
    ComptimeAutomaton automaton;
}

macro CtNewState ct_add_state(ComptimeAutomaton $self)
{
    return
    {
        $self.states.len,
        {
            $self.begin,
            $self.end,
            $self.states +++ (State[]){(State){(uint[]){}}},
            $self.edges
        }
    };
}



macro ComptimeAutomaton reduce(ComptimeAutomaton $self)
{
    bool[] $keep = array::zero {bool}($self.states.len);
    $keep = array::replace{bool}($keep, $self.begin, true);
    $keep = array::replace{bool}($keep, $self.end, true);

    // Follow the same state keeping rules as the runtime version
    $for uint $analyzing = 0; $analyzing < $self.states.len; $analyzing++:
        $foreach $edge_idx : $self.states[$analyzing].edges:
            Edge $edge = $self.edges[$edge_idx];
            $if $edge.next_state != $self.end:
                $if $edge.transition_type != EPSILON ||| $edge.open_cg != 0 ||| $edge.close_cg != 0:
                    $keep = array::replace{bool}($keep, $edge.next_state, true);
                $endif
                $if $edge.open_cg != 0 ||| $edge.close_cg != 0:
                    $keep = array::replace{bool}($keep, $analyzing, true);
                $endif
            $endif
        $endforeach
    $endfor


    uint[] $remap = array::zero {uint}($self.states.len);
    ComptimeAutomaton $result = {};

    $for uint $reducing = 0; $reducing < $self.states.len; $reducing++:
        $if $reducing == $self.end:
            CtNewState $add = ct_add_state($result);
            $result = $add.automaton;
            $remap = array::replace {uint}($remap, $reducing, $add.state_id);
            $result = $add.automaton;
        $else
            $if $keep[$reducing]:
                uint[] $state_stack = {$reducing};
                uint[] $edge_stack = {0};
                // usz $new_begin = $result.states.len;
                CtNewState $add = ct_add_state($result);
                $remap = array::replace {uint}($remap, $reducing, $add.state_id);
                $result = $add.automaton;
                

                $for var $i = 0; $state_stack.len > 0; $i++:
                    Pop { uint } $cur_state = array::pop {uint}($state_stack);
                    Pop { uint } $cur_edge = array::pop {uint}($edge_stack);
                    $edge_stack = $cur_edge.next;

                    $if $cur_edge.value + 1 < $self.states[$reducing].edges.len:
                        $edge_stack = array::push {uint}($edge_stack, $cur_edge.value + 1);
                    $else
                        $state_stack = $cur_state.next;
                    $endif

                    State $state = $self.states[$cur_state.value];
                    Edge $edge = $self.edges[$cur_edge.value];

                    $if $keep[$edge.next_state]:
                        $result = ct_add_edge($result, $add.state_id, $edge);
                    $else
                        $state_stack = array::push {uint}($state_stack, $edge.next_state);
                        $edge_stack = array::push {uint}($edge_stack, 0);
                    $endif
                $endfor
            $endif
        $endif
    $endfor

    // Now we do the remap
    // $foreach $i, $edge : $result.edges:
    $for var $i = 0; $i < $result.edges.len; $i++:
        var $edge = $result.edges[$i];
        $result = ct_repl_edge($result, $i,remap($edge, $remap[$edge.next_state]));
    $endfor

    return $result;
}

macro Char32[] to_string(parser::Node $node, SyntaxTree $tree)
{
    $switch $node.type:
        $case CHARACTER:
            Char32[] $str = {};
            $for var $i = 0; $i < $node.repeat_count; $i++:
                $str = $str +++ (Char32[]){$node.character};
            $endfor
            return $str;
        $case EXACTLY:
            Char32[] $substr = to_string($tree.nodes[$node.children[0]], $tree);
            $if $substr.len > 0:
                Char32[] $str = {};
                $for var $i = 0; $i < $node.repeat_count; $i++:
                    $str = $str +++ $substr;
                $endfor
                return $str;
            $else
                return {};
            $endif
        $case CONCAT:
            Char32[] $str = {};
            bool $broke = false;
            $foreach $n : $node.children:
                $if !$broke:
                    Char32[] $add_str = to_string($tree.nodes[$n], $tree);
                    $if $add_str.len == 0:
                        $broke = true;
                        return {};
                    $else
                        $str = $str +++ $add_str;
                    $endif
                $endif
            $endforeach
            $if !$broke:
                return $str;
            $endif
        $default:
            return {};
    $endswitch
}

struct NodeOrString
{
    bool is_string;
    Char32[] string;
    parser::Node node;
}

macro NodeOrString[] split_concat(parser::Node $node, SyntaxTree $tree)
{
    Char32[] $string_being_built = {};
    NodeOrString[] $result = {};
    $foreach $n : $node.children:
        Char32[] $child_string = to_string($tree.nodes[$n], $tree);
        $if $child_string.len > 0:
            $string_being_built = $string_being_built +++ $child_string;
        $else
            $if $string_being_built.len > 0:
                $result = $result +++ (NodeOrString[]){{.is_string = true, .string = $string_being_built},{.node = $tree.nodes[$n]}};
                $string_being_built = {};
            $else
                $result = $result +++ (NodeOrString[]){{.node = $tree.nodes[$n]}};
            $endif
        $endif
    $endforeach

    $if $string_being_built.len > 0:
        $result = $result +++ (NodeOrString[]){{.is_string = true, .string = $string_being_built}};
    $endif
    return $result;
}

struct LoweringContext
{
    uint[] automaton_state_ids;
    ComptimeAutomaton[] automata;
}

macro LoweringContext add_edge(LoweringContext $self, ushort $automaton_id, uint $state, Edge $edge)
{
    return
    {
        $self.automaton_state_ids,
        array::replace {ComptimeAutomaton}($self.automata, $automaton_id, ct_add_edge($self.automata[$automaton_id], $state, $edge))
    };
}

struct NewState
{
    uint state_id;
    LoweringContext context;
}

macro NewState add_state(LoweringContext $self, ushort $automaton_id)
{
    CtNewState $ct_ns = ct_add_state($self.automata[$automaton_id]);
    return
    {
        $ct_ns.state_id,
        {
            $self.automaton_state_ids,
            array::replace {ComptimeAutomaton}($self.automata, $automaton_id, $ct_ns.automaton)
        }
    };
}

struct NewAutomata
{
    ushort id;
    LoweringContext context;
}

macro NewAutomata add_automata(LoweringContext $self, uint $root_node_id, SyntaxTree $tree)
{
    $assert $self.automaton_state_ids.len < 65535 : "Regex is too complex!";

    bool $found = false;
    $foreach $i, $id : $self.automaton_state_ids:
        $if $id == $root_node_id:
            $found = true;
            return
            {
                (ushort)$i,
                $self
            };
        $endif
    $endforeach
    
    $if !$found:
        ushort $id = $self.automaton_state_ids.len;
        $self = {
            $self.automaton_state_ids +++ (uint[]){$root_node_id},
            $self.automata +++ (ComptimeAutomaton[]){{}}
        };

        LoweredState $result = lower_node($self, $id, $tree.nodes[$root_node_id], $tree);
        return
        {
            $id,
            {
                $result.context.automaton_state_ids,
                array::replace {ComptimeAutomaton} ($result.context.automata, $id, ct_begin_end($result.context.automata[$id], $result.begin, $result.end))
            }
        };
    $endif
}

struct LoweredState
{
    uint begin;
    uint end;
    LoweringContext context;
}

macro LoweredState lower_node(LoweringContext $self, ushort $automaton_id, parser::Node $node, SyntaxTree $tree)
{
    NewState $begin = add_state($self, $automaton_id);
    NewState $end = add_state($begin.context, $automaton_id);
    $self = $end.context;
    Char32[] $str_attempt = to_string($node, $tree);
    $if $str_attempt.len > 0:
        $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = STRING, .next_state = $end.state_id, .string = $str_attempt});
    $else
        $switch $node.type:
            $case WILDCARD:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = WILDCARD, .next_state = $end.state_id, .repeat_count = $node.repeat_count});
            $case BACKREF:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = BACK_REFERENCE, .next_state = $end.state_id, .repeat_count = $node.repeat_count, .backref_id = $node.group_id});
            $case CONCAT:
                NodeOrString[] $split = split_concat($node, $tree);
                NewState $previous = $begin;
                $for var $i = 0; $i < $split.len; $i++:
                    var $node_or_string = $split[$i];
                    $if $node_or_string.is_string:
                        $if $i == $split.len - 1:
                            $self = add_edge($ns.context, $automaton_id, $previous.state_id, {.transition_type = STRING, .next_state = $end.state_id, .string = $node_or_string.string});
                        $else
                            NewState $ns = add_state($self, $automaton_id);
                            $self = add_edge($ns.context, $automaton_id, $previous.state_id, {.transition_type = STRING, .next_state = $ns.state_id, .string = $node_or_string.string});
                            $previous = $ns;
                        $endif
                    $else
                        LoweredState $next = lower_node($self, $automaton_id, $node_or_string.node, $tree);
                        $self = add_edge($next.context, $automaton_id, $previous.state_id, {.transition_type = EPSILON, .next_state = $next.begin});
                        $if $i == $split.len - 1:
                            $end = {$next.end,{}};
                        $else
                            $previous = {$next.end,{}};
                        $endif
                    $endif
                $endfor
            $case DISJUNCT:
                $foreach $i : $node.children:
                    LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$i], $tree);
                    $self = add_edge(
                        add_edge($child.context,$automaton_id,$begin.state_id, 
                            {.transition_type = EPSILON, .next_state = $child.begin}
                        ),
                        $automaton_id,$child.end, 
                        {.transition_type = EPSILON, .next_state = $end.state_id}
                    );
                $endforeach
            $case NEGATIVE_CG:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = NEG_CHARACTER, .next_state = $end.state_id, .repeat_count = $node.repeat_count, .character_class = $node.class});
            $case POSITIVE_CG:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = POS_CHARACTER, .next_state = $end.state_id, .repeat_count = $node.repeat_count, .character_class = $node.class});
            $case START_ANCHOR:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = START, .next_state = $end.state_id});
            $case END_ANCHOR:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = END, .next_state = $end.state_id});
            $case WORD_ANCHOR:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = WORD_BOUNDARY, .next_state = $end.state_id});
            $case NOT_WORD_ANCHOR:
                $self = add_edge($self, $automaton_id, $begin.state_id, {.transition_type = NOT_WORD_BOUNDARY, .next_state = $end.state_id});
            $case ONE_OR_MORE:
                LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                $self = add_edge(
                    add_edge(
                        add_edge(
                            $child.context,
                            $automaton_id,
                            $begin.state_id,
                            {
                                .transition_type = EPSILON,
                                .next_state = $child.begin
                            }
                        ),
                        $automaton_id,
                        $child.end,
                        {
                            .transition_type = EPSILION,
                            .next_state = $begin.state_id
                        }
                    ),
                    $automaton_id,
                    $child.end,
                    {
                        .transition_type = EPSILON,
                        .next_state = $end.state_id
                    }
                );
            $case ZERO_OR_MORE:
                LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                $self = add_edge(
                    add_edge(
                        add_edge(
                            add_edge(
                                $child.context,
                                $automaton_id,
                                $begin.state_id,
                                {
                                    .transition_type = EPSILON,
                                    .next_state = $child.begin
                                }
                            ),
                            $automaton_id,
                            $begin.state_id,
                            {
                                .transition_type = EPSILON,
                                .next_state = $end.state_id
                            }
                        ),
                        $automaton_id,
                        $child.end,
                        {
                            .transition_type = EPSILON,
                            .next_state = $begin.state_id
                        }
                    ),
                    $automaton_id,
                    $child.end,
                    {
                        .transition_type = EPSILON,
                        .next_state = $end.state_id
                    }
                );
            $case ZERO_OR_ONE:
                LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                $self = add_edge(
                    add_edge(
                        add_edge(
                            $child.context,
                            $automaton_id,
                            $begin.state_id,
                            {
                                .transition_type = EPSILON,
                                .next_state = $child.begin
                            }
                        ),
                        $automaton_id,
                        $begin.state_id,
                        {
                            .transition_type = EPSILON,
                            .next_state = $end.state_id
                        }
                    ),
                    $automaton_id,
                    $child.end,
                    {
                        .transition_type = EPSILON,
                        .next_state = $end.state_id
                    }
                );
            $case EXACTLY:
                uint $previous = $begin.state_id;
                $for var $i = 0; $i < $node.repeat_count; $i++:
                    LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                    $self = add_edge($child.context, $automaton_id, $previous, {.transition_type = EPSILON, .next_state = $child.begin});
                    $previous = $child.end;
                $endfor
                $end = {$previous,{}};
            $case AT_MOST:
                uint $previous = $begin.state_id;
                $for var $i = 0; $i < $node.repeat_count; $i++:
                    LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                    $self = add_edge(
                        add_edge($child.context, $automaton_id, $previous, {.transition_type = EPSILON, .next_state = $child.begin}),
                        $automaton_id,
                        $previous,
                        {.transition_type = EPSILON, .next_state = $end.state_id}
                    );
                    $previous = $child.end;
                $endfor
                $self = add_edge($self, $automaton_id, $previous, {.transition_type = EPSILON, .next_state = $end.state_id});
            $case CAPTURE_GROUP:
                LoweredState $child = lower_node($self, $automaton_id, $tree.nodes[$node.children[0]], $tree);
                $self = add_edge(
                    add_edge(
                        $child.context,
                        $automaton_id,
                        $begin.state_id,
                        {
                            .transition_type = EPSILON,
                            .next_state = $child.begin,
                            .open_cg = $node.group_id
                        }
                    ),
                    $automaton_id,
                    $child.end,
                    {
                        .transition_type = EPSILON,
                        .next_state = $end.state_id,
                        .close_cg = $node.group_id
                    }
                );
            $case POSITIVE_LOOKAHEAD:
                NewAutomata $na = add_automata($self, $node.children[0], $tree);
                $self = add_edge($na.context, $automaton_id, $begin.state_id, {.transition_type = POS_LOOKAHEAD, .next_state = $end.state_id, .subautomaton_id = $na.id});
            $case NEGATIVE_LOOKAHEAD:
                NewAutomata $na = add_automata($self, $node.children[0], $tree);
                $self = add_edge($na.context, $automaton_id, $begin.state_id, {.transition_type = NEG_LOOKAHEAD, .next_state = $end.state_id, .subautomaton_id = $na.id});
        $endswitch
    $endif
    return
    {
        $begin.state_id,
        $end.state_id,
        $self
    };
}

struct ComptimeAutomataSet
{
    ComptimeAutomaton[] automata;
    ushort max_capture_group_id;
}

macro ComptimeAutomataSet lower_regex(String $regex_str, Options $options = NONE)
{
    SyntaxTree $tree = parser::parse($regex_str, $options);
    NewAutomata $na = add_automata({}, $tree.root, $tree);
    ComptimeAutomaton[] $result = $na.context.automata;
    $if $options & Options.NO_REDUCTION == 0:
        $for var $i = 0; $i < $result.len; $i++:
            var $automaton = $result[$i];
            $result = array::replace {ComptimeAutomaton}($result, $i, reduce($automaton));
        $endfor
    $endif;
    ushort $max_capture_group_id;
    $for var $i = 0; $i < $result.len; $i++:
        var $automaton = $result[$i];
        $for var $j = 0; $j < $result.len; $j++:
            var $edge = $automaton.edges[$j];
            $if $edge.open_cg > $max_capture_group_id:
                $max_capture_group_id = $edge.open_cg;
            $endif
        $endfor
    $endfor
    
    return
    {
        $result,
        $max_capture_group_id
    };
}

fn void fake_lower()
{
    lower_regex(`^.{8,15}$`,NONE);
}