require "tzinfo"

module MonthValue
  def month_value(str)
    (val = str.to_i).zero? ? (@month_value ||= {
      "jan" => 1, "january"  =>  1, "jul" =>  7, "july"      =>  7,
      "feb" => 2, "february" =>  2, "aug" =>  8, "august"    =>  8,
      "mar" => 3, "march"    =>  3, "sep" =>  9, "september" =>  9,
      "apr" => 4, "april"    =>  4, "oct" => 10, "october"   => 10,
      "may" => 5,                   "nov" => 11, "november"  => 11,
      "jun" => 6, "june"     =>  6, "dec" => 12, "december"  => 12,
    })[str.downcase] : val or raise "bad month: #{str}"
  end
end

class Date
  extend MonthValue

  def self.parse_str(str)
    case str
    when %r!^((?:19|20)\d\d)(\d\d)(\d\d)!
      ymd = [$1.to_i, $2.to_i, $3.to_i]
    when %r!^
      (?:(0[1-9]|[12]\d|3[01]|[1-9](?=\D))[-/\s]?          #  $1: day
         (                          (?>[a-z]{3,9}))[-/\s]? #  $2: month (no digits allowed here)
         ((?>19|20)\d\d)                                   #  $3: year
      | # or...
         ((?>19|20)\d\d)[-/\s]?                            #  $4: year
         (0[1-9]|1[012]|[1-9](?=\D)|(?>[a-z]{3,9}))[-/\s]? #  $5: month
         (0[1-9]|[12]\d|3[01]|[1-9]\b)                     #  $6: day
      | # or...
         (0[1-9]|1[012]|[1-9](?=\D)|(?>[a-z]{3,9}))[-/\s]? #  $7: month
         (0[1-9]|[12]\d|3[01]|[1-9](?=\D)),?[-/\s]?        #  $8: day
         ((?>19|20)\d\d)                                   #  $9: year
      )
    !iox
      ymd =   $1 ? [ $3.to_i, month_value($2), $1.to_i] : \
              $4 ? [ $4.to_i, month_value($5), $6.to_i] : \
                   [ $9.to_i, month_value($7), $8.to_i]
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
  extend MonthValue

  def self.parse_str(str)
    case str
    when %r!^
      ((?:19|20)\d\d)[-/\s]?(\d\d)[-/\s]?(\d\d)\s? # $1-3: year, month, day
      (\d\d):?(\d\d):?(\d\d)?\.?(\d+)?             # $4-7: hour, min, sec, decimal
      ([-+]\d\d:?\d\d)?                            # $8  : offset
    !x
      ymd = [$1.to_i, $2.to_i, $3.to_i]
      hms = [$4.to_i, $5.to_i, "#{$6}.#{$7}".to_f]
      off = $8.sub(/(\d)(\d\d)$/,'\1:\2') if $8
    when %r!^
      (?:(0[1-9]|[12]\d|3[01]|[1-9](?=\D))[-/\s]?          #  $1: day
         (                          (?>[a-z]{3,9}))[-/\s]? #  $2: month (no digits allowed here)
         ((?>19|20)\d\d)                                   #  $3: year
      | # or...
         ((?>19|20)\d\d)[-/\s]?                            #  $4: year
         (0[1-9]|1[012]|[1-9](?=\D)|(?>[a-z]{3,9}))[-/\s]? #  $5: month
         (0[1-9]|[12]\d|3[01]|[1-9](?=\D))                 #  $6: day
      | # or...
         (0[1-9]|1[012]|[1-9](?=\D)|(?>[a-z]{3,9}))[-/\s]? #  $7: month
         (0[1-9]|[12]\d|3[01]|[1-9](?=\D)),?[-/\s]?        #  $8: day
         ((?>19|20)\d\d)                                   #  $9: year
      )\s?T?\s?
      (\d\d?)?                                             # $10: hour
      :?(\d\d)?                                            # $11: min
      :?(\d\d)?                                            # $12: sec
      \.?(\d+)?                                            # $13: dec
      \s?(?:(a|p)?m)?                                      # $14: am/pm
      \s?(([-+])?(\d\d):?(\d\d)|UTC|GMT|Z)?                # $15: offset ($16=sign, $17=hours, $18=mins)
    !iox
      ymd =   $1 ? [ $3.to_i, month_value($2), $1.to_i] : \
              $4 ? [ $4.to_i, month_value($5), $6.to_i] : \
                   [ $9.to_i, month_value($7), $8.to_i]
      hms = [$14 ? ($10.to_i % 12) + (($14=="P" || $14=="p") ? 12 : 0) : $10.to_i, $11.to_i, "#{$12}.#{$13}".to_f]
      off = ($17 ? "#{$16||'+'}#{$17}:#{$18}" : "+00:00") if $15
    else
      raise "can't parse: #{str}"
    end
    [ymd, hms, off]
  end

  # read values of time in asz, stated, or local timezone, optionally convert to toz timezone
  def self.to_tz(str, toz=nil, asz=nil)
    ymd, hms, off = parse_str(str)
    out = Time.new(*ymd, *hms, asz ? TZInfo::Timezone.get(asz) : off)
    toz ? out.to(toz) : out
  end

  # swap the order of to_tz and default asz to UTC
  def self.as_tz(str, asz="UTC", toz=nil)
    to_tz(str, toz, asz)
  end

  # same moment in time, different time zone (ie - change time and zone)
  def to(zone)
    cfg = TZInfo::Timezone.get(zone)
    use = cfg.to_local(self)
    ary = use.to_a[1,5].reverse.push(strftime("%S.%6N").to_f)
    Time.new(*ary, cfg)
  end

  # same values of time, different time zone (ie - change time zone only)
  def as(zone)
    cfg = TZInfo::Timezone.get(zone)
    use = self
    ary = use.to_a[1,5].reverse.push(strftime("%S.%6N").to_f)
    Time.new(*ary, cfg)
  end
end

class String
  def to_day
    Date.to_day(self)
  end

  def iso_date(fmt="%Y-%m-%d")
    to_day.strftime(fmt)
  end

  def to_tz(*args)
    Time.to_tz(self, *args)
  end

  def as_tz(*args)
    Time.as_tz(self, *args)
  end
end
