require 'spec_helper'

describe Timeliness::Parser do
  context "parse" do
    it "should return time object for valid time string" do
      parse("2000-01-01 12:13:14", :datetime).should be_kind_of(Time)
    end

    it "should return nil for datetime string with invalid date part" do
      should_not_parse("2000-02-30 12:13:14", :datetime)
    end

    it "should return nil for datetime string with invalid time part" do
      should_not_parse("2000-02-01 25:13:14", :datetime)
    end

    it "should return nil for invalid date string" do
      should_not_parse("2000-02-30", :date)
    end

    it "should return nil for invalid time string" do
      should_not_parse("25:00:00", :time)
    end

    it "should ignore time in datetime string for date type" do
      parse('2000-02-01 12:13', :date).should == Time.local(2000,2,1)
    end

    it "should ignore date in datetime string for time type" do
      parse('2010-02-01 12:13', :time).should == Time.local(2000,1,1,12,13)
    end

    it "should return return same value if value not a string" do
      value = Time.now
      parse(value, :datetime).should == value
    end

    context "with :now option" do
      it 'should use date parts if string does not specify' do
        time = parse("12:13:14", :now => Time.local(2010,1,1))
        time.should == Time.local(2010,1,1,12,13,14)
      end
    end

    context "with :zone option" do
      context ":utc" do
        it "should return time object in utc timezone" do
          time = parse("2000-06-01 12:13:14", :datetime, :zone => :utc)
          time.utc_offset.should == 0
        end
      end

      context ":local" do
        it "should return time object in local system timezone" do
          time = parse("2000-06-01 12:13:14", :datetime, :zone => :local)
          time.utc_offset.should == 10.hours
        end
      end

      context ":current" do
        it "should return time object in current timezone" do
          Time.zone = 'Adelaide'
          time = parse("2000-06-01 12:13:14", :datetime, :zone => :current)
          time.utc_offset.should == 9.5.hours
        end
      end

      context "named zone" do
        it "should return time object in the timezone" do
          time = parse("2000-06-01 12:13:14", :datetime, :zone => 'London')
          time.utc_offset.should == 1.hour
        end
      end
    end

    describe "for time type" do
      it 'should use date from date_for_time_type' do
        parse('12:13:14', :time).should == Time.local(2000,1,1,12,13,14)
      end

      context "with :now option" do
        it 'should use date from :now' do
          parse('12:13:14', :time, :now => Time.local(2010, 6, 1)).should == Time.local(2010,6,1,12,13,14)
        end
      end

      context "with :zone option" do
        before(:all) do
          Timecop.freeze(2010,1,1,0,0,0)
        end

        it "should use date from the specified zone" do
          time = parse("12:13:14", :time, :zone => :utc)
          time.year.should == 2009
          time.month.should == 12
          time.day.should == 31
        end

        after(:all) do
          Timecop.return
        end
      end
    end
  end

  context "_parse" do
    context "with type" do
      it "should return date array from date string" do
        time_array = parser._parse('2000-02-01', :date)
        time_array.should == [2000,2,1,nil,nil,nil,nil]
      end

      it "should return time array from time string" do
        time_array = parser._parse('12:13:14', :time)
        time_array.should == [nil,nil,nil,12,13,14,nil]
      end

      it "should return datetime array from datetime string" do
        time_array = parser._parse('2000-02-01 12:13:14', :datetime)
        time_array.should == [2000,2,1,12,13,14,nil]
      end

      it "should return date array from date string when type is datetime" do
        time_array = parser._parse('2000-02-01', :datetime)
        time_array.should == [2000,2,1,nil,nil,nil,nil]
      end

      it "should return datetime array from datetime string when type is date" do
        time_array = parser._parse('2000-02-01 12:13:14', :date)
        time_array.should == [2000,2,1,12,13,14,nil]
      end
    end

    context "with no type" do
      it "should return date array from date string" do
        time_array = parser._parse('2000-02-01')
        time_array.should == [2000,2,1,nil,nil,nil,nil]
      end

      it "should return time array from time string" do
        time_array = parser._parse('12:13:14', :time)
        time_array.should == [nil,nil,nil,12,13,14,nil]
      end

      it "should return datetime array from datetime string" do
        time_array = parser._parse('2000-02-01 12:13:14')
        time_array.should == [2000,2,1,12,13,14,nil]
      end

      it "should return date array from date string when type is datetime" do
        time_array = parser._parse('2000-02-01')
        time_array.should == [2000,2,1,nil,nil,nil,nil]
      end

      it "should return datetime array from datetime string when type is date" do
        time_array = parser._parse('2000-02-01 12:13:14')
        time_array.should == [2000,2,1,12,13,14,nil]
      end
    end

    context "with :strict => true" do
      it "should return nil from date string when type is datetime" do
        time_array = parser._parse('2000-02-01', :datetime, :strict => true)
        time_array.should be_nil
      end

      it "should return nil from datetime string when type is date" do
        time_array = parser._parse('2000-02-01 12:13:14', :date, :strict => true)
        time_array.should be_nil
      end

      it "should return nil from datetime string when type is time" do
        time_array = parser._parse('2000-02-01 12:13:14', :time, :strict => true)
        time_array.should be_nil
      end

      it "should parse date string when type is date" do
        time_array = parser._parse('2000-02-01', :date, :strict => true)
        time_array.should_not be_nil
      end

      it "should parse time string when type is time" do
        time_array = parser._parse('12:13:14', :time, :strict => true)
        time_array.should_not be_nil
      end

      it "should parse datetime string when type is datetime" do
        time_array = parser._parse('2000-02-01 12:13:14', :datetime, :strict => true)
        time_array.should_not be_nil
      end

      it "should ignore strict parsing if no type specified" do
        time_array = parser._parse('2000-02-01', :strict => true)
        time_array.should_not be_nil
      end
    end

    it "should return nil if time hour is out of range for AM meridian" do
      time_array = parser._parse('13:14 am', :time)
      time_array.should == nil
      time_array = parser._parse('00:14 am', :time)
      time_array.should == nil
    end

    context "with :format option" do
      it "should return values if string matches specified format" do
        time_array = parser._parse('2000-02-01 12:13:14', :datetime, :format => 'yyyy-mm-dd hh:nn:ss')
        time_array.should == [2000,2,1,12,13,14,nil]
      end

      it "should return nil if string does not match specified format" do
        time_array = parser._parse('2000-02-01 12:13', :datetime, :format => 'yyyy-mm-dd hh:nn:ss')
        time_array.should be_nil
      end
    end

    context "date with ambiguous year" do
      it "should return year in current century if year below threshold" do
        time_array = parser._parse('01-02-29', :date)
        time_array.should == [2029,2,1,nil,nil,nil,nil]
      end

      it "should return year in last century if year at or above threshold" do
        time_array = parser._parse('01-02-30', :date)
        time_array.should == [1930,2,1,nil,nil,nil,nil]
      end

      it "should allow custom threshold" do
        default = Timeliness.ambiguous_year_threshold
        Timeliness.ambiguous_year_threshold = 40
        time_array = parser._parse('01-02-39', :date)
        time_array.should == [2039,2,1,nil,nil,nil,nil]
        time_array = parser._parse('01-02-40', :date)
        time_array.should == [1940,2,1,nil,nil,nil,nil]
        Timeliness.ambiguous_year_threshold = default
      end
    end
  end

  describe "make_time" do
    context "with zone value" do
      context ":utc" do
        it "should return time object in utc timezone" do
          time = parser.make_time([2000,6,1,12,0,0], :utc)
          time.utc_offset.should == 0
        end
      end

      context ":local" do
        it "should return time object in local system timezone" do
          time = parser.make_time([2000,6,1,12,0,0], :local)
          time.utc_offset.should == 10.hours
        end
      end

      context ":current" do
        it "should return time object in current timezone" do
          Time.zone = 'Adelaide'
          time = parser.make_time([2000,6,1,12,0,0], :current)
          time.utc_offset.should == 9.5.hours
        end
      end

      context "named zone" do
        it "should return time object in the timezone" do
          time = parser.make_time([2000,6,1,12,0,0], 'London')
          time.utc_offset.should == 1.hour
        end
      end
    end
  end

  describe "current_date" do
    before(:all) do
      Timecop.freeze(2010,1,1,0,0,0)
    end

    context "with no options" do
      it 'should return date_for_time_type values with no options' do
        current_date.should == Timeliness.date_for_time_type
      end
    end

    context "with :now option" do
      it 'should return date array from Time value' do
        time = Time.now
        date_array = [time.year, time.month, time.day]
        current_date(:now => time).should == date_array
      end
    end

    context "with :zone option" do
      it 'should return date array for utc zone' do
        time = Time.now.getutc
        date_array = [time.year, time.month, time.day]
        current_date(:zone => :utc).should == date_array
      end

      it 'should return date array for local zone' do
        time = Time.now
        date_array = [time.year, time.month, time.day]
        current_date(:zone => :local).should == date_array
      end

      it 'should return date array for current zone' do
        Time.zone = 'London'
        time = Time.current
        date_array = [time.year, time.month, time.day]
        current_date(:zone => :current).should == date_array
      end

      it 'should return date array for named zone' do
        time = Time.use_zone('London') { Time.current }
        date_array = [time.year, time.month, time.day]
        current_date(:zone => 'London').should == date_array
      end
    end

    after(:all) do
      Timecop.return
    end
  end
end
