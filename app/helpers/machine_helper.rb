module MachineHelper
  def power_button
    "<button class='power'>&#x233d; Power</button>".html_safe
  end
  def step_button
    "<button class='step'>&#x25b6; Step</button>".html_safe
  end
  def run_button
    "<button class='fast-forward'>&#x25b6;&#x25b6; Run</button>".html_safe
  end
end
