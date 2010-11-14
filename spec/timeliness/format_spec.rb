require 'spec_helper'

describe Timeliness::Format do
  context "#process" do
    it "should define method which outputs date array with values in correct order" do
      format_for('yyyy-mm-dd').process('2000', '1', '2').should == [2000,1,2,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs date array from format with different order" do
      format_for('dd/mm/yyyy').process('2', '1', '2000').should == [2000,1,2,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs time array" do
      format_for('hh:nn:ss').process('01', '02', '03').should == [nil,nil,nil,1,2,3,nil,nil]
    end

    it "should define method which outputs time array with meridian 'pm' adjusted hour" do
      format_for('hh:nn:ss ampm').process('01', '02', '03', 'pm').should == [nil,nil,nil,13,2,3,nil,nil]
    end

    it "should define method which outputs time array with meridian 'am' unadjusted hour" do
      format_for('hh:nn:ss ampm').process('01', '02', '03', 'am').should == [nil,nil,nil,1,2,3,nil,nil]
    end

    it "should define method which outputs time array with microseconds" do
      format_for('hh:nn:ss.u').process('01', '02', '03', '99').should == [nil,nil,nil,1,2,3,990000,nil]
    end

    it "should define method which outputs datetime array with zone offset" do
      format_for('yyyy-mm-dd hh:nn:ss.u zo').process('2001', '02', '03', '04', '05', '06', '99', '+10:00').should == [2001,2,3,4,5,6,990000,36000]
    end

    it "should define method which outputs datetime array with timezone string" do
      format_for('yyyy-mm-dd hh:nn:ss.u tz').process('2001', '02', '03', '04', '05', '06', '99', 'EST').should == [2001,2,3,4,5,6,990000,'EST']
    end
  end

  def format_for(format)
    Timeliness::Format.new(format).compile!
  end
end
