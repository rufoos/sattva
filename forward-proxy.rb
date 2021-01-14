require 'logger'
require 'webrick'
require 'webrick/httpproxy'
require 'webrick/https'

class ForwardProxy
  VERSION = "1.0.0"

  attr_reader :options, :config

  def self.run!(options)
    puts options
    ForwardProxy.new(options).run!
  end

  def initialize(options)
    @options = options
    options[:logfile] = File.expand_path(logfile) if logfile?
    options[:pidfile] = File.expand_path(pidfile) if pidfile?

    @config = { Port: port }
  end

  def daemonize?
    options[:daemonize]
  end

  def logfile
    options[:logfile]
  end

  def pidfile
    options[:pidfile]
  end

  def ssl_key_file
    options[:ssl_key_file]
  end

  def ssl_cert_file
    options[:ssl_cert_file]
  end

  def logfile?
    !logfile.nil?
  end

  def pidfile?
    !pidfile.nil?
  end

  def info(msg)
    puts "[#{Process.pid}] [#{Time.now}] #{msg}"
  end

  def port
    options[:port]
  end

  def ssl?
    options[:ssl] == true
  end

  def ssl_key_file?
    !ssl_key_file.nil?
  end

  def ssl_cert_file?
    !ssl_cert_file.nil?
  end

  def server_config
    @config.merge!(
      SSLEnable: true,
      SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
      SSLPrivateKey: OpenSSL::PKey::RSA.new(File.open(ssl_key_file).read),
      SSLCertificate: OpenSSL::X509::Certificate.new(File.open(ssl_cert_file).read),
      SSLCertName: [["CN", WEBrick::Utils::getservername]]
    ) if ssl? && ssl_key_file? && ssl_cert_file?

    @config.merge!(
      Logger: server_logger,
      AccessLog: server_access_log
    ) if logfile?

    @config
  end

  def server_logger
    access_log_file = File.open(logfile, 'a+')
    WEBrick::Log.new(access_log_file)
  end

  def server_access_log
    [[logfile, WEBrick::AccessLog::COMBINED_LOG_FORMAT]]
  end

  def run!
    proxy = WEBrick::HTTPProxyServer.new(server_config)

    check_pid
    daemonize if daemonize?
    write_pid

    if logfile?
      redirect_output
    elsif daemonize?
      suppress_output
    end

    trap 'INT' do
      File.delete(pidfile) if pidfile?
      proxy.shutdown
    end
    trap 'TERM' do
      File.delete(pidfile) if pidfile?
      proxy.shutdown
    end
    trap 'HUP' do
      log_file.reopen(access_log_filepath, 'a+')
    end

    proxy.start
  end

  def daemonize
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir "/"
  end

  def redirect_output
    FileUtils.mkdir_p(File.dirname(logfile), :mode => 0755)
    FileUtils.touch logfile
    File.chmod(0644, logfile)
    $stderr.reopen(logfile, 'a')
    $stdout.reopen($stderr)
    $stdout.sync = $stderr.sync = true
  end

  def suppress_output
    $stderr.reopen('/dev/null', 'a')
    $stdout.reopen($stderr)
  end

  def write_pid
    if pidfile?
      begin
        File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
          f.write("#{Process.pid}")
        end
        at_exit { File.delete(pidfile) if File.exists?(pidfile) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end
  end

  def check_pid
    if pidfile?
      case pid_status(pidfile)
      when :running, :not_owned
        puts "A server is already running. Check #{pidfile}"
        exit(1)
      when :dead
        File.delete(pidfile)
      end
    end
  end

  def pid_status(pidfile)
    return :exited unless File.exists?(pidfile)
    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid)
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end
end
