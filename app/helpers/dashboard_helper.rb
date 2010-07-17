module DashboardHelper
  DEFAULT_CHARTS = %w[spending-targets chart-sve chart-pie]
  PARTIALS_BY_CHART = {"spending-targets" => "targets/widget", "chart-sve" => "charts/sve", "chart-pie" => "charts/pie"}

  def dashboard_charts
    charts = current_user.preferences.read('charts.order')
    charts = charts ? charts.split(',') : DEFAULT_CHARTS

    # remove any invalid charts
    charts &= PARTIALS_BY_CHART.keys

    # use the default set if the user would have none
    charts = DEFAULT_CHARTS if (charts & PARTIALS_BY_CHART.keys).empty?

    return charts.map {|chart| render :partial => PARTIALS_BY_CHART[chart]}.join.html_safe
  end
end
