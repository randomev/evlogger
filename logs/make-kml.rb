#!/usr/bin/ruby
require 'rubygems'
require 'builder'

header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://www.opengis.net/kml/2.2\">
  <Document>
    <name>Paths</name>
    <description>Examples of paths. Note that the tessellate tag is by default
      set to 0. If you want to create tessellated lines, they must be authored
      (or edited) directly in KML.</description>
    <Style id=\"yellowLineGreenPoly\">
      <LineStyle>
        <color>7f00ffff</color>
        <width>4</width>
      </LineStyle>
      <PolyStyle>
        <color>7f00ff00</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>Absolute Extruded</name>
      <description>Transparent green wall with yellow outlines</description>
      <styleUrl>#yellowLineGreenPoly</styleUrl>
      <LineString>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>absolute</altitudeMode>
        <coordinates> 
"

footer = "
        </coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>
"

xml = Builder::XmlMarkup.new( :indent => 2 )
xml.instruct! :xml, :encoding => "UTF-8"

#s = header

source = File.open("FIRSTLOG.TXT") 
  xml.kml do |kml|
    kml.Document do |document|
      document.name "EVLogger"
      document.description "EVLogger"
      (0...200).each do |speed|                             # 0 - 200 km/h line widths
        document.Style(:id =>"normal#{speed}") do |style|
          style.LineStyle do |lt|
            #lt.color "7f0000" << (255-speed).to_s(16) #<< "00ffff" #7f00ffff
            lt.color "7f" << (255-speed).to_s(16) << "0000"  #<< "00ffff" #7f00ffff
            lt.width speed*5
          end
        end
      end
      
      sprev = ""
      s = ""
        source.each_line do |fd|
          document.Placemark do |placemark|
          	fd.chomp!
            @a = fd.split(/,/)    # date;time,altitude(cm);speed(knots^10-2);AD(0-1100), lat, lon
          	placemark.name @a[0]
            #placemark.description @a[1]
          	
            @f = @a[1].split(/;/) # altitude,speed,ad
            
          	placemark.styleUrl "#normal" << ((@f[1].to_f/100.0).to_i).to_s #//((@f[1].to_f/100.0*1.852).to_i).to_s
          	
          	placemark.ExtendedData do |extendeddata|
        	    extendeddata.Data(:name => "Speed (kn)") do |d| 
        	        d.value @f[1].to_s
        	    end
        	    extendeddata.Data(:name => "Altitude (mm)") do |d| 
        	        d.value @f[0].to_s
        	    end
        	    extendeddata.Data(:name => "AD (raw 10bit)") do |d| 
        	        d.value @f[2].to_s
        	    end
        	    #(:name => "Speed") @f[1].to_s
        	    #extendeddata.Data(:name => "Alt") @f[0] 
        	    #extendeddata.Data(:name => "AD") @f[2] 
        	  end
        	  
          	placemark.LineString do |linestring|
          	
            	#s = s + (@a[3].to_f/100000.0).to_s + ',' + (@a[2].to_f/100000.0).to_s + ',' + (@f[0].to_f/100.0).to_s + "\n"
            	sprev = s
            	s = (@a[3].to_f/100000.0).to_s + ',' + (@a[2].to_f/100000.0).to_s + ',' + (@f[0].to_f/100.0).to_s + "\n"
            	#s2 = (@a[3].to_f/100000.0+0.001).to_s + ',' + (@a[2].to_f/100000.0).to_s + ',' + (@f[0].to_f/100.0).to_s + "\n"

#              linestring.extrude 1
              linestring.tessellate 1
              linestring.altitudeMode "absolute"
              linestring.coordinates sprev << ' ' << s # << ' ' << s2
              
            end
          end 
        end
      end
  end

source.close

#s = s + footer

#puts s
puts xml.target!
