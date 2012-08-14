
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite::memory:')