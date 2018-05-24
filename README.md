# zones

`zones` is a Ruby gem that makes it easy to parse time and convert it between time zones.

## Examples

```ruby
# when parsing, the "!" means to ignore the supplied time zone / offset
x = "3 August 2017 11:43 +0415".to_tz("US/Pacific")  # 2017-08-03 00:28:00 -0700
y = "3 August 2017 11:43 +0415".to_tz!("US/Pacific") # 2017-08-03 11:43:00 -0700

# when converting, the "!" means to only change the offset
x.to_tz("US/Eastern")  # 2017-08-03 03:28:00 -0400
y.to_tz!("US/Eastern") # 2017-08-03 11:43:00 -0400
```

## License

This software is licensed under terms of the MIT License.
