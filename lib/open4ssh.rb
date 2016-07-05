require "open4ssh/version"
require "net/ssh"

# Open4ssh is a small convenience wrapper for {https://rubygems.org/gems/net-ssh net-ssh}.
# Its intended and primary purpose is to provide pragmatic
# execution of shell commands on a remote host via SSH.
#
# It provides the following functions:
#
# - {capture} to execute one command on a remote host via SSH and get the console output back.
# - {capture3} to execute one command on a remote host via SSH and get the exit code, standard out, standard error of the command back.
# - {capture4} to execute a sequence of commands on a remote host via SSH and get all return values (exit code, standard out, standard error, command) back.
# - {success} to evaluate whether a sequence of commands was successful.
# - {stdout} to get all standard out messages of a sequence of commands.
# - {stderr} to get all standard error messages of a sequence of commands.
# - {console} to get all console output (union of standard out and standard error messages) of a sequence of commands.
#
# @author Nane Kratzke
# @example
#   console = Open4ssh.capture(
#       host: 'remote.host.io',
#       user: 'nane',
#       pwd: 'secret',
#       cmd: 'ls -la'
#   )
#   puts console
#
module Open4ssh

  # Executes a shell command on a remote host via SSH and captures the console output.
  #
  # @param host [String] DNS name or IP address of the remote host (required)
  # @param port [Integer] Port (defaults to 22)
  # @param user [String] User name (required)
  # @param key [Path] Path to a key file (.pem) if user logs in via keyfile (not required if password is provided)
  # @param pwd [String] Password of user (not required if key is provided)
  # @param cmd [String] valid shell command string to be executed on host (required)
  #
  # @return [String] console output of executed command (output includes stdout and stderr)
  # @raise [One of Net::SSH::Exceptions] In case of net::ssh errors due to connection problems, authentication errors, timeouts, ....
  #
  # @example
  #   stdout = Open4ssh.capture(
  #       host: 'remote.host.io',
  #       user: 'nane',
  #       pwd: 'secret',
  #       cmd: 'ls -la'
  #   )
  #   puts stdout
  #
  def self.capture(host: '', user: '', port: 22, key: '', pwd: '', cmd: '')
    stdout = ""
    keys = [key]

    Net::SSH.start(host, user, port: port, password: pwd, keys: keys) do |ssh|
      stdout = ssh.exec!(cmd)
    end

    return stdout
  end

  # Executes one shell command on a remote host via SSH and captures it exit code, stdout and stderr.
  #
  # @param host [String] DNS name or IP address of the remote host (required)
  # @param port [Integer] Port (defaults to 22)
  # @param user [String] User name (required)
  # @param key [Path] Path to a key file (.pem) if user logs in via keyfile (not required if password is provided)
  # @param pwd [String] Password of user (not required if key is provided)
  # @param cmd [String] shell command string to be executed on host (required)
  # @param verbose [Bool] console outputs are plotted to stdout/stderr if set (defaults to false)
  #
  # @return [exit_code, std_out, std_err] exit_code, stdout, stderr of executed command
  # @raise [One of Net::SSH::Exceptions] In case of net::ssh errors due to connection problems, authentication errors, timeouts, ....
  #
  # @example
  #   exit_code, std_err, std_out = Open4ssh.capture3(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     pwd: 'secret',
  #     cmd: 'ls -la'
  #   )
  #
  def self.capture3(host: '', user: '', port: 22, key: '', pwd: '', cmd: '', verbose: false)
    returns = self.capture4(host: host, user: user, port: port, key: key, pwd: pwd, cmd: [cmd], verbose: verbose)
    exit_code = returns.last[0]
    std_out = returns.last[1]
    std_err = returns.last[2]
    return exit_code, std_out, std_err
  end

  # Executes a list of shell commands on a remote host via SSH and captures their exit codes, stdouts and stderrs.
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
  # @return [Array<exit_code, std_out, std_err, command>] List of exit_code, stdout, stderr and executed commands
  # @raise [One of Net::SSH::Exceptions] In case of net::ssh errors due to connection problems, authentication errors, timeouts, ....
  #
  # @example
  #   exit_code, stderr, stdout, command = Open4ssh.capture4(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     key: '/path/to/your/sshkey.pem',
  #     cmd: [
  #     "touch helloworld.txt",
  #     "cat helloworld.txt",
  #     "echo 'Hello World' >> helloworld.txt",
  #     "cat helloworld.txt",
  #     "rm helloworld.txt"
  #   ]).last
  #
  def self.capture4(host: '', user: '', port: 22, key: '', pwd: '', cmd: [], verbose: false)
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

  # Determines whether a list of shell commands has been executed successfully.
  #
  # @param results [Array<exit_code, std_out, std_err, command>] List of returns by executed commands as returned by capture4
  #
  # @return [Bool] true, if all exit codes are 0;
  # @return [Bool] false, otherwise
  #
  # @example
  #   ecodes = Open4ssh.capture4(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     key: '/path/to/your/sshkey.pem',
  #     cmd: [
  #       "touch helloworld.txt",
  #       "cat helloworld.txt",
  #       "echo 'Hello World' >> helloworld.txt",
  #       "cat helloworld.txt",
  #       "rm helloworld.txt"
  #   ])
  #
  #   if Open4ssh.success(ecodes)
  #      puts "Success:"
  #      puts Open4ssh.console(ecodes) # Print collected console outputs of all executed commands
  #   end
  #
  def self.success(results)
    results.select { |result| result[0] != 0 }.empty?
  end

  # Collects all stdout messages of a list of executed shell commands.
  #
  # @param results [Array<exit_code, std_out, std_err, command>] List of returns by executed commands as returned by capture4
  #
  # @return [String] All stdout messages (separated by line feed \n)
  #
  # @example
  #   ecodes = Open4ssh.capture4(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     key: '/path/to/your/sshkey.pem',
  #     cmd: [
  #       "touch helloworld.txt",
  #       "cat helloworld.txt",
  #       "echo 'Hello World' >> helloworld.txt",
  #       "cat helloworld.txt",
  #       "rm helloworld.txt"
  #   ])
  #
  #   if Open4ssh.success(ecodes)
  #      puts "Success:"
  #      puts Open4ssh.stdout(ecodes) # Print collected stdout messages of all executed commands
  #   end
  #
  def self.stdout(results)
    results.map { |result| result[1] }
           .select { |stdout| not stdout.strip.empty? } * ''
  end

  # Collects all stderr messages of a list of executed shell commands.
  #
  # @param results [Array<exit_code, std_out, std_err, command>] List of returns by executed commands as returned by capture4
  #
  # @return [String] All stderr messages (separated by line feed \n)
  #
  # @example
  #   ecodes = Open4ssh.capture4(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     key: '/path/to/your/sshkey.pem',
  #     cmd: [
  #       "touch helloworld.txt",
  #       "cat helloworld.txt",
  #       "this will fail",
  #       "cat helloworld.txt",
  #       "rm helloworld.txt"
  #   ])
  #
  #   unless Open4ssh.success(ecodes)
  #      puts "Failure:"
  #      puts Open4ssh.stderr(ecodes) # Print collected stderr messages of all executed commands
  #   end
  #
  def self.stderr(results)
    results.map { |result| result[2] }
           .select { |stderr| not stderr.strip.empty? } * ''
  end

  # Collects all console messages (stdout + stderr) of a list of executed shell commands.
  #
  # @param results [Array<exit_code, std_out, std_err, command>] List of returns by executed commands as returned by capture4
  #
  # @return [String] All console messages (separated by line feed \n)
  #
  # @example
  #   ecodes = Open4ssh.capture4(
  #     host: 'remote.host.io',
  #     user: 'nane',
  #     key: '/path/to/your/sshkey.pem',
  #     cmd: [
  #       "touch helloworld.txt",
  #       "cat helloworld.txt",
  #       "echo 'Hello World' >> helloworld.txt",
  #       "cat helloworld.txt",
  #       "rm helloworld.txt"
  #   ])
  #
  #   puts Open4ssh.console(ecodes) # Print collected console messages of all executed commands
  #
  def self.console(results)
    results.map { |result| "#{result[1]}#{result[2]}" }
           .select { |console| not console.strip.empty? } * ''
  end
end