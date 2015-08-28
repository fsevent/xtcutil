class Node
  def initialize
    @unified = nil
    @name = nil
    @height = nil
    @lines = []
  end

  def unified_node
    if @unified
      @unified = @unified.unified_node
    else
      self
    end
  end

  def pretty_print(q)
    center = mean_pos
    error = max_error
    q.object_group(self) {
      q.breakable
      q.text(@name || "(#{self.object_id})")
      if center
        if @height
          q.text("(%.2f,%.2f,%.2f)" % [center[0], center[1], @height])
        else
          q.text("(%.2f,%.2f)" % [center[0], center[1]])
        end
        if 0.1 < error
          q.text("{error=%.3g}" % error)
        end
      end
      if !@lines.empty?
        q.text ":"
        each_line {|posindex, line|
          n = line.get_node(1-posindex)
          if n
            n_name = n.get_node_name || "(#{n.object_id})"
          else
            n_name = "(no node assigned)"
          end
          q.breakable
          q.text n_name
        }
      end
    }
  end

  alias inspect pretty_print_inspect

  def unify_node(node)
    return unified_node.unify_node(node) if @unified
    node = node.unified_node
    if self.equal?(node)
      return
    end
    if @name && (node_name = node.name) && @name != node_name
      raise ArgumentError, "different name nodes not unifiable: #{@name.inspect} and #{node_name}"
    end
    if @name && !node_name
      node.set_node_name(@name)
    end
    if @height && (node_height = node.height) && @height != node_height
      raise ArgumentError, "different height nodes not unifiable: #{@height.inspect} and #{node_height}"
    end
    if @height && !node_height
      node.set_node_height(@height)
    end
    @lines.each {|posindex, line|
      node.add_line(posindex, line)
    }
    @unified = node
    @name = nil
    @height = nil
    @lines = nil
  end

  def set_node_name(name)
    return unified_node.set_node_name(name) if @unified
    if @name && @name != name
      raise "different node name already set: #{name} #{@name}"
    end
    @name = name
  end

  def get_node_name
    return unified_node.fetch_node_name if @unified
    @name
  end

  def fetch_node_name
    return unified_node.fetch_node_name if @unified
    raise "node name not set" if !@name
    @name
  end

  def set_node_height(height)
    return unified_node.set_node_height(height) if @unified
    if @height && @height != height
      raise "different node height already set: #{height} #{@height}"
    end
    @height = height
  end

  def get_node_height
    return unified_node.fetch_node_height if @unified
    @height
  end

  def fetch_node_height
    return unified_node.fetch_node_height if @unified
    raise "node height not set" if !@height
    @height
  end

  # line.get_node(posindex) should be self.
  def add_line(posindex, line)
    return unified_node.add_line(line, posindex) if @unified
    @lines << [posindex, line]
  end

  def each_line(&b) # :yields: line, posindex
    return unified_node.each_line(&b) if @unified
    @lines.each {|posindex, line|
      yield posindex, line
    }
  end

  def num_lines
    return unified_node.num_lines if @unified
    @lines.length
  end

  def mean_pos
    x = 0.0
    y = 0.0
    n = 0
    each_line {|posindex, line|
      n += 1
      pos = line.get_pos(posindex)
      x += pos[0]
      y += pos[1]
    }
    if n == 0
      nil
    else
      [x / n, y / n]
    end
  end

  def max_error
    center = mean_pos
    return nil if !center
    error = 0.0
    each_line {|posindex, line|
      pos = line.get_pos(posindex)
      e = hypot_pos(pos, center)
      error = e if error < e
    }
    return error
  end

end
