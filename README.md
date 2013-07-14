# yard-sftp

Move your new shiny yard documentation to a remote location with SFTP!

## Getting Started

In order to move your yard documentation to a remote location using SFTP you need to setup a local `.yardsftp` config file in your projects base directory. Please see the example below:

    --- !ruby/hash:SymbolHash
    :yard-sftp:
     host: 'example.com'
     base_path: '/home/public_html'
     base_folder: 'project_one/'
     username: 'username'
     password: 'password'
     
Once this is all setup hit `yard` at your command line as you normally would and each file will uploaded via SFTP as they are created. Please note that both the `.yardopts` and `doc` directories are uploaded!

### `.yardsftp` config file? Why?
I've added a new `.yardsftp` so different projects can be uploaded to custom remote locations. I did attempt to add these to the global `.yard/config` file but there was no way to distinguish custom remote file paths between different projects! Please email if you have a good suggestion!

## Tests
There are a no tests at present, this project was a proof of concept but these will be done at some point.

## Feedback
I would be more than happy to recieve feedback, please email me at: jonathan.chrisp@gmail.com
