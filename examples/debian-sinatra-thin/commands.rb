# ----------------------------------------------------------- COMMANDS --------
# The commands block defines shell commands to be added to the default list 
# defined by Rye::Cmd (Rudy executes all SSH commands via Rye). Commands can 
# have any name except for keywords already used by Rudy.
commands do
  allow :apt_get, "apt-get", :y, :q
  allow :gem_install, "/usr/bin/gem", "install", :n, '/usr/local/bin', :y, :V, "--no-rdoc", "--no-ri"
  allow :gem_sources, "/usr/bin/gem", "sources"
  allow :thin, "/usr/local/bin/thin", :d, :R, './config.ru', :l, './thin.log', :P, './thin.pid', :p, "4566"
end