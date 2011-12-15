desc 'install dotfiles'
task :install do
  dotfiles.each do |filename|
    linkname = File.expand_path("~/.#{File.basename(filename)}")

    if File.exists?(linkname)
      puts "`#{linkname}` already exist"
    else
      puts "`#{linkname}` -> `#{filename}`"
      File.symlink(filename, linkname)
    end
  end

  unless File.directory?(File.expand_path('../vim/bundle/vundle', __FILE__))
    system('git clone http://github.com/gmarik/vundle.git ~/.vim/bundle/vundle')
    system('vim -u ~/.vim/bundle.vim +BundleInstall +q')
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
