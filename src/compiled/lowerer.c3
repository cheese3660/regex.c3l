<*
    This module contains macros for lowering regexen into a compile time structure

    We can modify our previous tree syntax to make recursion depth minimal in this step, only adding a new step really on `(` and `|`
*>
module regex::compiled::lowerer;
import regex::common::states;
import regex::compiled::array;
import regex::compiled::class;

struct Edge
{
    TransitionType transition_type;
    uint next_state;
    uint backref_id;
    uint repeat_count;
    ushort subautomaton_id;
    Char32[] string;
    ComptimeClass character_class;
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

macro ComptimeAutomaton add_edge(ComptimeAutomaton $self, uint $state, Edge $edge)
{
    return
    {
        $self.begin,
        $self.end,
        array::replace{State}($self.states, $state ,(State){array::push{uint}($self.states[$state],(uint)$self.edges.len())}),
        array::push{Edge}($self.edges, $edge)
    };
}