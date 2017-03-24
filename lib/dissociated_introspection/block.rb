module DissociatedIntrospection
  Block = Struct.new(:ast, :type)

  def Block.source
    :source
  end

  def Block.to_h
    super.merge(source: source)
  end
end
