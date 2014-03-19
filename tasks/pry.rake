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

  $LOAD_PATH << File.expand_path('./lib')

  require 'pry'
  require 'savon'
  require 'cherby'

  config = YAML.load(File.open(args.config_yml))

  cherwell = Cherby::Cherwell.new(config)

  binding.pry
end

