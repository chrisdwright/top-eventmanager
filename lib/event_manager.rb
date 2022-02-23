require "csv"
require "google/apis/civicinfo_v2"
require "erb"
#require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0, 5]
end

def clean_phone(phone)
  number = phone.clone
  ["(", ")", "-", ".", " "].each { |d| number.gsub!(d, "") }
  if number.length < 10
    "Bad Number"
  elsif number.length > 11
    "Bad Number"
  elsif number.length > 10
    if number[0] == "1"
      number[-10, 10]
    else
      "Bad Number"
    end
  else
    number
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue => exception
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")
  File.open("output/thanks_#{id}.html", "w") do |file|
    file.puts form_letter
  end
end

puts "EventManager intialized!"

return if !File.exists? "form_letter.erb"
template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

return if !File.exists? "event_attendees.csv"

contents = CSV.open(
  "event_attendees.csv",
  headers: true,
  header_converters: :symbol
)

hours = []
days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])

  reg = row[:regdate]
  regFormatted = Time.strptime(reg, "%m/%d/%y %k:%M")
  hours << regFormatted.hour
  days << regFormatted.wday

=begin
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
=end
end

#find most registrations by day, decending
dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
dayList = days.reduce(Hash.new(0)) do |h, v|
  dayName = dayNames[v]
  h[dayName] += 1
  h
end
print dayList.sort_by { |k, v| -v }
print "\n"

#find most registrations by hour, decending
hourList = hours.reduce(Hash.new(0)) do |h, v|
  h[v.to_s] += 1
  h
end
print hourList.sort_by { |k, v| -v }
print "\n"