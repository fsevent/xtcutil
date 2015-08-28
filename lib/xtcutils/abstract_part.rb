class AbstractPart
  def initialize(layout, h)
    @layout = layout
    @h = h
    @endpoint_node = {}
    @endpoint_node.compare_by_identity
  end

  def index
    @h[:index].to_int
  end

  def each_seg(&b)
    segs = @h[:segs]
    segs.each(&b)
  end

  def nearest_endpoint_internal(pos1, types)
    result_ep = nil
    result_distance = nil
    each_seg {|seg|
      next unless types.include? seg[:type]
      pos2 = seg[:pos]
      distance = Math.hypot(pos1[0] - pos2[0], pos1[1] - pos2[1])
      if !result_ep
        result_ep = seg
        result_distance = distance
      else
        if distance < result_distance
          result_ep = seg
          result_distance = distance
        end
      end
    }
    result_ep
  end

  def nearest_connected_endpoint(pos1)
    nearest_endpoint_internal(pos1, %w[T])
  end

  def nearest_endpoint(pos1)
    nearest_endpoint_internal(pos1, %w[T E])
  end

  def set_endpoint_node(ep, endpoint_node)
    if @endpoint_node[ep]
      raise "endpoint node already set"
    end
    @endpoint_node[ep] = endpoint_node
  end

  def fetch_endpoint_node(ep)
    @endpoint_node.fetch(ep)
  end

  def get_endpoint_node(ep)
    @endpoint_node[ep]
  end

  def each_path(&b)
    each_state_paths {|name, paths|
      paths.each(&b)
    }
  end

end
