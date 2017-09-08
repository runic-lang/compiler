module Runic
  def self.version_string
    {{ `cat #{__DIR__}/../VERSION`.stringify.strip }}
  end
end
