prettyPrint = require('html').prettyPrint
React       = require 'react'

assertRendersHtml = (reactComponent, done, expectedHtml) ->
  if typeof(document) == 'undefined'
    React.renderComponentToString reactComponent, (html) ->
      html = html.replace /data-reactid="(.*?)"/g, ''
      html = html.replace /data-react-checksum="(.*?)"/g, ''
      html = prettyPrint html, indent_size: 2, unformatted: []
      expect(html).toEqual expectedHtml
      done()
  else
    div = document.createElement('div')
    body = window.document.getElementsByTagName('body')[0]
    body.appendChild(div)
    React.renderComponent reactComponent, div
    html = div.innerHTML
    html = html.replace /data-reactid="(.*?)"/g, ''
    html = html.replace /data-react-checksum="(.*?)"/g, ''
    html = prettyPrint html, indent_size: 2, unformatted: []
    expect(html).toEqual expectedHtml
    div.parentNode.removeChild div
    done()

click = (node) ->
  if node.fireEvent # if IE8
    if node.nodeName == 'INPUT' && node.type == 'checkbox'
      node.checked = not node.checked
    e = document.createEventObject()
    node.fireEvent 'onclick', e
  else
    e = document.createEvent 'MouseEvent'
    e.initMouseEvent('click', true, true,
      window, null, 0, 0, 0, 0, false, false, false, false, 0, null)
    node.dispatchEvent e
    # Doesn't work with PhantomJS:
    #   node.dispatchEvent(new MouseEvent('click', { bubbles: true }))

module.exports = { assertRendersHtml, click }
