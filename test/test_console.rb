require 'test_helper'
require 'open4ssh'
require 'open3'

# Tests the console, stderr, and stdout commands.
#
# @author Nane Kratzke
#
class TestConsole

  # Tests the {Open4ssh.console} function and its interplay with {Open4ssh.stderr} and {Open4ssh.stdout}.
  #
  def test_console
    returns = Open4ssh.capture4(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: [
        "echo 'hello world'",
        "echo 'another test'",
        "echo 'super test'"
    ])

    assert_equal(3, returns.count)
    assert(Open4ssh.success(returns))
    assert_equal("echo 'hello world\nanother test\nsuper test\n'", Open4ssh.console(returns))
    assert(Open4ssh.stderr(returns).empty?)
    assert(Open4ssh.console(returns).include?(Open4ssh.stderr(returns)))
    assert(Open4ssh.console(returns).include?(Open4ssh.stdout(returns)))
  end

  # Tests the {Open4ssh.stdout} function and its interplay with {Open4ssh.stderr} and {Open4ssh.console}.
  #
  def test_stdout
    returns = Open4ssh.capture4(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: [
        "echo 'hello world'",
        "echo 'another test'",
        "echo 'super test'"
    ])

    assert_equal(3, returns.count)
    assert(Open4ssh.success(returns))
    assert_equal("echo 'hello world\nanother test\nsuper test\n'", Open4ssh.stdout(returns))
    assert(Open4ssh.stderr(returns).empty?)
    assert(Open4ssh.console(returns).include?(Open4ssh.stderr(returns)))
    assert(Open4ssh.console(returns).include?(Open4ssh.stdout(returns)))
  end

  # Tests the {Open4ssh.stderr} function and its interplay with {Open4ssh.stdout} and {Open4ssh.console}.
  #
  def test_stderr
    returns = Open4ssh.capture4(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: [
        "echo 'hello world'",
        "this will fail",
        "echo 'super test'"
    ])

    assert_equal(2, returns.count)
    assert(!Open4ssh.success(returns))
    assert_equal("echo 'hello world\n'", Open4ssh.stdout(returns))
    assert(!Open4ssh.stderr(returns).empty?)
    assert(Open4ssh.console(returns).include?(Open4ssh.stderr(returns)))
    assert(Open4ssh.console(returns).include?(Open4ssh.stdout(returns)))
  end

end