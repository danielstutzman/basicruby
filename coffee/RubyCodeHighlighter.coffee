Lexer                 = require './Lexer.coffee'

class RubyCodeHighlighter

  constructor: (code) ->
    @code = code
    @currentLine = null
    @currentCol = null
    @highlightedRange = null
    @highlightedLineNum = null
    @startPosToEndPos = Lexer.build_start_pos_to_end_pos code
    @justChangedPosition = false

  visibleState: ->
    code:               @code
    currentLine:        @currentLine
    currentCol:         @currentCol
    highlightedRange:   @highlightedRange
    highlightedLineNum: @highlightedLineNum

  interpret: (bytecode) ->
    @highlightedRange = null
    @highlightedLineNum = null

    switch bytecode[0]

      when 'token'
        startLine = bytecode[1]
        startCol  = bytecode[2]
        startPos  = "#{bytecode[1]},#{bytecode[2]}"
        endPos    = @startPosToEndPos.map[startPos]
        if endPos
          endLine = endPos['$[]'](0)
          endCol  = endPos['$[]'](1)
        else
          endLine = startLine
          endCol = startCol + 1
        @highlightedRange = [startLine, startCol, endLine, endCol]
        if @justChangedPosition
          @highlightedLineNum = startLine
          @justChangedPosition = false
  
      when 'position'
        @currentLine = parseInt bytecode[1]
        @currentCol = parseInt bytecode[2]
        @justChangedPosition = true

      when 'done'
        @currentLine = null
        @currentCol = null

module.exports = RubyCodeHighlighter
