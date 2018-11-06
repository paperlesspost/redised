require 'helper'

class TestRedised < Test::Unit::TestCase

  class RedisedClass
    include Redised

    redised_namespace 'mynamespace'
  end

  class OtherRedisedClass
    include Redised
  end

  context "Redised" do
    setup do
      @env_config_path = File.join(File.dirname(__FILE__), 'env_redised_config.yml')
    end

    should "be able to assign the redised_config_path" do
      Redised.redised_config_path = @env_config_path
      assert_equal @env_config_path, Redised.redised_config_path
      assert Redised.redised_config['mynamespace']
    end

    should "pull default env from ENV" do
      ENV['RAILS_ENV'] = 'production'
      assert_equal 'production', Redised.redised_env
    end

    should "allow for setting the env" do
      Redised.redised_env = 'dev'
      assert_equal 'dev', Redised.redised_env
    end

    should "have class level redis connection" do
      Redised.redised_config_path = @env_config_path
      Redised.redised_env = 'production'
      redis = RedisedClass.redis
      assert_kind_of Redis::Namespace, redis
    end

    should "parse redis connection with namespace" do
      RedisedClass.redis = 'localhost:5678:0/namespace'
      redis = RedisedClass.redis
      assert_equal 'localhost', redis.client.host
      assert_equal 5678, redis.client.port
      assert_equal 0, redis.client.db
      assert_equal 'namespace', redis.namespace
    end

    should "parse redis connection with database and password" do
      RedisedClass.redis = 'localhost:5678:2:mypass/namespace'
      redis = RedisedClass.redis
      assert_equal 'localhost', redis.client.host
      assert_equal 5678, redis.client.port
      assert_equal 2, redis.client.db
      assert_equal 'mypass', redis.client.password
      assert_equal 'namespace', redis.namespace
      assert_equal 5.0, redis.client.timeout
    end

    should "use redis_options" do
      Redised.redis_options = {:timeout => 1.0}
      RedisedClass.redis = 'localhost:5678:2:mypass/namespace'
      redis = RedisedClass.redis
      assert_equal 'localhost', redis.client.host
      assert_equal 5678, redis.client.port
      assert_equal 2, redis.client.db
      assert_equal 'mypass', redis.client.password
      assert_equal 'namespace', redis.namespace
      assert_equal 1.0, redis.client.timeout
    end

    context 'use ENV string for URL' do
      setup do
        RedisedClass.redis = nil
        @env_config_path = File.join(File.dirname(__FILE__), 'env_redised_config.yml')
      end

      should 'process ERB in config YAML file' do
        ENV['REDIS_CONNSTRING'] = '127.0.0.1:5678:2:mypassw/namespace'
        Redised.redised_config_path = @env_config_path
        Redised.redised_env = 'fromenv'
        redis = RedisedClass.redis
        assert_equal '127.0.0.1', redis.client.host
        assert_equal 5678, redis.client.port
        assert_equal 2, redis.client.db
        assert_equal 'mypassw', redis.client.password
        assert_equal 'namespace', redis.namespace

      end
    end
  end

end
