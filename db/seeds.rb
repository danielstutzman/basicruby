Exercise.transaction do
  Exercise.delete_all

  Exercise.create! path: '1.1.1',
    title: 'How to output numbers',
    color: 'gold',
    yaml: <<END
assignment: |
  Click Power to start the Ruby machine.
  Click Step three times to run the program.
code: |
  puts 1
  puts 2
  puts 3
features: step instructions console
END
#cases:
#- input: "5\\n1"
#  expected_output: 25
#- input: "5\\n1"
#  expected_output: 16

  Exercise.create! path: '1.1.2',
    title: 'Fix the `NoMethodError`',
    color: 'red',
    yaml: <<END
assignment: |
  This program raises an error on line 2 because of a typo.
  Run the broken program.
  Then read the error message out loud.
code: |
  puts 1
  pust 2
  puts 3
features: step instructions console
END

  Exercise.all.each do |exercise|
    exercise.yaml_loaded # make sure each exercise's yaml is valid
  end
end
