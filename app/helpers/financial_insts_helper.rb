module FinancialInstsHelper

  def fi_homepage_link(fi)
    if fi && !fi.homepage_url.to_s.blank?
      link_to(fi.homepage_url, fi.homepage_url, :target => "new")
    else
      "your bank's website"
    end
  end

end
