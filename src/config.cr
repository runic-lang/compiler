module Runic
  def self.root
    File.expand_path("../..", Process.executable_path.not_nil!)
  end

  def self.libexec
    File.join(root, "libexec")
  end

  def self.manpages
    File.join(root, "doc", "man1")
  end

  def self.open_manpage(command)
    manpage = File.join(manpages, "runic-#{command}.1")
    Process.exec("man", {manpage})
  end
end
