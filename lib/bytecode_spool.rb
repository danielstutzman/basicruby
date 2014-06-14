class BytecodeSpool
  def initialize bytecodes
    @bytecodes = bytecodes + [[:done]]
    @counter = 0
    @label_to_counter = label_to_counter(bytecodes)
    @breakpoint = 'NEXT_POSITION'
    @num_steps_queued = 0
    @is_done = false
    @counter_stack = []
  end

  def visible_state
    { breakpoint: @breakpoint,
      num_steps_queued: @num_steps_queued,
      is_done: @is_done }
  end

  def is_done?
    @is_done
  end

  def queue_run_until breakpoint
    if @breakpoint == breakpoint
      @num_steps_queued += 1
    else
      @breakpoint = breakpoint
      @num_steps_queued = 1
    end
  end

  def get_next_bytecode
    if @is_done
      nil
    elsif @counter >= @bytecodes.size
      nil
    elsif @num_steps_queued == 0
      nil
    else
      bytecode = @bytecodes[@counter]
      case bytecode[0]
        when :position
          @num_steps_queued -= 1 if @breakpoint == 'NEXT_POSITION'
        when :done
          @num_steps_queued = 0
          @is_done = true
      end
      @counter += 1 # ok to step past label
      bytecode
    end
  end

  def goto label
    @counter = @label_to_counter[label] or raise "Can't find label #{label}"
  end

  def rescue label, stack_size
    while @counter_stack.size > stack_size
      @counter_stack.pop
    end
    @counter = @label_to_counter[label] or raise "Can't find label #{label}"
  end

  def gosub label
    @counter_stack.push @counter
    @counter = @label_to_counter[label] or raise "Can't find label #{label}"
  end

  def return_
    @counter = @counter_stack.pop
  end

  def terminate_early
    @is_done = true       # so it's not possible to continue
    @num_steps_queued = 0 # so buttons aren't glowing
  end

  private

  def label_to_counter bytecodes
    hash = {}
    bytecodes.each_with_index do |bytecode, counter|
      if bytecode[0] == :label
        label_name = bytecode[1]
        hash[label_name] = counter
      end
    end
    hash
  end
end
