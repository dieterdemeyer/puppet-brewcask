require "puppet/provider/package"
require "puppet/util/execution"

Puppet::Type.type(:package).provide :brewcask,
  :parent => Puppet::Provider::Package do
  include Puppet::Util::Execution

  confine  :operatingsystem => :darwin

  has_feature :versionable
  has_feature :install_options

  # no caching, thank you
  def self.instances
    []
  end

  def self.home
    if boxen_home = Facter.value(:boxen_home)
      "#{boxen_home}/homebrew"
    else
      "/usr/local"
    end
  end

  def self.caskroom
    "/opt/homebrew-cask/Caskroom/"
  end

  def self.current(name)
    caskdir = Pathname.new "#{caskroom}/#{name}"
    caskdir.directory? && caskdir.children.size >= 1 && caskdir.children.sort.last.to_s
  end

  def query
    return unless version = self.class.current(resource[:name])
    { :ensure => version, :name => resource[:name] }
  end

  def install
    run "install", resource[:name], *install_options
  end

  def uninstall
    run "uninstall", resource[:name]
  end

  def install_options
    Array(resource[:install_options]).flatten.compact
  end

  def run(*cmds)
    brew_cmd = ["brew", "cask"] + cmds
    execute brew_cmd, command_opts
  end

  private
  # Override default `execute` to run super method in a clean
  # environment without Bundler, if Bundler is present
  def execute(*args)
    if Puppet.features.bundled_environment?
      Bundler.with_clean_env do
        super
      end
    else
      super
    end
  end

  # Override default `execute` to run super method in a clean
  # environment without Bundler, if Bundler is present
  def self.execute(*args)
    if Puppet.features.bundled_environment?
      Bundler.with_clean_env do
        super
      end
    else
      super
    end
  end

  def default_user
    Facter.value(:boxen_user) || Facter.value(:id) || "root"
  end

  def command_opts
    @command_opts ||= {
      :combine            => true,
      :custom_environment => {
        "HOME"            => "/Users/#{default_user}",
        "PATH"            => "#{self.class.home}/bin:/usr/bin:/usr/sbin:/bin:/sbin"
      },
      :failonfail         => true,
      :uid                => default_user
    }
  end
end
