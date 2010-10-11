require 'spec_helper'

describe Timeliness::Parser do

  context "parse" do
    it "should return time object for valid time string" do
      parse("2000-01-01 12:13:14", :datetime).should be_kind_of(Time)
    end

    it "should return nil for time string with invalid date part" do
      parse("2000-02-30 12:13:14", :datetime).should be_nil
    end

    it "should return nil for time string with invalid time part" do
      parse("2000-02-01 25:13:14", :datetime).should be_nil
    end

    it "should return same Time object when passed a Time object" do
      value = Time.now
      parse(value, :datetime).should == value
    end

    it "should convert time string into current timezone" do
      Time.zone = 'Melbourne'
      time = parse("2000-01-01 12:13:14", :datetime, :timezone_aware => true)
      Time.zone.utc_offset.should == 10.hours
    end

    it "should return nil for invalid date string" do
      parse("2000-02-30", :date).should be_nil
    end

    it "should ignore time for date type" do
      value = parser.parse('2000-02-01 12:13', :date)
      value.should == Date.new(2000,2,1)
    end

    it "should ignore date for time type" do
      value = parser.parse('2010-02-01 12:13', :time)
      value.should == Time.utc(2000,1,1,12,13)
    end

    def parse(*args)
      Timeliness::Parser.parse(*args)
    end
  end

  context "_parse" do
    it "should return date array from time string" do
      time_array = parser._parse('2000-02-01', :date)
      time_array.should == [2000,2,1,nil,nil,nil,nil]
    end

    it "should return datetime array from string value" do
      time_array = parser._parse('2000-02-01 12:13:14', :datetime)
      time_array.should == [2000,2,1,12,13,14,nil]
    end

    it "should parse date string when type is datetime" do
      time_array = parser._parse('2000-02-01', :datetime)
      time_array.should == [2000,2,1,nil,nil,nil,nil]
    end

    it "should parse datetime string when type is date" do
      time_array = parser._parse('2000-02-01 12:13:14', :date)
      time_array.should == [2000,2,1,12,13,14,nil]
    end

    it "should return nil if time hour is out of range for AM meridian" do
      time_array = parser._parse('13:14 am', :time)
      time_array.should == nil
      time_array = parser._parse('00:14 am', :time)
      time_array.should == nil
    end

    context "with format option" do
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

  context "make_time" do
    it "should create time using current timezone" do
      time = Timeliness::Parser.make_time([2000,1,1,12,0,0])
      time.zone.should == "UTC"
    end

    it "should create time using current timezone" do
      Time.zone = 'Melbourne'
      time = Timeliness::Parser.make_time([2000,1,1,12,0,0], true)
      time.zone.should == "EST"
    end
  end

  context "adding formats" do
    before do
      parser.compile_format_sets
    end

    it "should add format to format array" do
      parser.add_formats(:time, "h o'clock")
      parser.time_formats.should include("h o'clock")
    end

    it "should match new format after its added" do
      validate("12 o'clock", :time).should be_false
      parser.add_formats(:time, "h o'clock")
      validate("12 o'clock", :time).should be_true
    end

    it "should add format before specified format and be higher precedence" do
      parser.add_formats(:time, "ss:hh:nn", :before => 'hh:nn:ss')
      validate("59:23:58", :time).should be_true
      time_array = parser._parse('59:23:58', :time)
      time_array.should == [nil,nil,nil,23,58,59,nil]
    end

    it "should raise error if format exists" do
      lambda { parser.add_formats(:time, "hh:nn:ss") }.should raise_error()
    end

    it "should raise error if format exists" do
      lambda { parser.add_formats(:time, "ss:hh:nn", :before => 'nn:hh:ss') }.should raise_error()
    end

    after do
      parser.time_formats.delete("h o'clock")
      parser.time_formats.delete("ss:hh:nn")
    end
  end

  context "removing formats" do
    it "should remove format from format array" do
      parser.remove_formats(:time, 'h.nn_ampm')
      parser.time_formats.should_not include("h o'clock")
    end

    it "should not match time after its format is removed" do
      validate('2.12am', :time).should be_true
      parser.remove_formats(:time, 'h.nn_ampm')
      validate('2.12am', :time).should be_false
    end

    it "should raise error if format does not exist" do
      lambda { parser.remove_formats(:time, "ss:hh:nn") }.should raise_error()
    end

    after do
      parser.time_formats << 'h.nn_ampm'
      parser.compile_format_sets
    end
  end

  context "removing US formats" do
    it "should validate a date as European format when US formats removed" do
      time_array = parser._parse('01/02/2000', :date)
      time_array.should == [2000,1,2,nil,nil,nil,nil]
      parser.remove_us_formats
      time_array = parser._parse('01/02/2000', :date)
      time_array.should == [2000,2,1,nil,nil,nil,nil]
    end
  end

  def parser
    Timeliness::Parser
  end

  def validate(time_string, type)
    !(parser.send("#{type}_format_set").regexp =~ time_string).nil?
  end
end
