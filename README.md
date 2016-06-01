# Zuora Coding challenge
* The current solution can sustain failures and doesnot regenerate counter from start on failure
* Also if a user belongs to more than one accounts, those events are flagged
* I tested this using ruby-2.3.0 on a ubuntu 14.04 ASW instance with 2 GB RAM [ x86_64 ]

##Install
* Install rvm
  * \curl -sSL https://get.rvm.io | bash -s stable --ruby
  * gem install bundler
  * bundle install

##Build
These are the steps that need be run successfully before running the script
* rake db:clean
* rake db:migrate

##Run
* ruby event_stream.rb {input-file} {is_retry?}
  * input-file should be absolute path
  * is_retry? should be either true/false and is false by default.

##Notes
* Used Sqlite3 as datastore to store user and account information and also to cache events for which identification messages are not yet received.
* Maintained processing_state file which contains the position in the file after a chunk is processed.
* Also stored counter values in a file after a chunk is processed, so that if the process fails or if database dies, whole process need not be restarted.
