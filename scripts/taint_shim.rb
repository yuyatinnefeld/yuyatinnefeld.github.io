# Ruby 3.2 removed Object#tainted?, which the pinned liquid 4.0.3 still calls.
class Object
  def tainted?; false; end
  def taint; self; end
  def untaint; self; end
end
