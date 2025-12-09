module regex::test_common;
import regex;

macro regex_expect($regex, $options, $on, ...)
{
    @pool()
    {
        RuntimeRegex? rr = regex::make_runtime_regex($regex, $options, tmem);
        if (catch rr) assert(false, "Regex " +++ $regex +++ " failed to be lowered");
        Regex r = &rr;

        MatchIterator iter = r.iter_matches($on);
        $for var $i = 0; $i < $vacount; $i++:
            if (try result = iter.next())
            {
                assert(result.matched() == $vaconst[$i], "Regex " +++ $regex +++ " failed to match " +++ $vaconst[$i]);
            }
            else
            {
                assert(false, "Regex " +++ $regex +++ " did not have match " +++ $vaconst[$i] +++ " at index " +++ ($i + 1) +++ " it instead stopped matching" );
            }
        $endfor;

        if (try last = iter.next()) assert(false, "Regex " +++ $regex +++ " had too many matches");
    };
}

macro regex_expect_match_full($regex, $options, ...)
{
    @pool()
    {
        RuntimeRegex? rr = regex::make_runtime_regex($regex, $options, tmem);
        if (catch rr) assert(false, "Regex " +++ $regex +++ " failed to be lowered");
        Regex r = &rr;

        $for var $i = 0; $i < $vacount; $i++:
            assert(r.matches($vaconst[$i]), "Regex " +++ $regex +++ " did not match " +++ $vaconst[$i]);
        $endfor;
    };
}

macro regex_expect_capture_groups($regex, $options, $on, ...)
{
    @pool()
    {
        RuntimeRegex? rr = regex::make_runtime_regex($regex, $options, tmem);
        if (catch rr) assert(false, "Regex " +++ $regex +++ " failed to be lowered");
        Regex r = &rr;
        MatchIterator iter = r.iter_matches($on);
        Match? first_match = iter.next();
        if (catch first_match) assert(false, "Regex " +++ $regex +++ " failed to match " +++ $on);
        assert(first_match.begin_offset() == 0 && first_match.end_offset() == $on.len, "Regex " +++ $regex +++ " did not fully match " +++ $on);
        assert(first_match.len() == $vacount + 1,  "Regex " +++ $regex +++ " did not have the expected number of capture groups");
        
        $for var $i = 0; $i < vacount; $i++:
            assert(first_match[$i+1].captured == $vaconst[$i], "Regex " +++ $regex +++ " did not have the expected capture group of " +++ $vaconst[i]);
        $endfor
    };
}