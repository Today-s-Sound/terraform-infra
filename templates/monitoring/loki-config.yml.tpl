auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

storage_config:
  aws:
    s3: s3://${aws_region}/${s3_logs_bucket_name}/loki
    s3forcepathstyle: true
  tsdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/index_cache

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
