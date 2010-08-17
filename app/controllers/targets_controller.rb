class TargetsController < ApplicationController
  before_filter :check_authentication
  layout nil

  # show all targets for this user
  def index
    # get all the targets and order them by tag_name
    @targets = current_user.targets.find(:all, :order=> "tag_name")
    # allow a period to be specified with start_date & end_date
    @period = nil
    if params[:start_date] && params[:end_date]
      @period = Time.parse(params[:start_date]).beginning_of_day..Time.parse(params[:end_date]).end_of_day
    end
    @targets.each { |target| target.calculate!(current_user, @period) }

    respond_to do |format|
      format.xml { render :layout => false } # index.xml.builder
      format.json { render :json => @targets.map {|t| present(t) } }
    end
  end

  # show the target for a single tag
  def show
    if target
      target.calculate!(current_user)
    end

    respond_to do |format|
      format.xml { render :layout => false } # show.xml.builder
    end
  end

  def create
    tag = Tag.find_or_create_by_name(params[:tag])
    amount = Currency.normalize(params[:amount])

    if tag && amount
      @target = Target.for_tag(tag, current_user)
      @target ||= Target.create(:tag => tag, :tag_name => tag.user_name, :amount_per_month => amount, :user => current_user)
    end

    if @target
      render :json => present(@target)
    else
      render :json => {}, :status => :bad_request
    end
  end

  def update
    if amount = Currency.normalize(params[:amount])
      target.amount_per_month = amount
      target.save
    end

    respond_to do |format|
      format.json { render :json => present(target) }
    end
  end

  def destroy
    target.destroy

    respond_to do |format|
      format.json { render :json => "TIIIIIMMM!!!" }
    end
  end

  private

  def target
    @target ||= Target.for_tag(tag, current_user) || raise(ActiveRecord::RecordNotFound)
  end

  def tag
    @tag ||= Tag.find_by_name(params[:id] || params[:tag])
  end
end
