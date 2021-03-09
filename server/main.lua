ESX = nil
local playersProcessingfarm = {}
local outofbound = true
local alive = true

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_farm:sellFarm')
AddEventHandler('esx_farm:sellFarm', function(itemName, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = Config.FarmDealerItems[itemName]
	local xItem = xPlayer.getInventoryItem(itemName)

	if not price then
		print(('esx_farm: %s attempted to sell an invalid Farm!'):format(xPlayer.identifier))
		return
	end

	if xItem.count < amount then
		xPlayer.showNotification(_U('dealer_notenough'))
		return
	end

	price = ESX.Math.Round(price * amount)

	if Config.GiveBlack then
		xPlayer.addAccountMoney('black_money', price)
	else
		xPlayer.addMoney(price)
	end

	xPlayer.removeInventoryItem(xItem.name, amount)
	xPlayer.showNotification(_U('dealer_sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
end)

ESX.RegisterServerCallback('esx_farm:buyLicense', function(source, cb, licenseName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local license = Config.LicensePrices[licenseName]

	if license then
		if xPlayer.getMoney() >= license.price then
			xPlayer.removeMoney(license.price)

			TriggerEvent('esx_license:addLicense', source, licenseName, function()
				cb(true)
			end)
		else
			cb(false)
		end
	else
		print(('esx_farm: %s attempted to buy an invalid license!'):format(xPlayer.identifier))
		cb(false)
	end
end)

RegisterServerEvent('esx_farm:pickedUpfarm')
AddEventHandler('esx_farm:pickedUpfarm', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local cime = math.random(5,10)

	if xPlayer.canCarryItem(Config.Item1, cime) then
		xPlayer.addInventoryItem(Config.Item1, cime)
	else
		xPlayer.showNotification(_U('farm_inventoryfull'))
	end
end)

ESX.RegisterServerCallback('esx_farm:canPickUp', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('esx_farm:outofbound')
AddEventHandler('esx_farm:outofbound', function()
	outofbound = true
end)

RegisterServerEvent('esx_farm:quitprocess')
AddEventHandler('esx_farm:quitprocess', function()
	can = false
end)

ESX.RegisterServerCallback('esx_farm:farm_count', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xfarm = xPlayer.getInventoryItem(Config.Item1).count
	cb(xfarm)
end)

RegisterServerEvent('esx_farm:processfarm')
AddEventHandler('esx_farm:processfarm', function()
  if not playersProcessingfarm[source] then
		local _source = source
		local xPlayer = ESX.GetPlayerFromId(_source)
		local xfarm = xPlayer.getInventoryItem(Config.Item1)
		local can = true
		outofbound = false
    if xfarm.count >= 3 then
      while outofbound == false and can do
				if playersProcessingfarm[_source] == nil then
					playersProcessingfarm[_source] = ESX.SetTimeout(Config.Delays.FarmProcessing , function()
            if xfarm.count >= 3 then
              if xPlayer.canSwapItem(Config.Item1, 3, Config.Item2, 1) then
                xPlayer.removeInventoryItem(Config.Item1, 3)
                xPlayer.addInventoryItem(Config.Item2, 1)
								xPlayer.showNotification(_U('farm_processed'))
							else
								can = false
								xPlayer.showNotification(_U('farm_processingfull'))
								TriggerEvent('esx_farm:cancelProcessing')
							end
						else
							can = false
							xPlayer.showNotification(_U('farm_processingenough'))
							TriggerEvent('esx_farm:cancelProcessing')
						end

						playersProcessingfarm[_source] = nil
					end)
				else
					Wait(Config.Delays.FarmProcessing)
				end
			end
		else
			xPlayer.showNotification(_U('farm_processingenough'))
			TriggerEvent('esx_farm:cancelProcessing')
		end

	else
		print(('esx_farm: %s attempted to exploit farm processing!'):format(GetPlayerIdentifiers(source)[1]))
	end
end)

function CancelProcessing(playerId)
	if playersProcessingfarm[playerId] then
		ESX.ClearTimeout(playersProcessingfarm[playerId])
		playersProcessingfarm[playerId] = nil
	end
end

RegisterServerEvent('esx_farm:cancelProcessing')
AddEventHandler('esx_farm:cancelProcessing', function()
	CancelProcessing(source)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
