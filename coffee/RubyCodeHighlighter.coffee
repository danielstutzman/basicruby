Lexer                 = require './Lexer.coffee'

class RubyCodeHighlighter

  constructor: (code) ->
    @code = code
    @currentLine = null
    @currentCol = null
    @highlightedRange = null
    @startPosToEndPos = Lexer.build_start_pos_to_end_pos code

  visibleState: ->
    code:             @code
    currentLine:      @currentLine
    currentCol:       @currentCol
    highlightedRange: @highlightedRange

  interpret: (bytecode) ->
    @highlightedRange = null

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
        600
  
      when 'position'
        newLine = parseInt bytecode[1]
        newCol = parseInt bytecode[2]
        millis = if newLine != @currentLine then 300 else null
        @currentLine = newLine
        @currentCol = newCol
        millis

      when 'done'
        @currentLine = null
        @currentCol = null
        null

      else
        null

module.exports = RubyCodeHighlighter
