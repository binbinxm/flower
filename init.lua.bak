require("sec")

pin = 0
pump_delay = 0
gpio.mode(pin,gpio.OUTPUT)


wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid=ssid
station_cfg.pwd=passwd
wifi.sta.config(station_cfg)

mqtt_client_id = "melinda_01"
mqtt_server = "iot.binya.tech"
mqtt_username = ""
mqtt_password = ""
mqtt_port = 1883
mqtt_subscribe_topic = "/home/env/pump"
mqtt_publish_topic = "/home/env/flowers"
mqtt_status = 0

m = mqtt.Client(mqtt_client_id, 120)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client dont send keepalive packet
-- m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client)
	print ("MQTT client connected")
	m:subscribe(mqtt_subscribe_topic, 0, function(client) print("subscribe "..mqtt_subscribe_topic.." success") end)
	mqtt_status = 1
end)
m:on("offline", function(client)
	print ("MQTT client offline")
	mqtt_status = 0
end)

-- on message receive event
m:on("message", function(client, topic, data) 
--  print(topic .. ":" ) 
  if data ~= nil then
    print(data)
	-- print("received:", data)
	if(data == 'on')
		then
			pump_delay = 2
		else
			pump_delay = 0
		end
  end
end)

function publish()
	if(wifi.sta.status() ~= wifi.STA_GOTIP)
	then
		print("WiFi disconnect")
		mqtt_status = 0
		pump_delay = 0
		return
	end
	
	print("ip address:\t" .. wifi.sta.getip())
	if(mqtt_status == 0)
	then
		pump_delay = 0
		print("MQTT connection lost, reconnecting...")
		m:connect(mqtt_server, mqtt_port, 0, 0,
			function(client)
				print("MQTT connected")
			end,
			function(client, reason)
			  print("failed reason: " .. reason)
			end)
		return
	end
	
	adcvalue = 1023-adc.read(0)
	pub_str = "{\"topic\":\""..mqtt_client_id.."\",\"value\":"..adcvalue.."}"
	m:publish(mqtt_publish_topic, pub_str, 0, 0, function(client) print("publish:\t" .. pub_str) end)
end



pump_timer = tmr.create()
pump_timer:register(1000, 1, function()
	if(pump_delay <= 0)
	then
		pump_delay = 0
		gpio.write(pin,gpio.HIGH)
	else
		pump_delay = pump_delay - 1
		gpio.write(pin,gpio.LOW)
	end
	print("pump_delay= "..pump_delay)
end)
pump_timer:start()

mytimer = tmr.create()
mytimer:register(10000, 1, function() publish() end)
mytimer:start()

