require 'fileutils'
require 'colored'
require 'yaml'
require 'net/sftp'
YAML::ENGINE.yamler = 'psych'

class File

  # @group Reading Files
  # Forces opening a file (for writing) by first creating the file's directory
  # @param [String] file the filename to open
  # @since 0.5.2
  def self.open!(file, *args, &block)
    dir = dirname(file)
    FileUtils.mkdir_p(dir) unless directory?(dir)
    open(file, *args, &block)

    # Create base directory, file directories and upload file via sftp
    sftp_create_base_directory
    sftp_file(file)
  end

  # Sets config from local .yardsftp file
  #
  # @return [Hash] opts Hash
  def self.sftp_config
    begin
      opts = YAML.load_file('.yardsftp')
    rescue Psych::SyntaxError
      abort 'Your .yardsftp file did not parse as expected!'.red.underline
    rescue Errno::ENOENT
      abort 'Your .yardsftp file is missing!'.red.underline
    end

    return opts
  end

  # Creates or returns sftp instance
  #
  # @return [Object] sftp instance
  def self.sftp
    sftp ||= Net::SFTP.start(HOST, USER, :password => PWD)
  end

  # Uploads file
  def self.sftp_file(file_path)
    directories = sftp_split_all(file_path)
    directories.pop #removes actual file from array

    unless directories.empty?
      sftp_build_directories(directories)
    end

    sftp.upload!(file_path, "#{BASE_PATH}/#{BASE_FOLDER}/#{file_path}")
  end

  # Creates directories
  #
  # @param opts [Array] directories Array of directory names
  def self.sftp_build_directories(directories)
    directories.each.with_index do |dir, i|
      if i == 0
        path = "#{BASE_PATH}/#{BASE_FOLDER}/#{dir}"
      elsif i == 1
        path = "#{BASE_PATH}/#{BASE_FOLDER}/#{directories[0]}/#{dir}"
      else
        path = "#{BASE_PATH}/#{BASE_FOLDER}/#{directories.take(i).join('/')}/#{dir}"
      end

      sftp_create_directory(path)
    end
  end

  # Creates base directory
  def self.sftp_create_base_directory
    unless sftp_directory_exists?("#{BASE_PATH}/#{BASE_FOLDER}")
      sftp_create_directory("#{BASE_PATH}/#{BASE_FOLDER}")
    end
  end

  # Creates base directory
  #
  # @param opts [String] path the path of directory
  def self.sftp_create_directory(path)
    unless sftp_directory_exists?(path)
      sftp.mkdir(path).wait
    end
  end

  # Checks if the directory exists
  #
  # @param opts [String] path the path of directory
  def self.sftp_directory_exists?(path)
    begin
      sftp.stat!(path)
    rescue
      return false
    else
      return true
    end
  end

  # Splits file path
  #
  # @param opts [String] path the path of directory
  # @return [Array] returns array of directories
  def self.sftp_split_all(path)
    head, tail = File.split(path)
    return [tail] if head == '.' || tail == '/'
    return [head, tail] if head == '/'
    return sftp_split_all(head) + [tail]
  end

  # Set configuration options
  OPTS        = sftp_config
  HOST        = OPTS['yard-sftp']['host']
  USER        = OPTS['yard-sftp']['username']
  PWD         = OPTS['yard-sftp']['password']
  BASE_PATH   = OPTS['yard-sftp']['base_path']
  BASE_FOLDER = OPTS['yard-sftp']['base_folder']
end