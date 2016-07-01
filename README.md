# Open4ssh

[Open4ssh](https://github.com/nkratzke/open4ssh) is a small convenience wrapper for [net-ssh](https://rubygems.org/gems/net-ssh). 
Its intended and primary purpose is to provide pragmatic
execution of shell commands on a remote host via SSH.

It is mainly inspired by [Open3](http://ruby-doc.org/stdlib-2.3.1/libdoc/open3/rdoc/Open3.html) standard library 
which provides access to exit codes, 
standard output and standard error messages of executed commands on local host.
Open4ssh does the same but in a SSH remote context. 
Astonishingly, there seems no pragmatic way to figure out exit codes or standard error messages of executed commands 
with the net-ssh library.
Additionally, Open4ssh is able to execute a 
sequence of commands and returns their exit codes, standard out and standard error messages in a command related list.

Open4ssh is most useful in remote automation scenarios which are triggered from Ruby environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'open4ssh'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install open4ssh

## Usage

### Remote execution of a single command via SSH

All parameters of the _exec_ command are explained [here](Open4ssh.html#exec-class_method).

However, the following snippets explain how to use Open4ssh. 
To execute simply one single command on a remote host, we can do the following:

```ruby
require 'open4ssh'

stdout = Open4ssh.exec(
     host: 'remote.host.io',
     user: 'nane',
     pwd: 'secret',
     cmd: 'ls -la'
)
puts stdout
```

This will execute the bash command 'ls -la' on host _remote.host.io_ as user _nane_.

For a lot of cloud scenarios it is more appropriate to support a keybased login. This can be done like that 
(simply use the key parameter instead of the pwd parameter):

```ruby
require 'open4ssh'

stdout = Open4ssh.exec(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: 'ls -la'
)
puts stdout
```

### Remote execution of a sequence of commands via SSH

All parameters of the _exec4_ command are explained [here](Open4ssh.html#exec4-class_method).
The following snippets will explain how to use Open4ssh to execute a (sequence) of commands.

This snippet here will execute five shell commands sequentially

```ruby
require 'open4ssh'
require 'pp'

returns = Open4ssh.exec4(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: [
       "touch helloworld.txt",
       "cat helloworld.txt",
       "echo 'Hello World' >> helloworld.txt",
       "cat helloworld.txt",
       "rm helloworld.txt"
     ]
)
pp(returns)
```

and will generate this output.

    [[0, "", "", "touch helloworld.txt"],
     [0, "", "", "cat helloworld.txt"],
     [0, "", "", "echo 'Hello World' >> helloworld.txt"],
     [0, "Hello World\n", "", "cat helloworld.txt"],
     [0, "", "", "rm helloworld.txt"]]

So, for each command a list of return values is returned.

1. exit code of the executed command
2. standard out message (might be empty)
3. standard error message (might be empty)
4. executed command (as passed by the _cmd_ parameter in _exec4_ call.

However, if we launch a sequence of commands exiting with exit codes not equal 0, this sequence is only executed as long as 
each command could be successfully processed (exit code 0). So this snippet here

```ruby
require 'open4ssh'
require 'pp'

returns = Open4ssh.exec4(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: [
       "touch helloworld.txt",
       "cat helloworld.txt",
       "this will not work",
       "cat helloworld.txt",
       "rm helloworld.txt"
     ]
)
pp(returns)
```

would produce the following output

    [[0, "", "", "touch helloworld.txt"],
     [0, "", "", "cat helloworld.txt"],
     [127, "", "bash: this: command not found\n", "this will not work"]]
     
and the last two commands would not been executed on the remote host, because the third command failed.

### How to check whether a sequence of commands was successful?

Because Open4ssh only executes commands as long as they are returning a exit code of 0, we can check 
pragmatically whether all commands of a sequence have been executed successfully:

```ruby
exit_code, stderr, stdout, command = Open4ssh.exec4(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: [
       "touch helloworld.txt",
       "cat helloworld.txt",
       "echo 'Hello World' >> helloworld.txt",
       "cat helloworld.txt",
       "rm helloworld.txt"
     ]
).last

if (exit_code == 0 && command == "rm helloworld.txt")
    puts "Everything worked fine"
end
```

### What is this good for?

Just a small example. Assuming your remote host is a Ubuntu 14.04 system we could do something like that:

```ruby
exit_code, stdout, stderr, command = Open4ssh.exec4(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: [
       "curl -fsSL https://test.docker.com/ | sh",
       "sudo docker swarm init"
     ]
).last

if (command == "sudo docker swarm init" && exit_code == 0)
    puts "You started successfully a new Docker Swarm cluster."
end
```

This would fire up an initial master for a [Docker Swarm cluster](https://docs.docker.com/engine/swarm/) 
in a few lines of Ruby code. Be patient. This can take several minutes. 
Of course, you can do any other tasks as well. This was only one example ;-)

### Verbose mode

If you want to know what is happening there you can turn on the verbose mode (mostly useful for debugging).

```ruby
exit_code, stdout, stderr, command = Open4ssh.exec4(
     host: 'remote.host.io',
     user: 'nane',
     key: '/path/to/your/sshkey.pem',
     cmd: [
       "curl -fsSL https://test.docker.com/ | sh",
       "sudo docker swarm init"
     ],
     verbose: true
).last

if (command == "sudo docker swarm init" && exit_code == 0)
    puts "You started successfully a new Docker Swarm cluster."
end
```

This will perform the same install like above but will print all messages of the Docker install script on your console.

## Development

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, 
and then run `bundle exec rake release`, 
which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on Github at https://github.com/nkratzke/open4ssh.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

