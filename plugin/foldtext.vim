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
    let foldEnding = " ⟨⋯ ⟩ " . foldEnding
    let width = winwidth(0) - &foldcolumn - (&number ? 8 : 0)
    let foldSize = 1 + v:foldend - v:foldstart
    let foldSizeStr = " " . foldSize . " lines "
    let foldLevelStr = repeat("+--", v:foldlevel)
    let lineCount = line("$")
    let percentage = (foldSize * 1.0) / lineCount * 100  
    let percentageStr = printf("[%.1f%%] ", percentage)

    let ending = foldSizeStr . percentageStr . foldLevelStr
    let expansionString = repeat(" ", width - strwidth(line . foldEnding. ending))
    return line . foldEnding . expansionString . ending
endfunction
