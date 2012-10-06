if !exists('g:foldPlaceholder')
    let g:foldPlaceholder = "⟨⋯ ⟩"
endif
if !exists('g:foldLineChar')
    let g:foldLineChar = '▤'
endif
if !exists('g:foldLevelChar')
    let g:foldLevelChar = '⧚'
endif
if !exists('g:foldWholeChar')
    let g:foldWholeChar = '⭕'
endif


function! CustomFoldText()
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
    let foldEnding = " " . g:foldPlaceholder . " " . foldEnding
    let width = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = g:foldLineChar . " ×" . foldSize
    let foldLevelStr = g:foldLevelChar . "×" . v:foldlevel . " "
    let lineCount = line("$")
    let proportion = (foldSize * 1.0) / lineCount
    if proportion < 1.0 / 16
        let proportionStr = '0'
    elseif proportion < 7.0 / 48
        let proportionStr = '1⁄8'
    elseif proportion < 11.0 / 60
        let proportionStr = '1⁄6'
    elseif proportion < 9.0 / 40
        let proportionStr = '1⁄5'
    elseif proportion < 7.0 / 24
        let proportionStr = '1⁄4'
    elseif proportion < 17.0 / 48
        let proportionStr = '1⁄3'
    elseif proportion < 31.0 / 80
        let proportionStr = '3⁄8'
    elseif proportion < 9.0 / 20
        let proportionStr = '2⁄5'
    elseif proportion < 11.0 / 20
        let proportionStr = '1⁄2'
    elseif proportion < 49.0 / 80
        let proportionStr = '3⁄5'
    elseif proportion < 31.0 / 48
        let proportionStr = '5⁄8'
    elseif proportion < 17.0 / 24
        let proportionStr = '2⁄3'
    elseif proportion < 31.0 / 40
        let proportionStr = '3⁄4'
    elseif proportion < 49.0 / 60
        let proportionStr = '4⁄5'
    elseif proportion < 41.0 / 48
        let proportionStr = '5⁄6'
    elseif proportion < 15.0 / 16
        let proportionStr = '7⁄8'
    else
        let proportionStr = '1'
    endif
    let proportionStr = printf(" " . g:foldWholeChar . " ×%s ", proportionStr)

    let ending = foldSizeStr . proportionStr . foldLevelStr
    let expansionString = repeat(" ", 4 + width - strwidth(line . foldEnding. ending))
    return line . foldEnding . expansionString . ending
endfunction
