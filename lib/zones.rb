require "tzinfo"

class Date
  def self.parse_str(str)
    case str
    when %r!^((?:19|20)\d\d)(\d\d)(\d\d)(\d\d)!
      ymd = [$1.to_i, $2.to_i, $3.to_i]
    when %r!^
      (?:(0[1-9]|[12]\d|3[01]|[1-9][-/ ])[-/ ]? #  $1: day
         ((?>[a-z]{3,9}))[-/ ]?                 #  $2: month
         ((?>19|20)\d\d)                        #  $3: year
      | # or...
         ((?>19|20)\d\d)[-/]?                   #  $4: year
         (0[1-9]|1[012]|[1-9][-/])[-/]?         #  $5: month
         (0[1-9]|[12]\d|3[01]|[1-9][\sT])       #  $6: day
      | # or...
         (0[1-9]|1[012]|[1-9][-/])[-/]?         #  $7: month
         (0[1-9]|[12]\d|3[01]|[1-9][-/])[-/]?   #  $8: day
         ((?>19|20)\d\d)                        #  $9: year
      )
    !iox
      ymd = $1 ? [$3.to_i, month_num($2), $1.to_i] : $4 ? [$4.to_i, $5.to_i, $6.to_i] : [$9.to_i, $7.to_i, $8.to_i]
    else
      raise "can't parse: #{str}"
    end
    ymd
  end

  # parse date
  def self.to_day(str)
    ymd = parse_str(str)
    out = Date.new(*ymd)
  end
end

class Time
  def self.parse_str(str, ignore_offset=false)
    case str
    when %r!^((?:19|20)\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)?\.?(\d+)?([-+]\d\d:?\d\d)?!
      ymd = [$1.to_i, $2.to_i, $3.to_i]
      hms = [$4.to_i, $5.to_i, "#{$6}.#{$7}".to_f]
      off = $8.sub(/(\d)(\d\d)$/,'\1:\2') if $8 && !ignore_offset
    when %r!^
      (?:(0[1-9]|[12]\d|3[01]|[1-9][-/ ])[-/ ]? #  $1: day
         ((?>[a-z]{3,9}))[-/ ]?                 #  $2: month
         ((?>19|20)\d\d)                        #  $3: year
      | # or...
         ((?>19|20)\d\d)[-/]?                   #  $4: year
         (0[1-9]|1[012]|[1-9][-/])[-/]?         #  $5: month
         (0[1-9]|[12]\d|3[01]|[1-9][\sT])       #  $6: day
      | # or...
         (0[1-9]|1[012]|[1-9][-/])[-/]?         #  $7: month
         (0[1-9]|[12]\d|3[01]|[1-9][-/])[-/]?   #  $8: day
         ((?>19|20)\d\d)                        #  $9: year
      )\s?T?\s?
      (\d\d?)?                                  # $10: hour
      :?(\d\d)?                                 # $11: min
      :?(\d\d)?                                 # $12: sec
      \.?(\d+)?                                 # $13: dec
      \s?(?:(a|p)?m)?                           # $14: am/pm
      \s?(([-+])?(\d\d):?(\d\d)|UTC|GMT)?       # $15: offset ($16=sign, $17=hours, $18=mins)
    !iox
      ymd = $1 ? [$3.to_i, month_num($2), $1.to_i] : $4 ? [$4.to_i, $5.to_i, $6.to_i] : [$9.to_i, $7.to_i, $8.to_i]
      hms = [$14 ? ($10.to_i % 12) + (($14=="P" || $14=="p") ? 12 : 0) : $10.to_i, $11.to_i, "#{$12}.#{$13}".to_f]
      off = ($17 ? "#{$16||'+'}#{$17}:#{$18}" : "+00:00") if $15 && !ignore_offset
    else
      raise "can't parse: #{str}"
    end
    off ? [ymd, hms, off] : [ymd, hms]
  end

  # get month number
  def self.month_num(str)
    (@month_num ||= {
      "jan" => 1, "january"  =>  1, "jul" =>  7, "july"      =>  7,
      "feb" => 2, "february" =>  2, "aug" =>  8, "august"    =>  8,
      "mar" => 3, "march"    =>  3, "sep" =>  9, "septmeber" =>  9,
      "apr" => 4, "april"    =>  4, "oct" => 10, "october"   => 10,
      "may" => 5,                   "nov" => 11, "november"  => 11,
      "jun" => 6, "june"     =>  6, "dec" => 12, "december"  => 12,
    })[str.downcase] or raise "bad month: #{str}"
  end

  # parse time and honor desired timezone
  def self.to_tz(str, to_tz=nil, ignore_offset=false)
    ymd, hms, off = parse_str(str, ignore_offset)
    out = Time.new(*ymd, *hms, off)
    if to_tz
      if off
        out = out.to_tz(to_tz)
      else
        utc = out.utc
        off = TZInfo::Timezone.get(to_tz).utc_to_local(utc) - utc
        out = Time.new(*ymd, *hms, off)
      end
    else
      out
    end
  end

  # ignore supplied timezone, use local
  def self.to_tz!(str, to_tz=nil)
    to_tz(str, to_tz, true)
  end

  # transform time to new timezone
  def to_tz(to_tz)
    utc = utc? ? self : getutc
    raw = TZInfo::Timezone.get(to_tz).utc_to_local(utc)
    all = raw.to_a[1,5].reverse.push(strftime("%S.%6N").to_f) # retain fractional seconds
    out = Time.new(*all, raw - utc)
  end

  # preserve time but change offset
  def to_tz!(to_tz)
    all = to_a[1,5].reverse.push(strftime("%S.%6N").to_f) # retain fractional seconds
    raw = Time.utc(*all)
    utc = TZInfo::Timezone.get(to_tz).local_to_utc(raw)
    out = Time.new(*all, raw - utc)
  end
end

class String
  def to_tz(*args)
    Time.to_tz(self, *args)
  end

  def to_tz!(*args)
    Time.to_tz!(self, *args)
  end

  def to_day
    Date.to_day(self)
  end

  def to_day!(fmt="%Y-%m-%d")
    to_day.strftime(fmt)
  end
end
