# zones

A friendly Ruby gem for time parsing and time zone conversion.

## API

```ruby
Time.to_tz(str, toz=nil, asz=nil)   # create a new Time object with a time zone
Time.as_tz(str, asz="UTC", toz=nil) # overrides original time zone and swaps params
Time#to(zone) # converts a time to a new time zone
Time#as(zone) # keeps the time, but changes the time zone

String#to_tz    # calls Time.to_tz
String#as_tz    # calls Time.as_tz
String#to_day   # calls Date.to_day
String#iso_date # parses and shows ISO date (YYYY-MM-DD)
```

## Examples

Parsing strings:

```ruby
# no argument means to parse the value as is; 'as' ignores the time zone and defaults to UTC
"3 August 2013 11:43 +0415".to_tz # 2013-08-03 11:43:00 +0415
"3 August 2013 11:43 +0415".as_tz # 2013-08-03 11:43:00 +0000

# one argument for `to_tz` means to parse naturally and then convert to that time zone
"3 August 2013 11:43 +0415".to_tz("US/Pacific") # 2013-08-03 00:28:00 -0700
"3 August 2013 11:43 +0415".to_tz("America/Caracas") # 2013-08-03 02:58:00 -0430

# one argument for `as_tz` means to ignore offset and use the parameter passed in
"3 August 2013 11:43 +0415".as_tz("US/Pacific") # 2013-08-03 11:43:00 -0700
"3 August 2013 11:43 +0415".as_tz("America/Caracas") # 2013-08-03 11:43:00 -0430

# use two arguments to indicate destination and source time zones, 'as' swaps the order
"3 August 2013 11:43 +0415".to_tz("US/Pacific", "America/Caracas") # 2013-08-03 09:13:00 -0700
"3 August 2013 11:43 +0415".as_tz("US/Pacific", "America/Caracas") # 2013-08-03 14:13:00 -0430

# the same as above, swapping functions and parameter order gives same results
"3 August 2013 11:43 +0415".to_tz("America/Caracas", "US/Pacific") # 2013-08-03 14:13:00 -0430
"3 August 2013 11:43 +0415".as_tz("America/Caracas", "US/Pacific") # 2013-08-03 09:13:00 -0700
```

Parsing strings using `to_tz`:

```ruby
# no args means to parse the value as is
"3 August 2013 11:43 +0415".to_tz # 2013-08-03 11:43:00 +0415

# one arg will then convert to that time zone
"3 August 2013 11:43 +0415".to_tz("US/Pacific") # 2013-08-03 00:28:00 -0700
"3 August 2013 11:43 +0415".to_tz("America/Caracas") # 2013-08-03 02:58:00 -0430

# two args forces the second arg as the initial time zone
"3 August 2013 11:43 +0415".to_tz("US/Pacific", "America/Caracas") # 2013-08-03 09:13:00 -0700
"3 August 2013 11:43 +0415".to_tz("America/Caracas", "US/Pacific") # 2013-08-03 14:13:00 -0430
```

Parsing strings using `as_tz`:

```ruby
# no args forces the timezone to be UTC
"3 August 2013 11:43 +0415".as_tz # 2013-08-03 11:43:00 +0000

# one arg ignore offset and forces the time zone as the arg
"3 August 2013 11:43 +0415".as_tz("US/Pacific") # 2013-08-03 11:43:00 -0700
"3 August 2013 11:43 +0415".as_tz("America/Caracas") # 2013-08-03 11:43:00 -0430

# two args forces the second arg as the initial time zone
"3 August 2013 11:43 +0415".as_tz("US/Pacific", "America/Caracas") # 2013-08-03 14:13:00 -0430
"3 August 2013 11:43 +0415".as_tz("America/Caracas", "US/Pacific") # 2013-08-03 09:13:00 -0700
```

Converting values:

```ruby
# 'as' keeps the time but changes the time zone, 'to' converts to a new time zone
x = "May 29, 2023 6:15pm -06:00".to_tz # 2023-05-29 18:15:00 -0600
x.as("US/Eastern")                     # 2023-05-29 18:15:00 -0400
x.to("US/Eastern")                     # 2023-05-29 20:15:00 -0400
```

Sample formats:

```ruby
x = "4/13/1971 19:25 -0700".to_tz # 1971-04-13 19:25:00 -0700
x = "13 May 2022 11:20PM".to_tz   # 2022-05-13 23:20:00 -0600
x = "September 24, 2008".iso_date # 2008-09-24
```

## License

This software is licensed under terms of the MIT License.
