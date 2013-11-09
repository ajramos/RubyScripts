#!/usr/bin/ruby
# encoding: utf-8
# Author:: ajramos
#
# == Description
# * Backups a mysql db into a bulk file and upload to a bucket in AWS S3
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
require 'aws'

s3 = AWS::S3.new(
  access_key_id: 'S3_ACCESS_KEY_ID',
  secret_access_key: 'S3_SECRET_ACCESS_KEY')
bucket_name = 'evomote'
hostname = 'localhost'
db = 'database'
user = 'user'
passwd = 'password'
bkp_path = '/tmp'
s3_bkp_path = 'bkp/db'
command = "mysqldump -h #{hostname} -u #{user} -p#{passwd} #{db}"
today = Time.new.strftime('%Y%m%d')
filename = "database_pro_db.#{today}.sql"

bkp_path += "/#{filename}"
command += " > #{bkp_path}"

system(command)

bucket = s3.buckets[bucket_name] # no request made

db_bkp_obj = bucket.objects["#{s3_bkp_path}/#{filename}"]

db_bkp_obj.write(Pathname.new(bkp_path))

del_command = "rm #{bkp_path}"
system(del_command)
