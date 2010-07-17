class FinancialInstsController < ApplicationController
  before_filter :check_authentication
  before_filter :check_for_admin, :only => [:edit, :update, :destroy, :unapproved, :confirm_merge, :merge]

  # GET /financial-institutions
  # GET /financial-institutions.xml
  # GET /financial_insts/list?format=xml
  def index
    @financial_insts = FinancialInst.for_user(current_user).order('name ASC')
    respond_to do |format|
      format.html { check_for_admin }     # index.html.erb    ## admin-only. stupid stupid stupid
      format.xml  { render :layout => false } # index.xml.builder
      format.json { render :layout => false } # index.json.erb
    end
  end

  # GET /financial-institutions/unapproved
  def unapproved
    @financial_insts = FinancialInst.paginated_find_all_unapproved(params[:page], :per_page => 1000)
  end

  # GET /financial-institutions/new
  def new
    get_countries
    @financial_inst = FinancialInst.new(:name => params[:name], :country_id => current_user.country_id)
  end

  # POST /financial-institutions
  def create
    # only allow users to set name, homepage_url, and country
    fi_params = (params[:financial_inst] || {}).slice(:name, :homepage_url, :country_id)
    @financial_inst = FinancialInst.new(fi_params.update(:creating_user_id => current_user.id, :approved => false))
    if @financial_inst.save
      # continue on with the upload process
      flash[:fi_confirmation] = "Your financial institution has been added."
      redirect_to manual_uploads_path(:fi => @financial_inst)
    else
      get_countries
      render :action => "new"
    end
  end

  # GET /financial-institutions/1/edit
  # GET /financial-institutions/us-000238/edit
  def edit
    @financial_inst = FinancialInst.find_for_user(params[:id], current_user) || raise(ActiveRecord::RecordNotFound)
  end

  # PUT /financial-institutions/1
  # PUT /financial-institutions/us-000238
  def update
    @financial_inst = FinancialInst.find_for_user(params[:id], current_user) || raise(ActiveRecord::RecordNotFound)
    if @financial_inst.update_attributes(params[:financial_inst])
      redirect_to(financial_inst_url(@financial_inst))
    else
      render :action => "edit"
    end
  end

  # GET /financial-institutions/1
  # GET /financial-institutions/us-000238
  # GET /financial-institutions/1.xml
  # GET /financial_insts/1?format=xml
  def show
    @financial_inst = FinancialInst.find_for_user(params[:id], @user || current_user) || raise(ActiveRecord::RecordNotFound)

    respond_to do |format|
      format.html {
        raise(ActiveRecord::RecordNotFound) unless check_for_admin
        generate_fi_stats; render :action => 'show' # show.html.erb
      }
      format.xml { render :xml => @financial_inst }
    end
  end


  def generate_fi_stats
    @recent_jobs    = @financial_inst.
                        all_ssu_jobs.
                        latest(10).
                        map(&:presenter)
    @recent_signups = @financial_inst.
                        all_ssu_jobs.
                        signups.
                        limit(10).
                        order('created_at DESC').
                        map(&:presenter)

    ## FIXME: This is really inefficient, need to add a real by_fi filter
    activity_30d = SsuJobs::Activity.new(30.days.ago, Time.now)
    activity_30d.wesabe_id = @financial_inst.wesabe_id
    activity_30d.summarize!()
    @fi_stats_30d = activity_30d.get_stats_for_wesabe_id(@financial_inst.wesabe_id)
    return unless @fi_stats_30d

    @fi_okay = []
    @fi_fail = []
    @fi_auth = []
    @fi_pend = []
    @fi_all  = []

    ## FIXME: Sorting shouldn't happen here!
    @fi_stats_30d.slot_stats.sort_by {|_| _.slot }.each do |slot_stat|
      @fi_okay << [slot_stat.slot*1000, slot_stat.sum_okay]
      @fi_fail << [slot_stat.slot*1000, slot_stat.sum_fail]
      @fi_auth << [slot_stat.slot*1000, slot_stat.sum_auth]
      @fi_pend << [slot_stat.slot*1000, slot_stat.sum_pending]
      @fi_all  << [slot_stat.slot*1000, slot_stat.sum_jobs]
    end

    activity_07d = SsuJobs::Activity.new(
      Chronic.parse('7 days ago'),
      Chronic.parse('today')
    )
    activity_07d.wesabe_id = @financial_inst.wesabe_id
    activity_07d.summarize!
    @fi_stats_07d = activity_07d.get_stats_for_wesabe_id(@financial_inst.wesabe_id)
  end
  hide_action :generate_fi_stats

  # DELETE /financial-institutions/1
  # DELETE /financial-institutions/us-000238
  def destroy
    @financial_inst = FinancialInst.find_for_user(params[:id], current_user) || raise(ActiveRecord::RecordNotFound)
    if @financial_inst.destroy
      redirect_to unapproved_financial_insts_url
    else
      render :action => "destroy"
    end
  end

  # GET /financial-institutions/:id/confirm_merge
  def confirm_merge
    @financial_inst = FinancialInst.find_by_wesabe_id(params[:id])
    @target_fi = FinancialInst.find(params[:target_fi_id])
    redirect_to financial_insts_url unless @financial_inst && @target_fi
  end

  # POST /financial-institutions/:id/merge
  def merge
    @financial_inst = FinancialInst.find_by_wesabe_id(params[:id])
    @target_fi = FinancialInst.find(params[:target_fi_id])
    @financial_inst.mapped_to_id = @target_fi.id
    FinancialInst.merge(@financial_inst.id, @financial_inst.mapped_to_id)
    redirect_to(financial_inst_url(@target_fi))
  end

private

  # Retrieves a list of countries for the select box on #new and #create.
  def get_countries
    @countries = Country.ids_and_names
  end

  def check_authentication
    if params[:job_guid]
      job = SsuJob.find_by_job_guid(params[:job_guid])
      if job && !job.expired? && (@user = User.find_by_id(params[:user_id]))
        return true
      else
        render :nothing => true, :status => 401
      end
    else
      super
    end
  end

end
