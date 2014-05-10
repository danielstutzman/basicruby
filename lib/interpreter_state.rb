class InterpreterState
  attr_accessor :result, :vars

  def initialize
    @partial_calls = []
    @result = [] # a stack with 0 or 1 items in it
    @vars = {}
    @main = (RUBY_PLATFORM == 'opal') ?
      `Opal.top` : TOPLEVEL_BINDING.eval('self')
  end

  def partial_calls
    # clone so it's an independent copy that won't get accidentally updated
    @partial_calls.map { |call| call.clone }
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

  def to_var var_name
    value = pop_result
    @vars[var_name] = value
    @result.push value
  end

  def from_var var_name
    @result.push @vars[var_name]
  end

  ## Below are non-bytecode methods

  def result_is_true?
    !!pop_result
  end

  def result_from_call new_result
    self.result new_result
  end

  def top
    self.result @main
  end

  def pop_call
    @partial_calls.pop
  end

  private

  def pop_result
    raise "Empty result stack" if @result == []
    @result.pop
  end
end
