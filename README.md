# prayer

This is program for calculate muslim prayer times made in Crystal lang based on calculations and source code from https://github.com/abodehq/Pray-Times

## Usage

1. Clone repository
2. Open with text editor folder and go to src/prayer.cr
3. On end of file instanciate new Prayer class with 
```
prayer = Prayer.new
```
4. Then use this code to get prayer time
```
prayer.getDatePrayerTimes(year, month, day, latitude , longitude, timezone, methodOfCalculation)
```
this is example
```
prayer.getDatePrayerTimes(2019, 4, 29, 40.8504, -73.9369, -4) #New York times
```
5. When compare to internet times if you find some difference in times you can adjust it with 

```
puts prayer.correctionForTimes([fajr,sunrise,dhuhr,asr,sunset,maghrib,isha])
```

this is example

```
puts prayer.correctionForTimes([-5,-5,-1,-1,6,6,0])
```

