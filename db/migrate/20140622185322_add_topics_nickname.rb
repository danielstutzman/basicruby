class AddTopicsNickname < ActiveRecord::Migration
  def up
    # can't start null: false with default: null, so start with default: ''
    add_column :topics, :nickname, :string, null: false, default: ''
    change_column_default :topics, :nickname, nil
    execute "update topics set nickname = case
      when title = 'Output numbers and blank lines' then 'puts'
      when title = 'Multiple outputs sharing a line' then 'print'
      when title = 'Variables' then 'vars'
      when title = 'Accepting input' then 'gets'
      when title = 'Multiple inputs' then 'gets2'
      when title = 'Copying variables' then 'copy_vars'
      when title = 'String literals vs. variables' then 'str_literals'
      when title = 'Arithmetic with input' then 'int_gets'
      when title = 'Spaces and strings' then 'spaces'
      when title = 'Array aliasing' then 'alias_array'
      when title = '`Array#map`' then 'array_map'
      when title = 'Functional programming' then 'functional'
      when title = 'Lambda and `->`' then 'lambda'
      when title = 'Demo of advanced debugger features' then 'advanced'
    end"
    add_index :topics, :nickname, unique: true

    # so that we can preserve exercise ids
    add_index :exercises, [:topic_id, :color, :rep_num], unique: true
  end
  def down
    remove_index :topics, :nickname
    remove_column :topics, :nickname
    remove_index :exercises, [:topic_id, :color, :rep_num]
  end
end
