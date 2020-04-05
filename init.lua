pin = 0

wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid="NETGEAR94"
station_cfg.pwd="mistyumbrella309"
wifi.sta.config(station_cfg)

mqtt_client_id = "melinda_01"
mqtt_server = "iot.binya.tech"
mqtt_username = ""
mqtt_password = ""
mqtt_port = 1883
mqtt_publish_topic = "/home/env/flowers"
mqtt_status = 0

-- init mqtt client with logins, keepalive timer 120s
mqttClient = mqtt.Client(mqtt_client_id, 120)
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client dont send keepalive packet
-- mqttClient:lwt("/lwt", "offline", 0, 0)

mqttClient:on("connect", function(client)
	print ("MQTT client connected")
	mqtt_status = 1
end)
mqttClient:on("offline", function(client)
	print ("MQTT client offline")
	mqtt_status = 0
end)

-- on message receive event
mqttClient:on("message", function(client, topic, data) 
--  print(topic .. ":" ) 
  if data ~= nil then
    print("received : ", data)
  end
end)


function publish(mq_client)
	if(wifi.sta.status() ~= wifi.STA_GOTIP)
	then
		print("WiFi disconnect")
		return
	end
	
	print(wifi.sta.getip())
	if(mqtt_status == 0)
	then
		print("MQTT connection lost")
		return
	end
	
	adcvalue = 1023-adc.read(0)
	-- pub_str = adcvalue
	pub_str = "{\"topic\":\""..mqtt_client_id.."\",\"value\":"..adcvalue.."}"
	client:subscribe(mqtt_publish_topic, 0, function(client) print("subscribe success") end)
	mqttClient:publish(mqtt_publish_topic, pub_str, 0, 0, function(client) print(pub_str) end)
end


mqttClient:connect(mqtt_server, mqtt_port, 0, 0,
function(client)
	print("MQTT connected")
end,
function(client, reason)
  print("failed reason: " .. reason)
end)

mytimer = tmr.create()
mytimer:register(5000, 1, function() publish(mqttClient) end)
mytimer:start()

