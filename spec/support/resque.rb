# redefine Reque's enqueue method so that we can test
Resque.class_eval do
  def self.enqueue(klass, *args)
    klass.perform(*args)
  end
end
