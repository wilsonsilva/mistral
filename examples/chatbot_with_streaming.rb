#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple chatbot example -- run with -h argument to see options.

require 'bundler/setup'
require 'dotenv/load'
require 'readline'
require 'optparse'
require 'mistral'

MODEL_LIST = %w[
  mistral-tiny-latest
  mistral-small-latest
  mistral-medium-latest
  codestral-latest
].freeze
DEFAULT_MODEL = 'mistral-small-latest'
DEFAULT_TEMPERATURE = 0.7
LOG_FORMAT = '%(asctime)s - %(levelname)s - %(message)s'
# A hash of all commands and their arguments, used for tab completion.
COMMAND_LIST = {
  '/new' => {},
  '/help' => {},
  '/model' => MODEL_LIST.map { |model| [model, {}] }.to_h, # Nested completions for models
  '/system' => {},
  '/temperature' => {},
  '/config' => {},
  '/quit' => {},
  '/exit' => {}
}.freeze

$logger = Logger.new($stdout)
$logger.level = Logger::INFO
$logger.formatter = proc do |severity, datetime, _, msg|
  "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} - #{severity} - #{msg}\n"
end

def find_completions(command_dict, parts)
  return command_dict.keys if parts.empty?

  if command_dict.key?(parts[0])
    find_completions(command_dict[parts[0]], parts[1..])
  else
    command_dict.keys.select { |cmd| cmd.start_with?(parts[0]) }
  end
end

# Enable tab completion
Readline.completion_proc = proc do |_input|
  line_parts = Readline.line_buffer.lstrip.split(' ')
  options = find_completions(COMMAND_LIST, line_parts[0..-2])
  options.select { |option| option.start_with?(line_parts[-1]) }
end

class ChatBot
  def initialize(api_key, model, system_message = nil, temperature = DEFAULT_TEMPERATURE)
    raise ArgumentError, 'An API key must be provided to use the Mistral API.' if api_key.nil?

    @client = Mistral::Client.new(api_key: api_key)
    @model = model
    @temperature = temperature
    @system_message = system_message
  end

  def opening_instructions
    puts '
To chat: type your message and hit enter
To start a new chat: /new
To switch model: /model <model name>
To switch system message: /system <message>
To switch temperature: /temperature <temperature>
To see current config: /config
To exit: /exit, /quit, or hit CTRL+C
To see this help: /help
    '
  end

  def new_chat
    puts ''
    puts "Starting new chat with model: #{@model}, temperature: #{@temperature}"
    puts ''
    @messages = []
    @messages << Mistral::ChatMessage.new(role: 'system', content: @system_message) if @system_message
  end

  def switch_model(input)
    model = get_arguments(input)

    if MODEL_LIST.include?(model)
      @model = model
      $logger.info("Switching model: #{model}")
    else
      $logger.error("Invalid model name: #{model}")
    end
  end

  def switch_system_message(input)
    system_message = get_arguments(input)

    if system_message
      @system_message = system_message
      $logger.info("Switching system message: #{system_message}")
      new_chat
    else
      $logger.error("Invalid system message: #{system_message}")
    end
  end

  def switch_temperature(input)
    temperature = get_arguments(input)

    begin
      temperature = Float(temperature)

      raise ArgumentError if temperature.negative? || temperature > 1

      @temperature = temperature
      $logger.info("Switching temperature: #{temperature}")
    rescue ArgumentError
      $logger.error("Invalid temperature: #{temperature}")
    end
  end

  def show_config
    puts ''
    puts "Current model: #{@model}"
    puts "Current temperature: #{@temperature}"
    puts "Current system message: #{@system_message}"
    puts ''
  end

  def collect_user_input
    puts ''
    print 'YOU: '
    gets.chomp
  end

  def run_inference(content)
    puts ''
    puts 'MISTRAL:'
    puts ''

    @messages << Mistral::ChatMessage.new(role: 'user', content: content)

    assistant_response = ''

    $logger.debug("Running inference with model: #{@model}, temperature: #{@temperature}")
    $logger.debug("Sending messages: #{@messages}")

    @client.chat_stream(model: @model, temperature: @temperature, messages: @messages).each do |chunk|
      response = chunk.choices[0].delta.content

      if response
        print response
        assistant_response += response
      end
    end

    puts ''

    @messages << Mistral::ChatMessage.new(role: 'assistant', content: assistant_response) if assistant_response

    $logger.debug("Current messages: #{@messages}")
  end

  def get_command(input)
    input.split[0].strip
  end

  def get_arguments(input)
    input.split[1..].join(' ')
  rescue IndexError
    ''
  end

  def is_command?(input)
    COMMAND_LIST.key?(get_command(input))
  end

  def execute_command(input)
    command = get_command(input)
    case command
    when '/exit', '/quit'
      exit
    when '/help'
      opening_instructions
    when '/new'
      new_chat
    when '/model'
      switch_model(input)
    when '/system'
      switch_system_message(input)
    when '/temperature'
      switch_temperature(input)
    when '/config'
      show_config
    end
  end

  def start
    opening_instructions
    new_chat

    loop do
      input = collect_user_input

      if is_command?(input)
        execute_command(input)
      else
        run_inference(input)
      end
    rescue Interrupt
      exit
    end
  end

  def exit
    $logger.debug('Exiting chatbot')
    puts 'Goodbye!'
    Kernel.exit(0)
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: chatbot.rb [options]'

  opts.on(
    '--api-key KEY',
    'Mistral API key. Defaults to environment variable MISTRAL_API_KEY'
  ) do |key|
    options[:api_key] = key
  end

  opts.on(
    '-m',
    '--model MODEL',
    MODEL_LIST,
    "Model for chat inference. Choices are #{MODEL_LIST.join(", ")}. Defaults to #{DEFAULT_MODEL}"
  ) do |model|
    options[:model] = model
  end

  opts.on(
    '-s',
    '--system-message MESSAGE',
    'Optional system message to prepend'
  ) do |message|
    options[:system_message] = message
  end

  opts.on(
    '-t',
    '--temperature FLOAT',
    Float,
    "Optional temperature for chat inference. Defaults to #{DEFAULT_TEMPERATURE}"
  ) do |temp|
    options[:temperature] = temp
  end

  opts.on(
    '-d',
    '--debug',
    'Enable debug logging'
  ) do
    options[:debug] = true
  end
end.parse!

api_key = options[:api_key] || ENV.fetch('MISTRAL_API_KEY')
model = options[:model] || DEFAULT_MODEL
system_message = options[:system_message]
temperature = options[:temperature] || DEFAULT_TEMPERATURE

$logger.level = options[:debug] ? Logger::DEBUG : Logger::INFO

$logger.debug(
  "Starting chatbot with model: #{model}, " \
  "temperature: #{temperature}, " \
  "system message: #{system_message}"
)

begin
  bot = ChatBot.new(api_key, model, system_message, temperature)
  bot.start
rescue StandardError => e
  $logger.error(e)
  exit(1)
end
