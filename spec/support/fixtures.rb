##
# Fixtures implements a global container to store fixture data loaded from the
# filesystem.
class Fixtures
  def self.[](name)
    @fixtures[name]
  end

  def self.[]=(name, value)
    @fixtures[name] = value
  end

  def self.clear
    @fixtures = {}
  end

  clear
end


def get_fixture(name)
    File.join(File.dirname(__FILE__), "../fixtures/#{name}")
end

