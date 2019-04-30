require "json"

class Prayer
  @methods = {
    "Jafari"  => [16.0, 0.0, 4.0, 0.0, 14.0],
    "Karachi" => [18.0, 1.0, 0.0, 0.0, 18.0],
    "ISNA"    => [15.0, 1.0, 0.0, 0.0, 15.0],
    "MWL"     => [18.0, 1.0, 0.0, 0.0, 17.0],
    "Makkah"  => [18.5, 1.0, 0.0, 1.0, 90.0],
    "Egypt"   => [19.5, 1.0, 0.0, 0.0, 17.5],
    "Tehran"  => [17.7, 0.0, 4.5, 0.0, 14.0],
    "Custom"  => [18.0, 1.0, 0.0, 0.0, 17.0],
  }
  @timeNames = {
    "fajr"    => "",
    "sunrise" => "",
    "dhuhr"   => "",
    "asr"     => "",
    "sunset"  => "",
    "maghrib" => "",
    "isha"    => "",
  }

  @calcMethod = "MWL" # caculation method
  @asrJuristic = 0    # Juristic method for Asr
  @dhuhrMinutes = 0   # minutes after mid-day for Dhuhr
  @adjustHighLats = 1 # adjusting method for higher latitudes

  @timeFormat = 0 # time format

  @lat = 0.0    # latitude
  @lng = 0.0    # longitude
  @timeZone = 0 # time-zone
  @jdate = 0.0  # Julian date

  def sin(d)
    return Math.sin((d) * Math::PI / 180)
  end

  def cos(d)
    return Math.cos((d) * Math::PI / 180)
  end

  def tan(d)
    return Math.tan((d) * Math::PI / 180)
  end

  def arcsin(x)
    return ((Math.asin(x)*180.0) / Math::PI)
  end

  def arccos(x)
    return ((Math.acos(x)*180.0) / Math::PI)
  end

  def arctan(x)
    return ((Math.atan(x)*180.0) / Math::PI)
  end

  def arccot(x)
    return ((Math.atan(1.0/x)*180.0) / Math::PI)
  end

  def arctan2(y, x)
    return ((Math.atan2(y, x)*180.0) / Math::PI)
  end

  def fixangle(a)
    a = a - 360.0 * (a / 360.0).floor
    a = a < 0 ? a + 360.0 : a
    return a
  end

  # def fixangle(angle) return fix(angle, 360.0) end
  def fixhour(hour)
    hour = hour - 24.0 * (hour / 24.0).floor

    hour = hour < 0 ? hour + 24.0 : hour

    return hour
  end

  def floatToTime24(time)
    time = self.fixhour(time + 0.5/60)
    hours = (time).floor
    minutes = ((time - hours)*60).floor
    return "#{self.twoDigitsFormat(hours)}:#{self.twoDigitsFormat(minutes)}"
  end

  def twoDigitsFormat(num)
    return (num < 10) ? "0#{num.to_i32}" : "#{num.to_i32}"
  end

  def julian(year, month, day)
    if month <= 2
      year -= 1
      month += 12
    end
    a = (year / 100).floor
    b = 2 - a + (a / 4).floor
    return (365.25 * (year + 4716)).floor + (30.6001 * (month + 1)).floor + day + b - 1524.5
  end

  def sunPosition(jd)
    d = jd - 2451545.0
    g = self.fixangle(357.529 + 0.98560028*d)
    q = self.fixangle(280.459 + 0.98564736*d)
    l = self.fixangle(q + 1.915*self.sin(g) + 0.020*self.sin(2*g))

    r = 1.00014 - 0.01671*self.cos(g) - 0.00014*self.cos(2*g)
    e = 23.439 - 0.00000036*d

    ra = self.arctan2(self.cos(e)*self.sin(l), self.cos(l))/15.0
    eqt = q/15.0 - self.fixhour(ra)
    decl = self.arcsin(self.sin(e)*self.sin(l))

    return [decl, eqt]
  end

  def dayPortion(times)
    timearray = [] of Float64
    times.map do |time|
      timearray << time / 24.0
    end
    return timearray
  end

  def computeTimes(times)
    t = self.dayPortion(times)
    fajr = self.computeTime(180 - @methods[@calcMethod][0], t[0])
    sunrise = self.computeTime(180 - 0.833, t[1])
    dhuhr = self.midDay(t[2])
    asr = self.computeAsr(1 + @asrJuristic, t[3])
    sunset = self.computeTime(0.833, t[4])
    maghrib = self.computeTime(@methods[@calcMethod][2], t[5])
    isha = self.computeTime(@methods[@calcMethod][4], t[6])
    return [fajr, sunrise, dhuhr, asr, sunset, maghrib, isha]
  end

  def computeTime(g, t)
    d = self.sunPosition(@jdate + t)[0]
    z = self.midDay(t)
    v = 1/15.0*self.arccos((-self.sin(g) - self.sin(d)*self.sin(@lat))/
                           (self.cos(d)*self.cos(@lat)))
    return z + (g > 90 ? -v : v)
  end

  def midDay(time)
    eqt = sunPosition(@jdate + time)[1]
    return fixhour(12 - eqt)
  end

  def adjustTimes(times)
    timearray = [] of Float64
    times.map do |time|
      timearray << time + @timeZone - @lng / 15.0
    end

    timearray[2] += @dhuhrMinutes/60 # Dhuhr

    if (@methods[@calcMethod][1] == 1.0) # Maghrib
      timearray[5] = timearray[4] + @methods[@calcMethod][2]/60
     
    end
    if (@methods[@calcMethod][3] == 1.0) # Isha
      timearray[6] = timearray[5] + @methods[@calcMethod][4]/60
    end
    return timearray
    # if ($this->adjustHighLats != $this->None)
    # 	$times = $this->adjustHighLatTimes($times);
    # return $times;
  end

  # compute prayer times at given julian date
  def computeDayTimes
    times = [5, 6, 12, 13, 18, 18, 18] # default times
    times1 = self.computeTimes(times)
    t = self.adjustTimes(times1)
    @timeNames["fajr"] = floatToTime24(t[0])
    @timeNames["sunrise"] = floatToTime24(t[1])
    @timeNames["dhuhr"] = floatToTime24(t[2])
    @timeNames["asr"] = floatToTime24(t[3])
    @timeNames["sunset"] = floatToTime24(t[4])
    @timeNames["maghrib"] = floatToTime24(t[5])
    @timeNames["isha"] = floatToTime24(t[6])
    return @timeNames.to_json

    # return $this->adjustTimesFormat($times);
  end

  def correctionForTimes(corrections : Array(Int32))
    counter = 0
    @timeNames.each do |key, value|
      minutes = @timeNames[key].split(":")[1].to_i32 + (corrections[counter])
      @timeNames[key] = "#{@timeNames[key].split(":")[0].to_s}:#{minutes.to_s}"
      counter += 1
    end
    @timeNames.to_json
    # @timeNames["fajr"].split(":")[1].to_i32 + (fajr)
    # @timeNames["sunrise"].split(":")[1].to_i32 + (sunrise)
    # @timeNames["dhuhr"].split(":")[1].to_i32 + (dhuhr)
    # @timeNames["asr"].split(":")[1].to_i32 + (asr)
    # @timeNames["sunset"].split(":")[1].to_i32 + (sunset)
    # @timeNames["maghrib"].split(":")[1].to_i32 + (maghrib)
    # @timeNames["isha"].split(":")[1].to_i32 + (isha)
  end

  def computeAsr(step, t) # Shafii: step=1, Hanafi: step=2
    d = self.sunPosition(@jdate + t)[0]
    g = -self.arccot(step + self.tan((@lat - d).abs))
    return computeTime(g, t)
  end

  def getDatePrayerTimes(year, month, day, latitude, longitude, timeZone, calcMethod = "MWL")
    @lat = latitude
    @lng = longitude
    @timeZone = timeZone
    @calcMethod = calcMethod
    @jdate = self.julian(year, month, day) - longitude/(15*24)
    return self.computeDayTimes
  end
end

