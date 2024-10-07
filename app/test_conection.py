from rediscluster import RedisCluster
import redis
import logging



redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", 6379))
redis_password = os.getenv("REDIS_PASSWORD")
redis_user     = os.getenv("REDIS_USER", "curly")


print("Testing Redis connection...")
logging.info("Testing Redis connection...")
# Redis connection details
redis_host = redis_host
redis_port = 6379
redis_password = redis_password
redis_tls_ca_cert = '/app/AmazonRootCA1.pem'
redis_user = redis_user
# Create SSL context
# ssl_context = ssl.create_default_context(cafile=redis_tls_ca_cert)

# Connect to Redis with TLS enabled and IAM authentication
#redis_client = redis.Redis(host=redis_host, port=redis_port, password=redis_password, username=redis_user, ssl=True, ssl_context=ssl_context, ssl_cert_reqs=ssl.CERT_REQUIRED, ssl_ca_certs=redis_tls_ca_cert)

try:
    redis = RedisCluster(
        #host="127.0.0.1",
        startup_nodes=[{"host": redis_host ,"port": "6379"}],
        port=6379,
        password=redis_password,
        username="curly",
        skip_full_coverage_check=True,
        decode_responses=True,
        ssl=True,
        ssl_cert_reqs=None  # Adjust as needed for your TLS configuration
    )
    
    redis.ping()
    logging.info("Redis connection successful!")
except redis.exceptions.ConnectionError:
    logging.info("Failed to connect to Redis.")