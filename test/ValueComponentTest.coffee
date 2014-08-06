ValueComponent = require '../coffee-istanbul/ValueComponent.js'
helper         = require '../test/helper.coffee'

describe 'ValueComponent', ->
  it 'renders integers', (done) ->
    props = { value: 3, object_ids: [], show_type: false }
    helper.assertRendersHtml ValueComponent(props), done, """
      <div class="value ">
        <span>3</span>
      </div>
    """
