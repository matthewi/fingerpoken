#!/usr/bin/env ruby

# TODO(sissel): Refactor the protocol into an EM::Tivo module.

require "rubygems"
require "fingerpoken/target"
require "ostruct"

class FingerPoken::Target::Tivo < FingerPoken::Target
  def initialize(config)
    super(config)
    # TODO(sissel): Make this a config
    @host = config[:host]
    @tivo = EventMachine::connect(@host, 31339, TivoClient, self)

    @state = OpenStruct.new # TODO(sissel): Make this not an open struct...
    
    @state.speed = 0
  end

  def mousemove_relative(x, y)
    direction = x < 0 ? -1 : 1
    want_speed = [(x.abs / 30).to_i, 3].min

    want_speed *= direction
    if want_speed != @state.speed
      p [want_speed]
    end

    if want_speed > @state.speed
      # increase to it
      1.upto(want_speed - @state.speed).each do
        puts "UP"
        @tivo.send_data("IRCODE FORWARD\r\n")
      end
    elsif (want_speed < @state.speed) 
      1.upto( (want_speed - @state.speed).abs ).each do
        @tivo.send_data("IRCODE REVERSE\r\n")
        puts "DOWN"
      end
      # decrease to it
    end
    @state.speed = want_speed
  end

  def move_end
    @tivo.send_data("IRCODE PLAY\r\n")
  end

  def click(button)
    case button.to_i
    when 1
      @tivo.send_data("IRCODE PAUSE\r\n")
    when 2 # 'middle' click (three fingers)
      @tivo.send_data("IRCODE SELECT\r\n")
    #when 2 # 'middle' click (three fingers)
      #@tivo.send_data("IRCODE TIVO\r\n")
    when 4 # scroll up
      @tivo.send_data("IRCODE UP\r\n")
    when 5 # scroll down
      @tivo.send_data("IRCODE DOWN\r\n")
    end
  end

  # Hack for now
  def keypress(key)
    case key
    when "Home"
      @tivo.send_data("IRCODE TIVO\r\n")
    when "Return"
      @tivo.send_data("IRCODE SELECT\r\n")
    end
  end

  class TivoClient < EventMachine::Connection
    def initialize(target)
      puts "init #{self} / #{target}"
      @target = target
    end

    def connection_completed
      @target.register
      puts "Ready"
    end

    def receive_data(data)
      p "Tivo says: #{data}"
    end

    def send_data(data)
      puts "Sending: #{data}"
      super(data)
    end
  end # class TivoClient
end # class FingerPoken::Target::Tivo 