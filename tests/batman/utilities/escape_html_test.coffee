QUnit.module "Batman.escapeHTML helper"

test "should escape unsafe characters", ->
  equal Batman.escapeHTML('<>&"\''), '&lt;&gt;&amp;&#34;&#39;'
