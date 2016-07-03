require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'open4ssh'
require 'open3'

# Tests the capture commands.
# @author Nane Kratzke
#
class TestCapture < Test::Unit::TestCase

  # SSH test user
  SSH_USER     = 'nane'

  # SSH test password
  SSH_PASSWORD = 'secret'

  # SSH port for testing
  SSH_PORT     = 2222

  # SSH container name
  CONTAINER    = 'ssh'

  # Starts ssh test container via {http://www.docker.io Docker}.
  # Installs a user with name 'nane' and password 'secret'.
  # SSH server operates on port 2222.
  #
  # We are using the following {https://github.com/mketo/docker/tree/master/ssh docker repository}.
  #
  def setup
    `docker run -d -p #{SSH_PORT}:22 -e SSH_PASSWORD=#{SSH_PASSWORD} -e SSH_USERNAME=#{SSH_USER} --name #{CONTAINER} keto/ssh`
    sleep 2 # Give the container some seconds to come up
  end

  # Shuts down ssh test container.
  #
  def teardown
    `docker stop #{CONTAINER}`
    `docker rm #{CONTAINER}`
  end

  # Tests the capture method.
  #
  def test_capture
    out = Open4ssh.capture(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: "echo 'hello world'")
    assert_equal("hello world\n", out)
  end

  # Tests the capture 3 method in case of a successful command.
  #
  def test_capture3_success
    exit_code, std_out, std_err = Open4ssh.capture3(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: "echo 'hello world'")

    assert_equal(0, exit_code)
    assert_equal("hello world\n", std_out)
    assert(std_err.empty?)
  end

  # Tests the capture3 method in case of a failing command.
  #
  def test_capture3_fail
    exit_code, std_out, std_err = Open4ssh.capture3(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: "this shall fail")

    assert_equal(127, exit_code)
    assert(std_out.empty?)
    assert(!std_err.empty?)
  end

  # Tests the capture4 method in case of a succesful commands.
  #
  def test_capture4_success
    returns = Open4ssh.capture4(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: [
        "echo 'hello world'",
        "echo 'another test'",
        "echo 'super test'"
    ])

    assert_equal(3, returns.count)
    assert(Open4ssh.success(returns))

    assert("echo 'hello world'", returns.first[3])
    assert("hello world\n", returns.first[1])

    assert("super test\n", returns.last[1])
    assert("echo 'super test'", returns.last[3])
  end

  # Tests the capture4 method in case of one failing command.
  #
  def test_capture4_fail
    returns = Open4ssh.capture4(host: 'localhost', port: SSH_PORT, user: SSH_USER, pwd: SSH_PASSWORD, cmd: [
        "echo 'hello world'",
        "this shall fail",
        "echo 'super test'"
    ])

    assert_equal(2, returns.count)
    assert(!Open4ssh.success(returns))

    assert_equal(0, returns.first[0])
    assert("echo 'hello world'", returns.first[3])
    assert("hello world\n", returns.first[1])

    assert(returns.last[0] != 0)
    assert(returns.last[1].empty?)
    assert(!returns.last[2].empty?)
  end

end