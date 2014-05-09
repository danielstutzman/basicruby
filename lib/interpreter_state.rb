class InterpreterState
  #attr_accessor :counter, :output, :partial_calls, :result, :vars

  def initialize
    @partial_calls = []
    @result = [] # a stack with 0 or 1 items in it
    @ifs = [] # a stack with true or false items in it
    @vars = {}
  end

  ## Below are bytecode methods

  def start_call
    @partial_calls.push []
  end

  def result new_result
    @result.push new_result
    raise "Result stack has too many items" if @result.size > 1
  end

  def arg
    @partial_calls.last.push pop_result
  end

  def discard
    pop_result
  end

  def push_if
    @ifs.push pop_result
  end

  def pop_if
    raise "Ifs stack is empty" if @ifs.size == 0
    @ifs.pop
  end

  def to_var var_name
    value = pop_result
    @vars[var_name] = value
    @result.push value
  end

  def from_var var_name
    @result.push @vars[var_name]
  end

  ## Below are non-bytecode methods

  def pop_call
    @partial_calls.pop
  end

  def if_was_true?
    @ifs.last
  end

  private

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
