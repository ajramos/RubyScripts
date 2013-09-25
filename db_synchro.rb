#!/usr/bin/ruby

# = db_synchro.rb
#
# Author:: ajramos
#
# == Description
# * Download a mysql db bulk file from a bucket in AWS S3 and fetched into the target database
#
# === Usage:
#
# Fill up the configuration data at the variables:
#
# - S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY: AWS S3 API credentials.
# - bucket_name: name of the bucket where downloading the sql file from.
# - s3_bkp_path: directory in bucket where downloading the sql file from.
# - hostname, db, user, passwd : credentials for database
# - bkp_path: directory where the backup is going to be download
# - filename: name of the backup file to be downloaded

require 'rubygems'
require 'aws-sdk'

s3 = AWS::S3.new(
    :c => 'S3_ACCESS_KEY_ID',
    :secret_access_key => 'S3_SECRET_ACCESS_KEY')

hostname = 'localhost'
db = 'database_name'
user = 'database_user'
passwd = 'database_password'
bucket_name = 'bucket_name'
bkp_path= '/tmp'
s3_bkp_path='bkp/db'
today = Time.new.strftime('%Y%m%d')
filename = "database_pro_db.#{today}.sql"


bkp_path += "/#{filename}"
mysql_cmd = "mysql -h #{hostname} -u #{user} -p#{passwd} #{db} < #{bkp_path}"

puts 'Starting...'

bucket = s3.buckets[bucket_name] # no request made

db_bkp_obj = bucket.objects["#{s3_bkp_path}/#{filename}"]

if (db_bkp_obj.exists?)
  puts "BackUp found: #{db_bkp_obj.key}"
  unless (File.exists?("#{bkp_path}"))
    puts 'Download...'
    open("#{bkp_path}", 'w') do |file|
      file.write db_bkp_obj.read
    end
    puts 'Download Finished'
  else
    puts 'File already downloaded, if you would like to download again, remove the file and run this script over again'
  end
end

puts 'Updating DB...'
system(mysql_cmd)
puts mysql_cmd
puts 'DB updated'

puts 'Housekeeping...'

del_command = "rm #{bkp_path}"
system(del_command)
puts 'END'
