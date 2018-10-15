# Patch a rails db:migrate issue which associates with 
# Mysql2::Error: All parts of a PRIMARY KEY must be NOT NULL;

class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end