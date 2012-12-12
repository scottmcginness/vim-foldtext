if has('multi_byte')
    let defaults = {'placeholder': '⟨⋯ ⟩', 'line': '▤ ', 'whole': '⭕ ',
\       'level': '⧚', 'division': '∕', 'multiplication': '×',
\       'epsilon': 'ε'}
else
    let defaults = {'placeholder': '<...>', 'line': 'L', 'whole': 'W',
\       'level': 'Z', 'division': '/', 'multiplication': '*',
\       'epsilon': '0'}
endif
let defaults['denominator'] = 25
let defaults['gap'] = 4

if !exists('g:FoldText_placeholder')
    let g:FoldText_placeholder = defaults['placeholder']
endif
if !exists('g:FoldText_line')
    let g:FoldText_line = defaults['line']
endif
if !exists('g:FoldText_whole')
    let g:FoldText_whole = defaults['whole']
endif
if !exists('g:FoldText_level')
    let g:FoldText_level = defaults['level']
endif
if !exists('g:FoldText_division')
    let g:FoldText_division = defaults['division']
endif
if !exists('g:FoldText_multiplication')
    let g:FoldText_multiplication = defaults['multiplication']
endif
if !exists('g:FoldText_epsilon')
    let g:FoldText_epsilon = defaults['epsilon']
endif
if !exists('g:FoldText_denominator')
    let g:FoldText_denominator = defaults['denominator']
endif
if g:FoldText_denominator >= &maxfuncdepth
    let g:FoldText_denominator = &maxfuncdepth - 1
endif
if !exists('g:FoldText_gap')
    let g:FoldText_gap = defaults['gap']
endif

unlet defaults


function! s:FractionsBetween(lo, hi, denominator)
    " Find all fractions between [a, b] and [c, d] with denominator equal
    " to `a:denominator'
    let lo = a:lo[0] / a:lo[1]
    let hi = a:hi[0] / a:hi[1]
    let fractions = []
	let n = 1.0
	while n < a:denominator
        let p = n / a:denominator
        if p > lo && p < hi
            call add(fractions, [n, a:denominator])
        endif
	   let n += 1
	endwhile
    return fractions
endfunction

function! s:FractionSearch(proportion, denominator)
    " Search for the nearest fraction, used by s:FractionNearest().
    if a:denominator == 1
        return [[0.0, 1], [1.0, 1]]
    endif

    let [lo, hi] = s:FractionSearch(a:proportion, a:denominator - 1)
    let fractionsBetween = s:FractionsBetween(lo, hi, a:denominator)
    for fraction in fractionsBetween
        let f = fraction[0] / fraction[1]
        if a:proportion >= f
            let lo = fraction
        else
            let hi = fraction
            break
        endif
    endfor
    return [lo, hi]
endfunction

function! s:FractionNearest(proportion, maxDenominator)
    " Find the neareset fraction to `a:proportion' (which is a float),
    " but using fractions with denominator less than `a:maxDenominator'.
    let [lo, hi] = s:FractionSearch(a:proportion, a:maxDenominator)
    let mid = (lo[0] / lo[1] + hi[0] / hi[1]) / 2
    if a:proportion > mid
        return hi
    else
        return lo
    endif
endfunction

function! s:FractionFormat(fraction)
    " Format a fraction: [a, b] --> 'a/b'
    let [n, d] = a:fraction
    if n == 0.0
        return g:FoldText_epsilon
    endif
    if d != 1
        return printf("%.0f%s%d", n, g:FoldText_division, d)
    endif
    return printf("%.0f", n)
endfunction

function! FoldText()
    " Returns a line representing the folded text
    "
    " A fold across the following:
    "
    " fu! MyFunc()
    "    call Foo()
    "    echo Bar()
    " endfu
    "
    " should, in general, produce something like:
    "
    " fu! MyFunc() <...> endfu                    L*15 O*2/5 Z*2
    "
    " The folded line has the following components:
    "
    "   - <...>           the folded text, but squashed;
    "   - endfu           the last line (where applicable);
    "   - L*15            the number of lines folded (including first);
    "   - O*2/5           the fraction of the whole file folded;
    "   - Z*2             the fold level of the fold.
    "
    " You may also define any of the following strings:
    "
    " let g:FoldText_placeholder = '<...>'
    " let g:FoldText_line = 'L'
    " let g:FoldText_level = 'Z'
    " let g:FoldText_whole = 'O'
    " let g:FoldText_division = '/'
    " let g:FoldText_multiplication = '*'
    " let g:FoldText_epsilon = '0'
    " let g:FoldText_denominator = 25
    "
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$'
        let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let spaces = repeat(' ', &tabstop)
        let line = substitute(getline(fs), '\t', spaces, 'g')
    endif
 
    let foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    let endBlockChars = ['end', '}', ']', ')']
    let endBlockRegex = printf('^\s*\(%s\);\?$', join(endBlockChars, '\|'))
    let endCommentRegex = '\s*\*/$'
    let startCommentBlankRegex = '\v^\s*/\*!?\s*$'

    if foldEnding =~ endBlockRegex
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    elseif foldEnding =~ endCommentRegex
        if getline(v:foldstart) =~ startCommentBlankRegex
            let nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            let line = line . nextLine
        endif
        let foldEnding = " " . g:FoldText_placeholder . " " . foldEnding
    else
        let foldEnding = " " . g:FoldText_placeholder
    endif
    let foldColumnWidth = &foldcolumn ? 1 : 0
    let numberColumnWidth = &number ? strwidth(line('$')) : 0
    let width = winwidth(0) - foldColumnWidth - numberColumnWidth - g:FoldText_gap

    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = printf("%s%s%s", g:FoldText_line, g:FoldText_multiplication, foldSize)

    let foldLevelStr = g:FoldText_level . g:FoldText_multiplication . v:foldlevel . " "

    let proportion = (foldSize * 1.0) / line("$")
    let foldFraction = s:FractionNearest(proportion, g:FoldText_denominator)
    let foldFractionStr = printf(" %s%s%s ", g:FoldText_whole, g:FoldText_multiplication, s:FractionFormat(foldFraction))
    let ending = foldSizeStr . foldFractionStr . foldLevelStr

    if strwidth(line . foldEnding . ending) >= width
        let line = strpart(line, 0, width - strwidth(foldEnding . ending))
    endif

    let expansionStr = repeat(" ", g:FoldText_gap + width - strwidth(line . foldEnding . ending))
    return line . foldEnding . expansionStr . ending
endfunction

set foldtext=FoldText()
