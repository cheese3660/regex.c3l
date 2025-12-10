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
const bool NO_REDUCTION @private = (REGEX_OPTIONS & Options.NO_REDUCTION) != 0;


<*
    Define a compiled regex as a char because it doesn't exactly matter
*>
typedef CompiledRegex = char;



<*
    Try and get a match starting at the current offset in the view

    @param [&in] self
    @param view: "The string view being matched over"
    @param offset: "The offset in the view to match at"
    @param [&in] match_allocator: "The allocator being used to allocate the array of captures"

    @require offset < view.len

    @return? regex::NO_MATCH : "If there is no match starting at the offset"
    @return "A match starting at the offset"
*>
fn Match? CompiledRegex.match_in_view(&self, String view, usz offset, Allocator match_allocator) @dynamic 
{
    return match_common(view, offset, match_allocator: match_allocator);
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
fn bool matches_at(String view, uint offset=0, ushort sub_automaton_index = 0, CaptureEntry* capture_base=null, bool require_full=false)
{
    if (try match_common(view, offset, sub_automaton_index, capture_base, require_full))
    {
        return true;
    }
    else
    {
        return false;
    }
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




<*
    Common code for matching, the parameters are basically the same as the parameters for the above functions, but this can take a null allocator in which case it just returns NO_MATCH or {}
*>
fn Match? match_common(String view, uint offset=0, ushort sub_automaton_index = 0, CaptureEntry* capture_base, bool require_full=false, Allocator match_allocator=null) @private
{
    switch (sub_automaton_index)
    {
        // Here is where we loop over every sub_automaton to generate their code
        default:
            unreachable();
    }
    return regex::NO_MATCH?;
}