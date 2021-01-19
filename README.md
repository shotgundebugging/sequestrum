Run concurrent requests from a file using Sidekiq

# Usage
```
redis-server
rackup
sidekiq -r ./sequestrum.rb test.urls GET
```
