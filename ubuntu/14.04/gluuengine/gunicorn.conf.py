import multiprocessing

bind = ":8000"
workers = multiprocessing.cpu_count() * 2 + 1
threads = workers
worker_class = 'gthread'
loglevel = 'warning'
accesslog = '-'
errorlog = '-'
raw_env = 'API_ENV=prod' # 'prod|test|dev'
