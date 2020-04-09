require("sec")

gpio.mode(pin,gpio.OUTPUT)

gpio.mode(0,gpio.OUTPUT)


wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid=ssid
station_cfg.pwd=passwd
wifi.sta.config(station_cfg)

mqtt_status = 0
pump_delay = 0

m = mqtt.Client(mqtt_client_id, 120)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client dont send keepalive packet
-- m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client)
	print ("MQTT client connected")
	m:subscribe(mqtt_subscribe_topic, 0, function(client) print("subscribe "..mqtt_subscribe_topic.." success") end)
	mqtt_status = 1
	publish()
end)
m:on("offline", function(client)
	print ("MQTT client offline")
	mqtt_status = 0
end)

-- on message receive event
m:on("message", function(client, topic, data) 
--  print(topic .. ":" ) 
  if data ~= nil then
    -- print(data)
	print("received:", data)
	if(data == 'on')
		then
			pump_delay = pump_delay_init
		else
			pump_delay = 0
		end
  end
end)

function publish()
	if mqtt_status ~= 1 then
		return
	end

	adcvalue = 1023-adc.read(0)
	pub_str = "{\"topic\":\""..mqtt_client_id.."\",\"value\":"..adcvalue.."}"
	m:publish(mqtt_publish_topic, pub_str, 0, 0, function(client) print("publish:\t" .. pub_str) end)
end



disp_timer = tmr.create()
disp_timer:register(5000, 1, function()
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
end)
disp_timer:start()


LED_warning = 0

pump_timer = tmr.create()
pump_timer:register(1000, 1, function()
	if(pump_delay <= 0)
	then
		gpio.write(pin,gpio.LOW)
		pump_delay = 0
	else
		pump_delay = pump_delay - 1
		gpio.write(pin,gpio.HIGH)
	end

	if(mqtt_status ~= 1) then
		if(LED_warning == 0) then
			gpio.write(0,gpio.LOW)
			LED_warning = 1
		else
			gpio.write(0,gpio.HIGH)
			LED_warning = 0
		end
	else
		gpio.write(0,gpio.HIGH)
	end
end)
pump_timer:start()

mytimer = tmr.create()
mytimer:register(scan_interval, 1, function() publish() end)
mytimer:start()

