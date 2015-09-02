class Node
  def initialize
    @unified = nil
    @uniq_attrs = {}
    @list_attrs = {}
  end

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
      lines = get_list_attr(:lines)
      if !lines.empty?
        q.text ":"
        each_line {|tipindex, line|
          n = line.get_node(1-tipindex)
          if n
            n_name = n.get_node_name || "(#{n.object_id})"
          else
            n_name = "(no node assigned)"
          end
          q.breakable
          q.text n_name
        }
      end
      if get_uniq_attr(:defined_height)
        q.breakable
        q.text "(zdef)"
      end
      get_list_attr(:comments).each {|comment|
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
      return self
    end
    @uniq_attrs.each {|k, v1|
      if node.has_uniq_attr?(k) && v1 != (v2 = node.fetch_uniq_attr(k))
        raise ArgumentError, "unique attribute has different value: #{k} : #{v1.inspect} and #{v2.inspect}"
      end
    }
    @uniq_attrs.each {|k, v1|
      if !node.has_uniq_attr?(k)
        node.set_uniq_attr(k, v1)
      end
    }
    @list_attrs.each {|k, vs|
      vs.each {|v|
        node.add_list_attr(k, v)
      }
    }
    @unified = node
    @uniq_attrs = nil
    @list_attrs = nil
    node
  end

  def has_uniq_attr?(k)
    return unified_node.has_uniq_attr?(k) if @unified
    @uniq_attrs.has_key?(k)
  end

  def set_uniq_attr(k, v)
    return unified_node.set_uniq_attr(k, v) if @unified
    if @uniq_attrs.has_key?(k) && @uniq_attrs[k] != v
      raise "cannot set unique attribute: #{k} : #{v.inspect} (already set: #{@uniq_attrs[k]}.inspect)"
    end
    @uniq_attrs[k] = v
    nil
  end

  def get_uniq_attr(k)
    return unified_node.get_uniq_attr(k) if @unified
    @uniq_attrs[k]
  end

  def fetch_uniq_attr(k)
    return unified_node.fetch_node_name if @unified
    raise "unique attribute not set: #{k}" if !@uniq_attrs.has_key?(k)
    @uniq_attrs[k]
  end

  def count_list_attr(k)
    return unified_node.count_list_attr(k) if @unified
    if @list_attrs[k]
      @list_attrs[k].length
    else
      0
    end
  end

  def add_list_attr(k, v)
    return unified_node.add_list_attr(k, v) if @unified
    @list_attrs[k] ||= []
    @list_attrs[k] << v
    nil
  end

  def get_list_attr(k)
    return unified_node.get_list_attr(k) if @unified
    if @list_attrs[k]
      @list_attrs[k].dup
    else
      []
    end
  end

  def set_node_name(name) set_uniq_attr(:node_name, name) end
  def get_node_name() get_uniq_attr(:node_name) end
  def fetch_node_name() fetch_uniq_attr(:node_name) end

  def set_node_height(name) set_uniq_attr(:node_height, name) end
  def get_node_height() get_uniq_attr(:node_height) end
  def fetch_node_height() fetch_uniq_attr(:node_height) end

  # line.get_node(tipindex) should be self.
  def add_line(tipindex, line)
    raise ArgumentError, "tipindex should be 0 or 1 : #{tipindex.inspect}" if tipindex != 0 && tipindex != 1
    raise ArgumentError, "line expected: #{line.inspect} " unless line.kind_of? AbstractLine
    return unified_node.add_line(tipindex, line) if @unified
    add_list_attr(:lines, [tipindex, line])
  end

  def lines
    ary = []
    each_line {|tipindex, line|
      ary << [tipindex, line]
    }
    ary
  end

  def each_line(&b) # :yields: line, tipindex
    return unified_node.each_line(&b) if @unified
    get_list_attr(:lines).each {|tipindex, line|
      yield tipindex, line
    }
  end

  def num_lines
    return unified_node.num_lines if @unified
    count_list_attr(:lines)
  end

  def add_comment(comment)
    add_list_attr(:comments, comment)
  end

  def mean_pos
    return unified_node.mean_pos if @unified
    n = count_list_attr(:lines)
    if n == 0
      return nil
    end
    x = 0.0
    y = 0.0
    each_line {|tipindex, line|
      pos = line.get_pos(tipindex)
      x += pos[0]
      y += pos[1]
    }
    [x / n, y / n]
  end

  def max_gap
    center = mean_pos
    return nil if !center
    gap = 0.0
    each_line {|tipindex, line|
      pos = line.get_pos(tipindex)
      e = hypot_pos(pos, center)
      gap = e if gap < e
    }
    return gap
  end

end
