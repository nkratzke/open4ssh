require 'simplecov'
SimpleCov.start

require 'test/unit'

# Base class for test classes.
# It defines common ssh settings to be used in all test classes
# and starts a ssh container for all test cases.
#
# @note It is assumed that a working docker system is installed.
#   The docker command must be executable by the user executing this
#   test suite.
#
# @author Nane Kratzke
#
class TestHelper < Test::Unit::TestCase

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

end