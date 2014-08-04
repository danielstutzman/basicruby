RubyCodeHighlighter = require './RubyCodeHighlighter.coffee'

describe 'RubyCodeHighlighter', ->
  it 'starts out uninitialized', =>
    code = 'puts 1'
    highlightTokens = false
    highlighter = new RubyCodeHighlighter(code, highlightTokens)
    expect(highlighter.visibleState()).toEqual
      code:             'puts 1'
      currentLine:      null
      currentCol:       null
      highlightedRange: null
