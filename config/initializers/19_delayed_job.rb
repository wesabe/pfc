# don't delete failed jobs
Delayed::Worker.destroy_failed_jobs = false
# low max attempts, since if it fails, it likely won't ever work
Delayed::Worker.max_attempts = 2