<*
    This module implements a compiled regular expression using code generation techniques in C3

    @require REGEX_STR.typeid == String : "Only strings can be compiled into regexen"
    @require REGEX_STR.len > 0 : "Empty regexen cannot be compiled"
    @require REGEX_OPTIONS.typeid == Options : "The options to a compiled regular expression must be regex options"
*>
module regex::compiled::compiled_regex { REGEX_STR, REGEX_OPTIONS };


import regex;

const bool MULTILINE @private = (REGEX_OPTIONS & Options.MULTILINE) != 0;
const bool SINGLE_LINE @private = (REGEX_OPTIONS & Options.SINGLE_LINE) != 0;
const bool IGNORE_CASE @private =(REGEX_OPTIONS & Options.IGNORE_CASE) != 0;
const bool ASCII_ONLY @private = (REGEX_OPTIONS & Options.ASCII_ONLY) != 0;

<*
    Define a compiled regex as a char because it doesn't exactly matter
*>
typedef CompiledRegex = char;

<*
    Try and get a match starting at the current offset in the view

    @param [&in] self
    @param view: "The string view being matched over"
    @param offset: "The offset in the view to match at"
    @param match_allocator: "The allocator being used to allocate the array of captures"

    @require offset < view.len

    @return? regex::NO_MATCH : "If there is no match starting at the offset"
    @return "A match starting at the offset"
*>
fn Match? CompiledRegex.match_in_view(&self, String view, usz offset, Allocator match_allocator) @dynamic 
{
    unreachable();
}

<*
    Check if the given subautomaton matches at the index
    
    @param view                 : "The string view being matched over"
    @param offset               : "The offset in the view to match at"
    @param sub_automaton_index  : "The subautomaton to check"
    @param capture_base         : "The parent capture group array, if there is one"
    @param require_full         : "Does this require a full match?"

    @require offset <= view.len : "Offset is out of bounds of the string"
    @require sub_automaton_index < self.automaton_count : "Invalid subautomaton index"
    @require capture_base == null || capture_base.ref_count > 0 : "The capture group array is deallocated"

    @return "If the sub-automaton matches at the given offset"
*>
fn bool matches_at(String view, uint offset=0, ushort sub_automaton_index = 0, CaptureEntry* capture_base, bool require_full=false)
{
    unreachable();
}

<*
    Check if the regex matches the entirety of the given string

    @param [&in] self
    @param view : "The string to match"

    @return "Does the regex match the entire string"
*>
fn bool CompiledRegex.matches(&self, String view) @dynamic
{
    return matches_at(view, require_full: true);
}


