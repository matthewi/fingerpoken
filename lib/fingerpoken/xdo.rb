#!/usr/bin/env ruby

require "rubygems"
require "xdo/keyboard"
require "xdo/mouse"
require "xdo/xwindow"
require "fingerpoken/target"

# add mousemove_relative to xdo
module XDo
  module Mouse
      extend XDo::Mouse
      def move_relative(x, y, speed = 2, set = true, sync = true)
        if set
          opts = []
          opts << "--sync" if sync
          `#{XDOTOOL} mousemove_relative #{opts.join(" ")} -- #{x} #{y}`
          return [x, y]
        else
          raise(ArgumentError, "speed has to be > 0 (default is 2), was #{speed}!") if speed <= 0
          pos = position #Current cursor position
          act_x = pos[0]
          act_y = pos[1]
          aim_x = x
          aim_y = y
          #Create the illusion of a fluent movement (hey, that statement sounds better in German, really! ;-))
          loop do
            #Change position as indiciated by +speed+
            if act_x > aim_x
              act_x -= speed
            elsif act_x < aim_x
              act_x += speed
            end
            if act_y > aim_y
              act_y -= speed
            elsif act_y < aim_y
              act_y += speed
            end
            #Move to computed position
            move(act_x, act_y, speed, true)
            #Check wheather the cursor's current position is inside an 
            #acceptable area around the goal position. The size of this 
            #area is defined by +speed+; this check ensures we don't get 
            #an infinite loop for unusual conditions. 
            if ((aim_x - speed)..(aim_x + speed)).include? act_x
              if ((aim_y - speed)..(aim_y + speed)).include? act_y
                break
              end #if in Y-Toleranz
            end #if in X-Toleranz
          end #loop
          #Correct the cursor position to point to the exact point specified. 
          #This is for the case the "acceptable area" condition above triggers. 
          if position != [x, y]
            move(x, y, 1, true)
          end #if position != [x, y]
          
        end #if set
        [x, y]
      end
  end
end
  
class FingerPoken::Target::Xdo < FingerPoken::Target

  def initialize(config)
    super(config)
    @rootwin = XDo::XWindow.from_root 
    @screen_x, @screen_y = @rootwin.size()
  end

  def mousemove_relative(x, y)
    return XDo::Mouse.move_relative(x, y)
  end

  def mousemove_absolute(px, py)
    # Edges may be hard to hit on some devices, so inflate things a bit.
    xbuf = @screen_x * 0.1
    ybuf = @screen_y * 0.1
    x = (((@screen_x + xbuf) * px) - (xbuf / 2)).to_i
    y = (((@screen_y + ybuf) * py) - (ybuf / 2)).to_i

    return XDo::Mouse.move(x, y)
  end

  def click(button)
    return XDo::Mouse.click(nil, nil, button.to_i)
  end

  def mousedown(button)
    return XDo::Mouse.down(button.to_i)
  end

  def mouseup(button)
    return XDo::Mouse.up(button.to_i)
  end

  def type(string)
    return XDo::Keyboard.type(string)
  end

  def keypress(key)
    if key.is_a?(String)
      if key.length == 1
        # Assume letter
        type(key)
      else
        # Assume keysym
        XDo::Keyboard.char(key)
      end
    else
      # type printables, key others.
      if 32.upto(127).include?(key)
        type(key.chr)
      else
        case key
          when 8 
            XDo::Keyboard.char("BackSpace")
          when 13
            XDo::Keyboard.char("Return")
          else
            puts "I don't know how to type web keycode '#{key}'"
          end # case key
      end # if 32.upto(127).include?(key)
    end # if key.is_a?String
    return nil
  end # def keypress
end # class FingerPoken::Target::Xdo 
