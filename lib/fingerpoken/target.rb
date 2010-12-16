require "logger"

class FingerPoken::Target
  def initialize(config)
    @channel = config[:channel]
    @logger = Logger.new(STDERR)
  end

  def register
    @channel.subscribe do |request|
      case request["action"]
      when "mousemove_relative"
        mousemove_relative(request["rel_x"], request["rel_y"])
      when "move_end"
        move_end()
      when "click"
        click(request["button"])
      when "mousedown"
        mousedown(request["button"])
      when "mouseup"
        mouseup(request["button"])
      when "type"
        type(request["string"])
      when "keypress"
        keypress(request["key"])
      else
        p ["Unsupported action", request]
      end
    end
  end

  # Subclasses should implement this.
  def mousemove_relative(x, y)
    @logger.info("mousemove not supported")
  end

  def mousedown(button)
    @logger.info("mousedown not supported")
  end

  def mouseup(button)
    @logger.info("mouseup not supported")
  end

  def click(button)
    mousedown(button)
    mouseup(button)
  end

  def type(string)
    @logger.info("typing not supported")
  end

  def keypress(key)
    @logger.info("keypress not supported")
  end

  def keydown(key)
    @logger.info("keydown not supported")
  end

  def keyup(key)
    @logger.info("keyup not supported")
  end

  def move_end()
    @logger.info("move_end not supported")
  end
end # class FingerPoken::Target
