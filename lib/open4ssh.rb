require "open4ssh/version"
require "net/ssh"

module Open4ssh

  # Executes a shell command on a remote host via SSH and returns the console output.
  #
  # @param host [String] DNS name or IP address of the remote host (required)
  # @param port [Integer] Port (defaults to 22)
  # @param user [String] User name (required)
  # @param key [Path] Path to a key file (.pem) if user logs in via keyfile (not required if password is provided)
  # @param pwd [String] Password of user (not required if key is provided)
  # @param cmd [String] valid shell command string to be executed on host (required)
  #
  # @return [String] console output of executed command (output includes stdout and stderr)
  #
  def self.exec(host: '', user: '', port: 22, key: '', pwd: '', cmd: '')
    stdout = ""
    keys = [key]

    Net::SSH.start(host, user, port: 22, password: pwd, keys: keys) do |ssh|
      result = ssh.exec!(cmd)
      stdout = result
    end

    return stdout
  end

  # Executes a list of shell commands on a remote host via SSH and returns their exit codes, stdouts and stderrs.
  # The commands are executed sequentially until a command terminates with an exit code not equal 0 (no success).
  #
  # @param host [String] DNS name or IP address of the remote host (required)
  # @param port [Integer] Port (defaults to 22)
  # @param user [String] User name (required)
  # @param key [Path] Path to a key file (.pem) if user logs in via keyfile (not required if password is provided)
  # @param pwd [String] Password of user (not required if key is provided)
  # @param cmd [Array<String>] List of valid shell command strings to be executed on host (required)
  # @param verbose [Bool] console outputs are plotted to stdout/stderr if set (defaults to false)
  #
  # @return [Array<exit_code, stdout, stderr, command>] List of exit_code, stdout, stderr and executed commands
  #
  def self.exec4(host: '', user: '', port: 22, key: '', pwd: '', cmd: [], verbose: false)
    keys    = [key]
    results = []

    Net::SSH.start(host, user, port: port, password: pwd, keys: keys) do |ssh|
      # Execute command by command
      for command in cmd
        stdout   = ""
        stderr   = ""
        code     = nil
        channel = ssh.open_channel do |ch|
          ch.exec(command) do |c, success|
            c.close unless success

            c.on_data do |_, data|
              stdout += data
              $stdout.puts(data) if verbose
            end

            c.on_extended_data do |_, _, data|
              stderr += data
              $stderr.puts(data) if verbose
            end

            c.on_request('exit-status') { |_, data| code = data.read_long }
          end
        end
        channel.wait
        results << [code, stdout, stderr, command]

        # If last command was not successful stop execution
        if code != 0
          ssh.close
          return results
        end
      end
    end

    return results
  end
end