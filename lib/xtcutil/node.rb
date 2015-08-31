class Node
  def initialize
    @unified = nil
    @attrs = {}
    @lines = []
    @comments = []
  end
  attr_reader :comments

  def unified_node
    if @unified
      @unified = @unified.unified_node
    else
      self
    end
  end

  def pretty_print(q)
    if @unified
      q.object_group(self) {
        q.breakable
        q.text "unified to #{@unified.object_id}"
      }
      return
    end
    center = mean_pos
    mgap = max_gap
    q.object_group(self) {
      q.breakable
      q.text(get_node_name || "(#{self.object_id})")
      if center
        if get_node_height
          q.text("(%.3f,%.3f,%.3f)" % [center[0], center[1], get_node_height])
        else
          q.text("(%.3f,%.3f)" % [center[0], center[1]])
        end
        if 0.1 < mgap
          q.text("{max_gap=%.3g}" % error)
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
      if get_attr(:defined_height)
        q.breakable
        q.text "(zdef)"
      end
      @comments.each {|comment|
        q.breakable
        q.text "(#{comment})"
      }
    }
  end

  alias inspect pretty_print_inspect

  def unify_node(node)
    return unified_node.unify_node(node) if @unified
    node = node.unified_node
    if self.equal?(node)
      return
    end
    @attrs.each {|k, v1|
      if node.attrs.has_key?(k) && v1 != (v2 = node.attrs[k])
        raise ArgumentError, "different attribute nodes not unifiable: #{k} : #{v1.inspect} and #{v2.inspect}"
      end
    }
    @attrs.each {|k, v1|
      if !node.attrs.has_key?(k)
        node.set_attr(k, v1)
      end
    }
    @lines.each {|posindex, line|
      node.add_line(posindex, line)
    }
    @comments.each {|comment|
      node.add_comment(comment)
    }
    @unified = node
    @attrs = nil
    @lines = nil
    @comments = nil
  end

  def set_attr(k, v)
    return unified_node.set_attr(k, v) if @unified
    if @attrs.has_key?(k) && @attrs[k] != v
      raise "cannot set node  attribute: #{k} : #{v.inspect} (already set: #{@attrs[k]}.inspect)"
    end
    @attrs[k] = v
    nil
  end

  def get_attr(k)
    return unified_node.get_attr(k) if @unified
    @attrs[k]
  end

  def fetch_attr(k)
    return unified_node.fetch_node_name if @unified
    raise "attribute not set: #{k}" if !@attrs.has_key(k)
    @attrs[k]
  end

  def set_node_name(name) set_attr(:node_name, name) end
  def get_node_name() get_attr(:node_name) end
  def fetch_node_name() fetch_attr(:node_name) end

  def set_node_height(name) set_attr(:node_height, name) end
  def get_node_height() get_attr(:node_height) end
  def fetch_node_height() fetch_attr(:node_height) end

  # line.get_node(posindex) should be self.
  def add_line(posindex, line)
    raise ArgumentError, "posindex should be 0 or 1 : #{posindex.inspect}" if posindex != 0 && posindex != 1
    raise ArgumentError, "line expected: #{line.inspect} " unless line.kind_of? AbstractLine
    return unified_node.add_line(posindex, line) if @unified
    @lines << [posindex, line]
  end

  def lines
    ary = []
    each_line {|posindex, line|
      ary << [posindex, line]
    }
    ary
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
    return unified_node.mean_pos if @unified
    n = @lines.length
    if n == 0
      return nil
    end
    x = 0.0
    y = 0.0
    each_line {|posindex, line|
      pos = line.get_pos(posindex)
      x += pos[0]
      y += pos[1]
    }
    [x / n, y / n]
  end

  def max_gap
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

  def add_comment(comment)
    @comments << comment
  end

end