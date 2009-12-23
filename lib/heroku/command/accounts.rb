require 'yaml'

class Heroku::Command::Accounts < Heroku::Command::Base

  def index
    puts "No accounts found." if account_names.empty?

    account_names.each do |name|
      puts "%s: %s" % [ name, account(name)[:identity_file] ]
    end
  end

  def add
    name = args.shift

    error("Please specify an account name.") unless name
    error("That account already exists.") if account_exists?(name)

    auth = Heroku::Command::Auth.new(nil)
    username, password = auth.ask_for_credentials

    print "Path to identity file: "
    identity_file = ask

    write_account(name,
      :username      => username,
      :password      => password,
      :identity_file => identity_file
    )
  end

  def remove
    error("That account does not exist.") unless account_exists?(name)
  end

## account interface #########################################################

  def self.account(name)
    accounts = Heroku::Command::Accounts.new(nil)
    accounts.send(:account, name)
  end

private ######################################################################

  def account(name)
    error("No such account: #{name}") unless account_exists?(name)
    read_account(name)
  end

  def accounts_directory
    @accounts_directory ||= begin
      directory = File.join(home_directory, '.heroku', 'accounts')
      FileUtils::mkdir_p(directory)
      directory
    end
  end

  def account_file(name)
    File.join(accounts_directory, name)
  end

  def account_names
    Dir[File.join(accounts_directory, '*')].map { |d| File.basename(d) }
  end

  def account_exists?(name)
    account_names.include?(name)
  end

  def read_account(name)
    YAML::load_file(account_file(name))
  end

  def write_account(name, account)
    File.open(account_file(name), 'w') { |f| f.puts YAML::dump(account) }
  end

  def error(message)
    puts message
    exit 1
  end

end