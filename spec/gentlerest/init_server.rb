require 'gentlerest'

if GentleREST.server(:default) == nil
  Thread.new do
    GentleREST.start(:name => :default)
  end
end
loop do
  break if GentleREST.server(:default) != nil
  sleep 0.1
end
