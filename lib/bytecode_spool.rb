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

  def get_next_bytecode is_result_truthy, gosubbing_label, gotoing_label,
      stack_size
    if @is_done
      nil
    elsif @counter >= @bytecodes.size
      nil
    elsif @num_steps_queued == 0
      nil
    elsif gosubbing_label
      @counter_stack.push @counter
      @counter = @label_to_counter[gosubbing_label] or raise \
        "Can't find label #{gosubbing_label}"
      bytecode = @bytecodes[@counter]
      @counter += 1 # ok to step once past label
      bytecode
    elsif gotoing_label
      @counter = @label_to_counter[gotoing_label] or raise \
        "Can't find label #{gotoing_label}"
      bytecode = @bytecodes[@counter]
      @counter += 1 # ok to step once past label
      bytecode
    else
      bytecode = @bytecodes[@counter]
      case bytecode[0]
        when :position
          @num_steps_queued -= 1 if @breakpoint == 'NEXT_POSITION'
        when :done
          @num_steps_queued = 0
          @is_done = true
        when :goto
          @counter = @label_to_counter[bytecode[1]] or raise \
            "Can't find label #{bytecode[1]}"
        when :goto_if_not
          if !is_result_truthy
            @counter = @label_to_counter[bytecode[1]] or raise \
              "Can't find label #{bytecode[1]}"
          end
        when :return
          while @counter_stack.size > stack_size
            @counter_stack.pop
          end
          @counter = @counter_stack.pop - 1
      end
      @counter += 1 # ok to step past label
      bytecode
    end
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
