Exercise.transaction do
  Exercise.delete_all

  Exercise.create! path: '1.1.1',
    title: 'How to output numbers',
    color: 'yellow',
    yaml: <<END
assignment: |
  Click Power to start the Ruby machine.
  Click Step three times to run the program.
code: |
  puts 1
  puts 2
  puts 3
cases:
- expected_output: "1\\n2\\n3"
features: run instructions console
END

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
features: run instructions console
END

  Exercise.create! path: '1.1.6',
    title: 'Output what the test case expects',
    color: 'blue',
    yaml: <<END
assignment: |
  Note the expected output under Run Test Case.
  Write a program to output what's expected.
  Click Run Test Case to grade it.
solution: |
  puts 5
  puts 5
  puts 9
cases:
- expected_output: "5\\n5\\n9\\n"
features: run instructions console
END

  Exercise.all.each do |exercise|
    exercise.yaml_loaded # make sure each exercise's yaml is valid
  end
end
