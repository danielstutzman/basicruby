Lexer                 = require './Lexer.coffee'

class RubyCodeHighlighter

  constructor: (code, highlightTokens) ->
    @code = code
    @currentLine = null
    @currentCol = null
    @highlightedRange = null
    @highlightTokens = highlightTokens
    @startPosToEndPos = Lexer.build_start_pos_to_end_pos code
    @lineStartPosToEndPos = Lexer.build_line_start_pos_to_end_pos code
    @justChangedPosition = false

  visibleState: ->
    code:               @code
    currentLine:        @currentLine
    currentCol:         @currentCol
    highlightedRange:   @highlightedRange

  interpret: (bytecode) ->
    @highlightedRange = null

    switch bytecode[0]

      when 'token'
        startLine = bytecode[1]
        startCol  = bytecode[2]
        if @highlightTokens
          startPos  = "#{bytecode[1]},#{bytecode[2]}"
          endPos    = @startPosToEndPos.map[startPos]
          if endPos
            endLine = endPos['$[]'](0)
            endCol  = endPos['$[]'](1)
          else
            endLine = startLine
            endCol = startCol + 1
          @highlightedRange = [startLine, startCol, endLine, endCol]
        else # highlight the entire line, not just individual tokens
          if @justChangedPosition
            @justChangedPosition = false
            startPos = "#{bytecode[1]},#{bytecode[2]}"
            endPos    = @lineStartPosToEndPos.map[startPos]
            if endPos
              endLine = endPos['$[]'](0)
              endCol  = endPos['$[]'](1)
            else
              endLine = startLine
              endCol = startCol + 1
            @highlightedRange = [startLine, startCol, endLine, endCol]
  
      when 'position'
        if bytecode[1] == 'YourCode'
          @currentLine = parseInt bytecode[2]
          @currentCol = parseInt bytecode[3]
          @justChangedPosition = true

      when 'done'
        @currentLine = null
        @currentCol = null

module.exports = RubyCodeHighlighter
