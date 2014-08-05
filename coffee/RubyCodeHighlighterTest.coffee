RubyCodeHighlighter = require './RubyCodeHighlighter.coffee'

describe 'RubyCodeHighlighter', ->

  describe 'highlightTokens = false', ->

    it "starts out uninitialized", ->
      highlighter = new RubyCodeHighlighter 'puts 1', false
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      null
        currentCol:       null
        highlightedRange: null

    it "updates the pointer when it sees position bytecodes", ->
      highlighter = new RubyCodeHighlighter 'puts 1', false
      highlighter.interpret ['position', 'YourCode', 1, 0]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      1
        currentCol:       0
        highlightedRange: null

    it "updates highlightedRange to highlight the whole line when it sees a token bytecode after a position bytecode", ->
      highlighter = new RubyCodeHighlighter 'puts 1', false
      highlighter.interpret ['position', 'YourCode', 1, 0]
      highlighter.interpret ['token', 1, 0]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      1
        currentCol:       0
        highlightedRange: [1, 0, 1, 6]

    it "doesn't update highlightedRange when it sees a token bytecode not after a position bytecode", ->
      highlighter = new RubyCodeHighlighter 'puts 1', false
      highlighter.interpret ['token', 1, 0]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      null
        currentCol:       null
        highlightedRange: null

  describe 'highlightTokens = true', ->

    it "starts out uninitialized", ->
      highlighter = new RubyCodeHighlighter 'puts 1', true
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      null
        currentCol:       null
        highlightedRange: null

    it "updates the pointer when it sees position bytecodes", ->
      highlighter = new RubyCodeHighlighter 'puts 1', true
      highlighter.interpret ['position', 'YourCode', 1, 0]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      1
        currentCol:       0
        highlightedRange: null

    it "updates highlightRange when it sees a token bytecode", ->
      highlighter = new RubyCodeHighlighter 'puts 1', true
      highlighter.interpret ['token', 1, 0]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      null
        currentCol:       null
        highlightedRange: [1, 0, 1, 4]
      highlighter.interpret ['token', 1, 4]
      expect(highlighter.visibleState()).toEqual
        code:             'puts 1'
        currentLine:      null
        currentCol:       null
        highlightedRange: [1, 4, 1, 5]
