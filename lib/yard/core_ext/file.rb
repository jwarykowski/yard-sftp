require 'fileutils'
require 'colored'
require 'yaml'
require 'net/sftp'

class File

  # @group Reading Files
  # Forces opening a file (for writing) by first creating the file's directory
  # @param [String] file the filename to open
  # @since 0.5.2
  def self.open!(file, *args, &block)
    dir = dirname(file)
    FileUtils.mkdir_p(dir) unless directory?(dir)
    open(file, *args, &block)

    sftp_create_path("#{BASE_DIR}")
    sftp_file(file)
  end

  # Sets config from local .yardsftp file
  #
  # @return [Hash] opts Hash
  def self.sftp_config
      opts = YAML.load_file('.yardsftp')
    rescue Psych::SyntaxError
      abort 'Your .yardsftp file did not parse as expected!'.red.underline
    rescue Errno::ENOENT
      abort 'Your .yardsftp file is missing!'.red.underline
  end

  # Creates or returns sftp instance
  #
  # @return [Object] sftp instance
  def self.sftp
      tries ||= 3
      connection ||= Net::SFTP.start(HOST, USER, :password => PWD)
    rescue Errno::EADDRINUSE
      log.progress('SSH Connection Error - retrying', nil)
      retry unless (tries -= 1).zero?
  end

  # Uploads file
  #
  # @param opts [String] file_path path of the file
  def self.sftp_file(file_path)
    paths = sftp_split_all(file_path)
    paths.pop
    return if paths.include?(".yardoc")

    unless paths.empty?
      sftp_create_paths(paths)
    end

    log.progress("Uploading #{file_path}", nil)
    sftp.upload!(file_path, "#{BASE_DIR}/#{file_path}")
  end

  # Creates paths relevant for file
  #
  # @param opts [Array] paths Array of paths
  def self.sftp_create_paths(paths)
    # Check if path doesn't already exists
    if sftp_path_exists?("#{BASE_DIR}/#{paths.join('/')}")
      sftp_clean_path("#{BASE_DIR}/#{paths.join('/')}")
    else
      # Iterate through each path and create
      paths.each.with_index do |p, i|
        case i
        when 0
          sftp_create_path("#{BASE_DIR}/#{p}")
        when 1
          sftp_create_path("#{BASE_DIR}/#{paths[0]}/#{p}")
        else
          sftp_create_path("#{BASE_DIR}/#{paths.take(i).join('/')}/#{p}")
        end
      end
    end
  end

  # Creates path if it doesn't exist
  #
  # @param opts [String] path the path of directory
  def self.sftp_create_path(path)
    unless sftp_path_exists?(path)
      log.progress("Creating directory: #{path}", nil)
      sftp.mkdir!(path)
    end
  end

  # Removes files from path if older than upload time
  #
  # @param opts [String] path the path of directory
  def self.sftp_clean_path(path)
   sftp.dir.foreach(path) do |f|
      if !File.extname("#{path}/#{f.name}").empty? && f.attributes.mtime < UPLOAD_TIME
        sftp_remove_path("#{path}/#{f.name}")
      end
    end
  end

  # Checks if the path exists
  #
  # @param opts [String] path the path of directory
  # @return [Boolean] returns boolean of result
  def self.sftp_path_exists?(path)
      sftp.stat!(path)
    rescue Net::SFTP::StatusException
      return false
    else
      return true
  end

  # Removes file
  #
  # @param opts [String] path the path of file
  def self.sftp_remove_path(path)
    log.progress("Removing existing file: #{path}", nil)
    sftp.remove!(path)
  end

  # Splits path
  #
  # @param opts [String] path the path of file
  # @return [Array] returns array of file path
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
  BASE_DIR    = OPTS['yard-sftp']['base_path'] + '/' + OPTS['yard-sftp']['base_folder']
  UPLOAD_TIME = Time.now.to_i
end