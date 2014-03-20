require 'rake'

desc "Open pry console"
task :pry, :config_yml do |t, args|
  if !args.config_yml
    puts "Usage: rake pry[config.yml]"
    puts "Where config.yml looks something like:"
    puts "  url: 'cherwell.ds9.net'"
    puts "  username: 'sisko'"
    puts "  password: 'baseball'"
    exit
  end

  require 'pry'
  require 'savon'
  require 'cherby'

  config = YAML.load(File.open(args.config_yml))

  cherwell = Cherby::Cherwell.new(
    config['url'],
    config['username'],
    config['password']
  )

  binding.pry
end

