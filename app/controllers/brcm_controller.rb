# REVIEW: Make this not ugly, or replace it with something which isn't a hideous hack.
require 'exporter/txaction/csv'
require 'exporter/txaction/xls'

# A simple pass-through controller for brcm-accounts-api.
class BrcmController < ApplicationController
  before_filter :check_authentication

  def passthrough
    res = brcm.request(request.method, request.fullpath.sub(%r{^/data}, ""), params) do |req|
      req.user = current_user
      req.headers["Accept-Language"] = request.headers["HTTP_ACCEPT_LANGUAGE"]
      req.headers["Accept"] = request.headers["HTTP_ACCEPT"]
    end

    assert_valid_response(res)

     render(:text => res.body, :content_type => res.content_type, :status => res.code)
  end

  def transactions
    res = brcm.request(request.method, request.fullpath.sub(%r{^/data}, ""), params) do |req|
      req.user = current_user
      req.headers["Accept-Language"] = request.headers["HTTP_ACCEPT_LANGUAGE"]
      req.headers["Accept"] = (params[:format] == 'xml') ? 'application/xml' : 'application/json'
    end

    assert_valid_response(res)

    # extract tag name if that's one of the params
    tag = params[:tag].gsub(%r{^/tags/},'') if params[:tag] # param comes to us as "/tags/<tag>"

    respond_to do |format|
      format.json { render :text => res.body, :content_type => res.content_type, :status => res.code }
      format.xml  { render :text => res.body, :content_type => res.content_type, :status => res.code }
      format.csv  {
        exporter = Exporter::Txaction::Csv.new(current_user, res.body, :tag => tag)
        exporter.render(self, "wesabe-transactions.csv")
      }
      format.xls {
        exporter = Exporter::Txaction::Xls.new(current_user, res.body, :tag => tag)
        exporter.render(self, "wesabe-transactions.xls")
      }
      format.any  { render :text => res.body, :content_type => res.content_type, :status => res.code }
    end
  end

  private

  def brcm
    Service.get(:brcm)
  end

  def assert_valid_response(res)
    if res.nil?
      raise "BRCM sucked at life: request to #{request.fullpath} received no response"
    elsif res.code >= 400
      raise "BRCM sucked at life: request to #{request.fullpath} received #{res.code} response:\n\n#{res.headers}\n\n#{res.body}"
    end
  end
end