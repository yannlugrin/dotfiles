desc 'install dotfiles'
task :install do
  dotfiles.each do |filename|
    linkname = File.expand_path("~/.#{File.basename(filename)}")

    if File.exists?(linkname)
      puts "`#{linkname}` already exist"
    else
      puts "`#{linkname}` -> `#{filename}`"
      File.link(filename, linkname)
    end
  end
end

desc 'list dotfiles'
task :list do
  dotfiles.each do |filename|
    puts File.basename(filename)
  end
end

def dotfiles
  Dir['*'].select {|filename| filename !~ /(Rakefile|README)/ }.map{|filename| File.expand_path(filename) }
end
