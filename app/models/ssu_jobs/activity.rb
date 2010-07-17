class SsuJobs::Activity
  attr_accessor :start_date
  attr_accessor :end_date
  attr_accessor :wesabe_id
  attr_accessor :resolution

  class SsuJobs::Activity::Maths
    def self.percent(a,b)
      return 0 if a == 0
      return 0 if b == 0
      return (1-((a - b).to_f / a.to_f))*100
    end

    def self.average(set)
      return set.inject(0) {|sum,n| sum + n} /set.size.to_f
    end

    def self.std_dev(set,avg)
      return Math.sqrt(set.inject(0) {|dev,n| dev += (n - avg) ** 2 }/set.size.to_f)
    end
  end

  class SsuJobs::Activity::UberStats
    attr_accessor :sum_jobs
    attr_accessor :sum_okay, :sum_fail, :sum_auth, :sum_pending
    attr_accessor :pct_okay, :pct_fail, :pct_auth, :pct_pending

    def initialize
      @sum_jobs    = 0
      @sum_okay    = 0
      @sum_fail    = 0
      @sum_auth    = 0
      @sum_pending = 0
      @pct_okay    = 0
      @pct_fail    = 0
      @pct_auth    = 0
      @pct_pending = 0
    end

    def summarize!(inst_stats)
      return false if inst_stats.nil?

      inst_stats.each do
        |inst|
        @sum_okay    += inst.sum_okay
        @sum_fail    += inst.sum_fail
        @sum_auth    += inst.sum_auth
        @sum_pending += inst.sum_pending
      end

      @sum_jobs     = @sum_okay + @sum_auth + @sum_fail + @sum_pending
      @pct_okay     = SsuJobs::Activity::Maths::percent(@sum_jobs, @sum_okay)
      @pct_fail     = SsuJobs::Activity::Maths::percent(@sum_jobs, @sum_fail)
      @pct_auth     = SsuJobs::Activity::Maths::percent(@sum_jobs, @sum_auth)
      @pct_pending  = SsuJobs::Activity::Maths::percent(@sum_jobs, @sum_pending)
      return true
    end
  end

  class SsuJobs::Activity::InstStats
    attr_reader   :id, :name
    attr_accessor :slot_stats

    attr_accessor :sum_jobs
    attr_accessor :sum_okay, :sum_fail, :sum_auth, :sum_pending
    attr_accessor :pct_okay, :pct_fail, :pct_auth, :pct_pending
    attr_accessor :avg_okay, :avg_fail, :avg_auth, :avg_pending
    attr_accessor :sdv_okay, :sdv_fail, :sdv_auth, :sdv_pending

    def initialize(id, name)
      @id   = id
      @name = name
      @sum_jobs    = 0
      @sum_okay    = 0
      @sum_fail    = 0
      @sum_auth    = 0
      @sum_pending = 0
      @pct_okay    = 0.0
      @pct_fail    = 0.0
      @pct_auth    = 0.0
      @pct_pending = 0.0
      @avg_okay    = 0.0
      @avg_fail    = 0.0
      @avg_pending = 0.0
      @sdv_okay    = 0.0
      @sdv_fail    = 0.0
      @sdv_auth    = 0.0
      @sdv_pending = 0.0
    end

    def self.zero
      new(nil, nil)
    end

    def summarize!
      fails    = Array.new
      okays    = Array.new
      auths    = Array.new
      pendings = Array.new

      @slot_stats.each do |slot|
        ## add up each node in the provided range
        @sum_okay    += slot.sum_okay
        @sum_fail    += slot.sum_fail
        @sum_auth    += slot.sum_auth
        @sum_pending += slot.sum_pending

        ## used for average and stddev
        fails    << slot.sum_fail
        okays    << slot.sum_okay
        auths    << slot.sum_auth
        pendings << slot.sum_pending
      end

      @sum_jobs += @sum_okay + @sum_fail + @sum_auth + @sum_pending

      ## calculate percent of total jobs
      @pct_okay    = SsuJobs::Activity::Maths.percent(@sum_jobs, @sum_okay)
      @pct_fail    = SsuJobs::Activity::Maths.percent(@sum_jobs, @sum_fail)
      @pct_auth    = SsuJobs::Activity::Maths.percent(@sum_jobs, @sum_auth)
      @pct_pending = SsuJobs::Activity::Maths.percent(@sum_jobs, @sum_pending)

      ## calculate averages
      @avg_okay    = SsuJobs::Activity::Maths.average(okays)
      @avg_fail    = SsuJobs::Activity::Maths.average(fails)
      @avg_auth    = SsuJobs::Activity::Maths.average(auths)
      @avg_pending = SsuJobs::Activity::Maths.average(pendings)

      ## calculate standard deviations
      @sdv_okay    = SsuJobs::Activity::Maths.std_dev(okays, @avg_okay)
      @sdv_fail    = SsuJobs::Activity::Maths.std_dev(fails, @avg_fail)
      @sdv_auth    = SsuJobs::Activity::Maths.std_dev(auths, @avg_auth)
      @sdv_pending = SsuJobs::Activity::Maths.std_dev(pendings, @avg_pending)

      return true
    end

    def to_a
      return [
        @name,     @id,
        @sum_okay, @sum_fail, @sum_auth, @sum_pending,
        @pct_okay, @pct_fail, @pct_auth, @pct_pending,
        @avg_okay, @avg_fail, @avg_auth, @avg_pending,
        @sdv_okay, @sdv_fail, @sdv_auth, @sdv_pending
      ]
    end

    def to_param
      id.to_s
    end
  end

  class SsuJobs::Activity::SlotStats
    attr_accessor :slot
    attr_accessor :sum_okay, :sum_fail, :sum_auth, :sum_pending

    def initialize(slot)
      @slot        = slot
      @sum_okay    = 0
      @sum_fail    = 0
      @sum_auth    = 0
      @sum_pending = 0
    end

    def sum_jobs
      return @sum_okay + @sum_fail + @sum_auth + @sum_pending
    end

    def to_a
      return [@slot, @sum_okay, @sum_fail, @sum_auth, @sum_pending]
    end
  end




  def initialize(start_date=nil, end_date=nil, resolution=nil)
    @start_date = start_date || Time.now.beginning_of_day
    @end_date   = end_date   || Time.now
    @resolution = resolution || 86400
    @ssu_jobs       = Array.new
    @ssu_jobs_by_id = Hash.new
    @map_id_to_inst = Hash.new
  end

  def summarize!
    ## within some bounds don't do nonsensical things
    return false if @end_date   <= @start_date
    return false if @resolution <= 0
    __collect_ssu_jobs()
    __process_ssu_jobs()
    return true
  end

  def get_stats_for_all
    uber = SsuJobs::Activity::UberStats.new
    uber.summarize!(@map_id_to_inst.values)
    return [uber, @map_id_to_inst.values]
  end

  def get_stats_for_wesabe_id(inst_id)
    return @map_id_to_inst[inst_id]
  end

  private
  def __collect_ssu_jobs
    cc = ConditionsConstructor.new
    cc.add("ssu_jobs.account_cred_id = account_creds.id")
    cc.add("account_creds.financial_inst_id = financial_insts.id")
    cc.add(['ssu_jobs.created_at >= ? AND ssu_jobs.created_at <= ?', @start_date, @end_date])

    ## limit by wesabe-id in some cases, whee!
    cc.add(['financial_insts.wesabe_id = ?', @wesabe_id]) if @wesabe_id

    cond_str   = SsuJob.send(:sanitize_sql_for_conditions, cc.conditions)
    result_set = SsuJob.connection.execute(%{
      SELECT
        financial_insts.wesabe_id,
        financial_insts.name,
        UNIX_TIMESTAMP(ssu_jobs.created_at),
        ssu_jobs.status
      FROM ssu_jobs, account_creds, financial_insts
      WHERE #{cond_str}
      ORDER BY ssu_jobs.created_at ASC
    })

    result_set.each do |row|
      @ssu_jobs << {
        :wesabe_id  => row[0],
        :name       => row[1],
        :created_at => row[2],
        :status     => row[3]
      }
    end
  end

  def __process_ssu_jobs
    ## FIXME: Move this into initialize, or?
    ## calculate a starting date, we always start at 00:00:00
    sd = @start_date
    ed = @end_date
    origin = sd.beginning_of_day.to_i - @resolution
    dest   = (ed.end_of_day.to_i - origin) / @resolution

    ## calculate the available time slots!
    slots = (1..dest).map{|s| origin + s * @resolution}

    ## iterate, you know, over all the jobs!
    @ssu_jobs.each do |ssu_job|
      inst_id = ssu_job[:wesabe_id]
      time_t  = ssu_job[:created_at].to_i

      ##  initialize index -> id :: time_t :: slot
      unless @ssu_jobs_by_id.has_key?(inst_id)
        @ssu_jobs_by_id[inst_id] = Hash.new
        @map_id_to_inst[inst_id] =
          SsuJobs::Activity::InstStats.new(inst_id, ssu_job[:name])

        slots.each do |slot|
          @ssu_jobs_by_id[inst_id][slot] = SsuJobs::Activity::SlotStats.new(slot)
        end
      end

      ## calculate the time_t slot for this result: the input set is assumed
      ## to be in ascending order.  the copied table is also ascending so we
      ## can minimzie iteration be shifting done dates off of the table
      dslots = slots.clone
      while dslots.length > 1
        dslots.shift if time_t >= dslots[1]
        break        if dslots.length == 1 || time_t < dslots[1]
      end
      slot = dslots[0]

      slot_stat = @ssu_jobs_by_id[inst_id][slot]
      case ssu_job[:status]
      when '200'    then slot_stat.sum_okay    += 1
      when '202'    then slot_stat.sum_pending += 1
      when /4\d{2}/ then slot_stat.sum_auth    += 1
      when /5\d{2}/ then slot_stat.sum_fail    += 1
      end
    end # of ssu_jobs.each

    ## take all of the slot_stats we've collected and stash them neatly
    ## away in their respective InstStats containers.
    @map_id_to_inst.each_pair do |inst_id, inst|
      inst.slot_stats = @ssu_jobs_by_id[inst_id].values
      inst.summarize!
    end

    ## let's just go ahead and throw away the data we don't need.
    @ssu_jobs       = nil
    @ssu_jobs_by_id = nil
    return true
  end

end
