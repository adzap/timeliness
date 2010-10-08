require 'spec_helper'

describe Timeliness::FormatSet do
  describe "format method generator" do
    it "should generate method which outputs date array with values in correct order" do
      generate_method('yyyy-mm-dd').call('2000', '1', '2').should == [2000,1,2,nil,nil,nil,nil]
   end

    it "should generate method which outputs date array from format with different order" do
      generate_method('dd/mm/yyyy').call('2', '1', '2000').should == [2000,1,2,nil,nil,nil,nil]
    end

    it "should generate method which outputs time array" do
      generate_method('hh:nn:ss').call('01', '02', '03').should == [nil,nil,nil,1,2,3,nil]
    end

    it "should generate method which outputs time array with meridian 'pm' adjusted hour" do
      generate_method('hh:nn:ss ampm').call('01', '02', '03', 'pm').should == [nil,nil,nil,13,2,3,nil]
    end

    it "should generate method which outputs time array with meridian 'am' unadjusted hour" do
      generate_method('hh:nn:ss ampm').call('01', '02', '03', 'am').should == [nil,nil,nil,1,2,3,nil]
    end

    it "should generate method which outputs time array with microseconds" do
      generate_method('hh:nn:ss.u').call('01', '02', '03', '99').should == [nil,nil,nil,1,2,3,990000]
    end

    it "should generate method which outputs datetime array with zone offset" do
      generate_method('yyyy-mm-dd hh:nn:ss.u zo').call('2001', '02', '03', '04', '05', '06', '99', '+10:00').should == [2001,2,3,4,5,6,990000,36000]
    end
  end

  describe "validate regexps" do

    describe "for time formats" do
      format_tests = {
        'hh:nn:ss'  => {:pass => ['12:12:12', '01:01:01'], :fail => ['1:12:12', '12:1:12', '12:12:1', '12-12-12']},
        'hh-nn-ss'  => {:pass => ['12-12-12', '01-01-01'], :fail => ['1-12-12', '12-1-12', '12-12-1', '12:12:12']},
        'h:nn'      => {:pass => ['12:12', '1:01'], :fail => ['12:2', '12-12']},
        'h.nn'      => {:pass => ['2.12', '12.12'], :fail => ['2.1', '12:12']},
        'h nn'      => {:pass => ['2 12', '12 12'], :fail => ['2 1', '2.12', '12:12']},
        'h-nn'      => {:pass => ['2-12', '12-12'], :fail => ['2-1', '2.12', '12:12']},
        'h:nn_ampm' => {:pass => ['2:12am', '2:12 pm', '2:12 AM', '2:12PM'], :fail => ['1:2am', '1:12  pm', '2.12am']},
        'h.nn_ampm' => {:pass => ['2.12am', '2.12 pm'], :fail => ['1:2am', '1:12  pm', '2:12am']},
        'h nn_ampm' => {:pass => ['2 12am', '2 12 pm'], :fail => ['1 2am', '1 12  pm', '2:12am']},
        'h-nn_ampm' => {:pass => ['2-12am', '2-12 pm'], :fail => ['1-2am', '1-12  pm', '2:12am']},
        'h_ampm'    => {:pass => ['2am', '2 am', '12 pm'], :fail => ['1.am', '12  pm', '2:12am']},
      }
      format_tests.each do |format, values|
        it "should correctly validate times in format '#{format}'" do
          regexp = generate_regexp(format)
          values[:pass].each {|value| value.should match(regexp)}
          values[:fail].each {|value| value.should_not match(regexp)}
        end
      end
    end

    describe "for date formats" do
      format_tests = {
        'yyyy/mm/dd' => {:pass => ['2000/02/01'], :fail => ['2000\02\01', '2000/2/1', '00/02/01']},
        'yyyy-mm-dd' => {:pass => ['2000-02-01'], :fail => ['2000\02\01', '2000-2-1', '00-02-01']},
        'yyyy.mm.dd' => {:pass => ['2000.02.01'], :fail => ['2000\02\01', '2000.2.1', '00.02.01']},
        'm/d/yy'     => {:pass => ['2/1/01', '02/01/00', '02/01/2000'], :fail => ['2/1/0', '2.1.01']},
        'd/m/yy'     => {:pass => ['1/2/01', '01/02/00', '01/02/2000'], :fail => ['1/2/0', '1.2.01']},
        'm\d\yy'     => {:pass => ['2\1\01', '2\01\00', '02\01\2000'], :fail => ['2\1\0', '2/1/01']},
        'd\m\yy'     => {:pass => ['1\2\01', '1\02\00', '01\02\2000'], :fail => ['1\2\0', '1/2/01']},
        'd-m-yy'     => {:pass => ['1-2-01', '1-02-00', '01-02-2000'], :fail => ['1-2-0', '1/2/01']},
        'd.m.yy'     => {:pass => ['1.2.01', '1.02.00', '01.02.2000'], :fail => ['1.2.0', '1/2/01']},
        'd mmm yy'   => {:pass => ['1 Feb 00', '1 Feb 2000', '1 February 00', '01 February 2000'],
                          :fail => ['1 Fe 00', 'Feb 1 2000', '1 Feb 0']}
      }
      format_tests.each do |format, values|
        it "should correctly validate dates in format '#{format}'" do
          regexp = generate_regexp(format)
          values[:pass].each {|value| value.should match(regexp)}
          values[:fail].each {|value| value.should_not match(regexp)}
        end
      end
    end

    describe "for datetime formats" do
      format_tests = {
        'ddd mmm d hh:nn:ss zo yyyy'  => {:pass => ['Sat Jul 19 12:00:00 +1000 2008'], :fail => []},
        'yyyy-mm-ddThh:nn:ss(?:Z|zo)' => {:pass => ['2008-07-19T12:00:00+10:00', '2008-07-19T12:00:00Z'], :fail => ['2008-07-19T12:00:00Z+10:00']},
      }
      format_tests.each do |format, values|
        it "should correctly validate datetimes in format '#{format}'" do
          regexp = generate_regexp(format)
          values[:pass].each {|value| value.should match(regexp)}
          values[:fail].each {|value| value.should_not match(regexp)}
        end
      end
    end
  end

  def generate_method(format)
    Timeliness::FormatSet.compile([format]).method(:"format_#{format}")
  end

  def generate_regexp(format)
    Timeliness::FormatSet.compile([format]).regexp
  end

end
