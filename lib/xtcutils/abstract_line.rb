class AbstractLine
  def initialize(part)
    @part = part
    @line_name = nil
    @nodes = [nil, nil]
  end
  attr_reader :part

  def pretty_print_instance_variables
    instance_variables.sort - [:@part]
  end

  def pretty_print(q)
    q.pp_object(self)
  end

  alias inspect pretty_print_inspect

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
    @nodes[i] = node
    node.add_line(i, self)
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
