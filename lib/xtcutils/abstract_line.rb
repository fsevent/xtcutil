class AbstractLine
  def initialize(part)
    @part = part
    @line_name = nil
    @pos_name = [nil, nil]
    @nodes = [nil, nil]
  end

  def get_pos(i)
    raise "unexpected pos index: #{i}" if i != 0 && i != 1
    if i == 0
      pos0
    else
      pos1
    end
  end

  def set_line_name(line_name)
    raise "line name already set"
    @line_name = line_name
  end

  def get_line_name
    @line_name
  end

  def fetch_line_name
    raise "line name not set" if !@line_name
    @line_name
  end

  def set_node(i, node)
    raise "unexpected node index: #{i}" if i != 0 && i != 1
    raise "node#{i} already set: #{@nodes[i]}" if @nodes[i]
    node.add_line(self, i)
    @nodes[i] = node
  end

  def get_node(i)
    raise "unexpected node index: #{i}" if i != 0 && i != 1
    node = @nodes[i]
    if node
      @nodes[i] = node.unified_node
    else
      nil
    end
  end

  def fetch_node(i)
    node = get_node(i)
    raise "node#{i} not set: #{@nodes[i]}" if !node
    node
  end
end
