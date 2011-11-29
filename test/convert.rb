ARGV.each do |file_name|
  File.open(file_name, 'r+') do |file|
    contents = file.read
    contents.gsub!(/\s\ssetup: /, 'setup ')
    contents.gsub!(/\s\steardown: /, 'teardown ')
    contents.gsub!(/(\s|^)(not)?(equal|Equal|deepEqual|strictEqual|ok)(\s|\()/i, '\1assert.\2\3\4')
    contents.gsub!(/(\s|^)raises(\s|\()/, '\1assert.throws\2')
    contents.gsub!(/(\s|^)equals(\s|\()/, '\1assert.equal\2')

    contents.gsub!(/(QUnit\.module.+?)\n(.+?)(?=(?:QUnit\.module|\z))/m) do |lines|
      lines.split("\n").join("\n  ") << "\n\n"
    end

    contents.gsub!(/QUnit\.module (.+?),?\s*$/, 'suite \1, ->')
    contents.gsub!(/test (.+?)(?:\s?\d+,)?(\s*)->\s*$/, 'test \1\2 ->')
    contents.gsub!(/asyncTest (.+?)(?:\s?\d+,)?(\s*)->\s*$/, 'test \1\2(done) ->')
    contents.gsub!(/QUnit\.start/, "done")
    contents.gsub!(/^\s+$/, '')
    contents.gsub!(/delay (.+,\s?)?((?:\=|-)>)/, 'delay {\1done}, \2')
    file.rewind
    file.truncate(0)
    file.write(contents)
  end
end
