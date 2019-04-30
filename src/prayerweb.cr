require "kemal"
require "./prayer.cr"

get "/" do |env|
    
    render "src/views/hello.ecr"
end
get "/gettimes/:year/:month/:day/:lat/:lng/:tz/:method" do |env|
    year = env.params.url["year"]
    month = env.params.url["month"]
    day = env.params.url["day"]
    lat = env.params.url["lat"]
    lng = env.params.url["lng"]
    tz = env.params.url["tz"]
    method = env.params.url["method"]
    a = Prayer.new
    env.response.content_type = "application/json"
    a.getDatePrayerTimes(year.to_i32, month.to_i32, day.to_i32, lat.to_f64 ,lng.to_f64, tz.to_i32, method)
    # puts a.correctionForTimes([-5,-5,-1,-1,6,6,0])
end
  

Kemal.run
