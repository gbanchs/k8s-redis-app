import os
from rediscluster import RedisCluster
from typing import Optional
from fastapi import Depends, FastAPI, HTTPException
#from redis import Redis
from redis.exceptions import AuthenticationError
from pydantic import BaseModel
import uvicorn
import logging

app = FastAPI()

# Get Redis credentials from environment variables

redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", 6379))
redis_password = os.getenv("REDIS_PASSWORD")
redis_user     = os.getenv("REDIS_USER", "curly")

# Connect to Redis
#r = Redis(host=redis_host, port=redis_port, password=redis_password, db=0)
r = RedisCluster(
        #host="127.0.0.1",
        startup_nodes=[{"host": redis_host ,"port": "6379"}],
        port=6379,       
        username="",
        skip_full_coverage_check=True,
        decode_responses=True,
        ssl=True,
        ssl_cert_reqs=None  # Adjust as needed for your TLS configuration
    )
#r = Redis(host=redis_host, port=6379, decode_responses=True, ssl=True, username=redis_user, password=redis_password)

# if r.ping():
#     logging.info("Connected to Redis")
    
# Define the counter key
COUNTER_KEY = "counter"

class Counter(BaseModel):
    counter: int

@app.get("/read")
def read_counter():
    """Read the current counter value from Redis."""
    try:
        value = r.get(COUNTER_KEY)
        # Return 0 if the key doesn't exist
        value = int(value) if value else 0
        return Counter(counter=value)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/write")
def write_counter():
    """Increment the counter value in Redis."""
    try:
        value = r.incr(COUNTER_KEY)
        return Counter(counter=value)
    except AuthenticationError:
        raise HTTPException(status_code=401, detail="Unauthorized")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/healthz")
def health():
    """Health check endpoint for Kubernetes."""
    return {"status": "ok"}
    
    
    
    
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
