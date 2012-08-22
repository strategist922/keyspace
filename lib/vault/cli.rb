require 'thor'

module Vault
  class CLI < Thor
    desc :server, "Start the Vault server"
    def server
      require 'vault/server/app'
      Server::App.run!
    end
  end
end