require_relative 'options_menu.rb'

class AppSelection < OptionsMenu

  register(:app_selection)

  def initialize(config_defaults)
    raise ArgumentError if config_defaults.nil?
    @app_defaults = config_defaults
  end

  def request_user_app_selection
    show_options_menu
    response = prompt_user_for_selection
    selection = response.chomp.to_i
    process_user_response(selection)
  end
  
  private

  def prompt(*args)
    print(*args)
    STDIN.gets
  end

  def process_user_response(selection)
    
  end

  def prompt_user_for_selection
    prompt("please enter a number")
  end

  def show_options_menu
    $stdout.puts "menu"
  end

end

