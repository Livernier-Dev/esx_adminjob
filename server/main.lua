ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

if Config.MaxInService ~= -1 then
	TriggerEvent('esx_service:activateService', 'ADMIN', Config.MaxInService)
end

TriggerEvent('esx_phone:registerNumber', 'admin', _U('alert_admin'), true, true)
TriggerEvent('esx_society:registerSociety', 'admin', 'admin', 'society_admin', 'society_admin', 'society_admin', {type = 'public'})

ESX.RegisterServerCallback('esx_adminjob:getVehicleFromadmin', function (source, cb)
	MySQL.Async.fetchAll('SELECT *, date_format(time, "%Y-%m-%d") AS time FROM owned_vehicles WHERE admin = @admin', {
		['@admin'] =1
	}, function (result)

		local vehicles = {}

		for i=1, #result, 1 do
			
			table.insert(vehicles, {
				owner         = result[i].owner,
				plate = result[i].plate,
				vehicle     = result[i].vehicle,
				type = result[i].type,
				job     = result[i].job,
				stored      = result[i].stored,
				fourrieremecano     = result[i].fourrieremecano,
				vehiclename		  = result[i].vehiclename,
				buyer		  = result[i].buyer,
				properties		  = result[i].properties,
				admin		  = result[i].admin,
				admin_by		  = result[i].admin_by,
				time		  = result[i].time
			})
		end

		cb(vehicles)
	end)
end)

RegisterServerEvent('esx_adminjob:updateVehicleFromadmin')
AddEventHandler('esx_adminjob:updateVehicleFromadmin', function(plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `admin` = @admin, `admin_by` = @admin_by, `time` = NOW() WHERE plate = @plate', {
		['@admin'] = 1,
		['@plate'] = plate,
		['@admin_by'] = xPlayer.name
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print("ERROR Update setVehicleFromadmin")
		end
	end)
end)


RegisterServerEvent('esx_adminjob:setVehicleFromadmin')
AddEventHandler('esx_adminjob:setVehicleFromadmin', function(plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored, `admin` = @admin, `admin_by` = @admin_by WHERE plate = @plate', {
		['@stored'] = false,
		['@admin'] = 0,
		['@plate'] = plate,
		['@admin_by'] = nil
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print("ERROR Update setVehicleFromadmin")
		end
	end)
end)

RegisterServerEvent('Xenon:RecivePound')
AddEventHandler('Xenon:RecivePound', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local xItem = xPlayer.getInventoryItem('pound')

	if xItem.limit ~= -1 and xItem.count +1 > xItem.limit then
		TriggerClientEvent("pNotify:SendNotification",source,
		{text = " <center><b style ='color:yellow'>????????????????????????????????????????????????????????????",
		type = "alert", timeout = 5000, 
		layout = "topCenter"})	
	else
		xPlayer.addInventoryItem('pound', 1)
	end



	
end)

RegisterServerEvent('esx_adminjob:confiscatePlayerItem')
AddEventHandler('esx_adminjob:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	-- if sourceXPlayer.job.name ~= 'admin' then
	-- 	print(('esx_adminjob: %s attempted to confiscate!'):format(xPlayer.identifier))
	-- 	return
	-- end
	
	if amount == nil then
		TriggerClientEvent("pNotify:SendNotification", _source, {
			text = '<strong class="red-text">?????????????????????????????????????????????????????????</strong>',
			type = "error",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		return
	end

	if itemType == 'item_standard' then
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		if targetItem.count > 0 then

			if targetItem.count < amount then

				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
					type = "error",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})

			else
				
				if sourceItem.limit ~= -1 and (sourceItem.count + amount) > sourceItem.limit then
					TriggerClientEvent("pNotify:SendNotification", target, {
						text = '<strong class="red-text">??????????????????????????????????????????????????????????????????????????????????????????</strong>',
						type = "error",
						timeout = 3000,
						layout = "bottomCenter",
						queue = "global"
					})
				else
					targetXPlayer.removeInventoryItem(itemName, amount)
					sourceXPlayer.addInventoryItem(itemName, amount)
					TriggerClientEvent("pNotify:SendNotification", _source, {
						text = '??????????????????????????? <strong class="amber-text">'..sourceItem.label..'</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ?????????????????? <strong class="blue-text">'..targetXPlayer.name..'</strong> ???????????????????????????????????????',
						type = "success",
						timeout = 3000,
						layout = "bottomCenter",
						queue = "global"
					})
					TriggerClientEvent("pNotify:SendNotification", target, {
						text = '??????????????? <strong class="amber-text">'..sourceItem.label..'</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ????????????????????????????????????????????????',
						type = "success",
						timeout = 3000,
						layout = "bottomCenter",
						queue = "global"
					})

					local content = '' .. sourceXPlayer.name .. ' ????????? ' .. sourceItem.label .. ' ????????? ' .. targetXPlayer.name .. ' ??????????????? ' .. ESX.Math.GroupDigits(amount) .. ''
					TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeItem', content, sourceXPlayer.source, '^5')

					Citizen.Wait(100)
										
					local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ' .. sourceItem.label .. ' ????????? ' .. sourceXPlayer.name .. ' ??????????????? ' .. ESX.Math.GroupDigits(amount) .. ''
					TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeItem', content2, targetXPlayer.source, '^7')
				end
			end
		else
			TriggerClientEvent("pNotify:SendNotification", _source, {
				text = '<strong class="red-text">??????????????????????????????????????????????????? '..targetItem.label..'</strong>',
				type = "error",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})
		end
	elseif itemType == 'item_money' then
		if amount <= 0 then
			TriggerClientEvent("pNotify:SendNotification", _source, {
				text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
				type = "error",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})
		else

			local targetMoney = ESX.GetPlayerFromId(targetXPlayer.source).getMoney()
			
			if targetMoney < amount then
				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
					type = "error",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})
			else

				targetXPlayer.removeMoney(amount)
				sourceXPlayer.addMoney (amount)

				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '??????????????????????????? <strong class="amber-text">??????????????????</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ?????????????????? <strong class="blue-text">'..targetXPlayer.name..'</strong> ???????????????????????????????????????',
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})
				TriggerClientEvent("pNotify:SendNotification", target, {
					text = '??????????????? <strong class="amber-text">??????????????????</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ????????????????????????????????????????????????',
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})

				local content = '' .. sourceXPlayer.name .. ' ????????? ?????????????????? ????????? ' .. targetXPlayer.name .. ' ??????????????? $' .. ESX.Math.GroupDigits(amount) .. ''
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeMoney', content, sourceXPlayer.source, '^5')

				Citizen.Wait(100)
									
				local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ?????????????????? ????????? ' .. sourceXPlayer.name .. ' ??????????????? $' .. ESX.Math.GroupDigits(amount) .. ''
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeMoney', content2, targetXPlayer.source, '^7')
			end

		end
	elseif itemType == 'item_account' then
		if amount <= 0 then
			TriggerClientEvent("pNotify:SendNotification", _source, {
				text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>'..amount,
				type = "error",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})
		else

			local targetMoney = targetXPlayer.getAccount(itemName).money

			if targetMoney < amount then
				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
					type = "error",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})
			else

				targetXPlayer.removeAccountMoney(itemName, amount)
				sourceXPlayer.addAccountMoney(itemName, amount)

				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '??????????????????????????? <strong class="amber-text">'..itemName..'</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ?????????????????? <strong class="blue-text">'..targetXPlayer.name..'</strong> ???????????????????????????????????????',
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})
				TriggerClientEvent("pNotify:SendNotification", target, {
					text = '??????????????? <strong class="amber-text">'..itemName..'</strong> ??????????????? <strong class="amber-text">'..amount..'</strong> ????????????????????????????????????????????????',
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})

				local content = '' .. sourceXPlayer.name .. ' ????????? ' .. itemName .. ' ????????? ' .. targetXPlayer.name .. ' ??????????????? $' .. ESX.Math.GroupDigits(amount) .. ''
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeDirtyMoney', content, sourceXPlayer.source, '^5')

				Citizen.Wait(100)
									
				local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ' .. itemName .. ' ????????? ' .. sourceXPlayer.name .. ' ??????????????? $' .. ESX.Math.GroupDigits(amount) .. ''
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeDirtyMoney', content2, targetXPlayer.source, '^7')
			end

		end
	elseif itemType == 'item_weapon' then
		if amount == nil then amount = 0 end
		targetXPlayer.removeWeapon(itemName, amount)
		sourceXPlayer.addWeapon(itemName, amount)

		TriggerClientEvent("pNotify:SendNotification", _source, {
			text = '??????????????????????????? <strong class="amber-text">'..ESX.GetWeaponLabel(itemName)..'</strong> ????????????????????????????????? <strong class="amber-text">'..amount..'</strong> ?????????????????? <strong class="blue-text">'..targetXPlayer.name..'</strong> ???????????????????????????????????????',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = '??????????????? <strong class="amber-text">'..ESX.GetWeaponLabel(itemName)..'</strong> ????????????????????????????????? <strong class="amber-text">'..amount..'</strong> ????????????????????????????????????????????????',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})

		
		if amount > 0 then
			local content = '' .. sourceXPlayer.name .. ' ????????? ' .. ESX.GetWeaponLabel(itemName) .. ' ????????? ' .. targetXPlayer.name .. ' ????????? ?????????????????? ??????????????? ' .. ESX.Math.GroupDigits(amount) .. ''
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeWeapon', content, sourceXPlayer.source, '^5')

			Citizen.Wait(100)
						
			local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ' .. ESX.GetWeaponLabel(itemName) .. ' ????????? ' .. sourceXPlayer.name .. ' ????????? ?????????????????? ??????????????? ' .. ESX.Math.GroupDigits(amount) .. ''
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeWeapon', content2, targetXPlayer.source, '^7')
		else
			local content = '' .. sourceXPlayer.name .. ' ????????? ' .. ESX.GetWeaponLabel(itemName) .. ' ????????? ' .. targetXPlayer.name .. '  ??????????????? 1'
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeWeapon', content, sourceXPlayer.source, '^5')

			Citizen.Wait(100)
						
			local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ' .. ESX.GetWeaponLabel(itemName) .. ' ????????? ' .. sourceXPlayer.name .. ' ??????????????? 1'
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeWeapon', content2, targetXPlayer.source, '^7')
		end
	elseif itemType == "item_key" then -- MEETA GiveKey

		MySQL.Async.execute("UPDATE owned_vehicles SET owner = @newplayer WHERE owner = @identifier AND plate = @plate",
		{
			['@newplayer']		= sourceXPlayer.identifier,
			['@identifier']		= targetXPlayer.identifier,
			['@plate']		= itemName
		})
		
		TriggerClientEvent("pNotify:SendNotification", _source, {
			text = '??????????????????????????? <strong class="amber-text">?????????????????????</strong> ????????????????????? <strong class="yellow-text">'..itemName..'</strong>',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = '??????????????? <strong class="amber-text">?????????????????????</strong> ????????????????????? <strong class="yellow-text">'..itemName..'</strong> ????????????????????????????????????????????????',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		
		TriggerClientEvent("esx_inventoryhud:getOwnerVehicle", _source)
		TriggerClientEvent("esx_inventoryhud:getOwnerVehicle", target)

		local content = '' .. sourceXPlayer.name .. ' ????????? ????????????????????? ????????? ' .. targetXPlayer.name .. ' ????????????????????? ' .. itemName .. ''
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeKey', content, sourceXPlayer.source, '^5')

		Citizen.Wait(100)
							
		local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ????????????????????? ????????? ' .. sourceXPlayer.name .. ' ????????????????????? ' .. itemName .. ''
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeKey', content2, targetXPlayer.source, '^7')
	elseif itemType == "item_keyhouse" then -- MEETA GiveKeyHouse

		MySQL.Async.execute("UPDATE owned_properties SET owner = @newplayer WHERE owner = @identifier AND id = @id",
		{
			['@newplayer']		= sourceXPlayer.identifier,
			['@identifier']		= targetXPlayer.identifier,
			['@id']		= itemName
		})

		TriggerClientEvent("pNotify:SendNotification", _source, {
			text = '??????????????????????????? <strong class="amber-text">???????????????????????????</strong>',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		TriggerClientEvent("pNotify:SendNotification", target, {
			text = '??????????????? <strong class="amber-text">???????????????????????????</strong> ??????????????????????????? <strong class="blue-text">'.. sourceXPlayer.name ..'</strong> ????????????????????????????????????????????????',
			type = "success",
			timeout = 3000,
			layout = "bottomCenter",
			queue = "global"
		})
		
		TriggerClientEvent("esx_inventoryhud:getOwnerHouse", _source)
		TriggerClientEvent("esx_inventoryhud:getOwnerHouse", target)

		local content = '' .. sourceXPlayer.name .. ' ????????? ??????????????????????????? ????????? ' .. targetXPlayer.name .. ''
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeKey', content, sourceXPlayer.source, '^5')

		Citizen.Wait(100)
							
		local content2 = '' .. targetXPlayer.name .. ' ?????????????????? ??????????????????????????? ????????? ' .. sourceXPlayer.name .. ''
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminSeizeKey', content2, targetXPlayer.source, '^7')
	end
end)

RegisterServerEvent('esx_adminjob:handcuff')
AddEventHandler('esx_adminjob:handcuff', function(target, playerheading, playerCoords, playerlocation)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'admin' then
		--TriggerClientEvent('esx_adminjob:handcuff', target)
		TriggerClientEvent('esx_adminjob:getarrested', target, playerheading, playerCoords, playerlocation)
    	TriggerClientEvent('esx_adminjob:doarrested', source)
	else
		print(('esx_adminjob: %s attempted to handcuff a player (not cop)!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_adminjob:unhandcuff')
AddEventHandler('esx_adminjob:unhandcuff', function(target, playerheading, playerCoords, playerlocation)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'admin' then
		--TriggerClientEvent('esx_adminjob:handcuff', target)
		TriggerClientEvent('esx_adminjob:getuncuffed', target, playerheading, playerCoords, playerlocation)
    	TriggerClientEvent('esx_adminjob:douncuffing', source)
	else
		print(('esx_adminjob: %s attempted to handcuff a player (not cop)!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_adminjob:drag')
AddEventHandler('esx_adminjob:drag', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'admin' then
		TriggerClientEvent('esx_adminjob:drag', target, source)
	else
		print(('esx_adminjob: %s attempted to drag (not cop)!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_adminjob:putInVehicle')
AddEventHandler('esx_adminjob:putInVehicle', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'admin' then
		TriggerClientEvent('esx_adminjob:putInVehicle', target)
	else
		print(('esx_adminjob: %s attempted to put in vehicle (not cop)!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_adminjob:OutVehicle')
AddEventHandler('esx_adminjob:OutVehicle', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'admin' then
		TriggerClientEvent('esx_adminjob:OutVehicle', target)
	else
		print(('esx_adminjob: %s attempted to drag out from vehicle (not cop)!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_adminjob:getStockItem')
AddEventHandler('esx_adminjob:getStockItem', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_admin', function(inventory)

		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then
		
			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})
			else
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent("pNotify:SendNotification", _source, {
					text = _U('have_withdrawn', count, inventoryItem.label),
					type = "success",
					timeout = 3000,
					layout = "bottomCenter",
					queue = "global"
				})

				local content = '' .. xPlayer.name .. ' ?????? ' .. inventoryItem.label .. ' ??????????????? ' .. ESX.Math.GroupDigits(count) .. ' ??????????????????????????????'
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminGetStockItem', content, xPlayer.source, '^3')
			end
		else
			TriggerClientEvent("pNotify:SendNotification", _source, {
				text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
				type = "success",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})
		end
	end)

end)

RegisterServerEvent('esx_adminjob:putStockItems')
AddEventHandler('esx_adminjob:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_admin', function(inventory)

		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = _U('have_withdrawn', count, inventoryItem.label),
				type = "success",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})

			local content = '' .. xPlayer.name .. ' ???????????? ' .. inventoryItem.label .. ' ??????????????? ' .. ESX.Math.GroupDigits(count) .. ' ????????????????????????'
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminPutStockItem', content, xPlayer.source, '^2')
		else
			TriggerClientEvent("pNotify:SendNotification", source, {
				text = '<strong class="red-text">??????????????????????????????????????????????????????</strong>',
				type = "success",
				timeout = 3000,
				layout = "bottomCenter",
				queue = "global"
			})
		end

	end)

end)

ESX.RegisterServerCallback('esx_adminjob:getOtherPlayerData', function(source, cb, target)

	if Config.EnableESXIdentity then

		local xPlayer = ESX.GetPlayerFromId(target)

		local result = MySQL.Sync.fetchAll('SELECT firstname, lastname, sex, dateofbirth, height FROM users WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		})

		local firstname = result[1].firstname
		local lastname  = result[1].lastname
		local sex       = result[1].sex
		local dob       = result[1].dateofbirth
		local height    = result[1].height

		local data = {
			name      = GetPlayerName(target),
			job       = xPlayer.job,
			inventory = xPlayer.inventory,
			accounts  = xPlayer.accounts,
			weapons   = xPlayer.loadout,
			firstname = firstname,
			lastname  = lastname,
			sex       = sex,
			dob       = dob,
			height    = height
		}

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status ~= nil then
				data.drunk = math.floor(status.percent)
			end
		end)

		if Config.EnableLicenses then
			TriggerEvent('esx_license:getLicenses', target, function(licenses)
				data.licenses = licenses
				cb(data)
			end)
		else
			cb(data)
		end

	else

		local xPlayer = ESX.GetPlayerFromId(target)

		local data = {
			name       = GetPlayerName(target),
			job        = xPlayer.job,
			inventory  = xPlayer.inventory,
			accounts   = xPlayer.accounts,
			weapons    = xPlayer.loadout
		}

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status ~= nil then
				data.drunk = math.floor(status.percent)
			end
		end)

		TriggerEvent('esx_license:getLicenses', target, function(licenses)
			data.licenses = licenses
		end)

		cb(data)

	end

end)

ESX.RegisterServerCallback('esx_adminjob:getFineList', function(source, cb, category)
	MySQL.Async.fetchAll('SELECT * FROM fine_types WHERE category = @category', {
		['@category'] = category
	}, function(fines)
		cb(fines)
	end)
end)

ESX.RegisterServerCallback('esx_adminjob:getVehicleInfos', function(source, cb, plate)

	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)

		local retrivedInfo = {
			plate = plate
		}

		if result[1] then

			MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier',  {
				['@identifier'] = result[1].owner
			}, function(result2)

				if Config.EnableESXIdentity then
					retrivedInfo.owner = result2[1].firstname .. ' ' .. result2[1].lastname
				-- else
					-- retrivedInfo.owner = result2[1].name
				end

				cb(retrivedInfo)
			end)
		else
			cb(retrivedInfo)
		end
	end)
end)

function string:split(delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( self, delimiter, from  )
	while delim_from do
	  table.insert( result, string.sub( self, from , delim_from-1 ) )
	  from  = delim_to + 1
	  delim_from, delim_to = string.find( self, delimiter, from  )
	end
	table.insert( result, string.sub( self, from  ) )
	return result
  end

ESX.RegisterServerCallback('esx_adminjob:getVehicleByName', function(source, cb, name)
	local FullName = name.split(name," +")
	MySQL.Async.fetchAll('SELECT * FROM users WHERE firstname = @firstname AND lastname = @lastname', {
		['@firstname'] = FullName[1],
		['@lastname'] = FullName[2],
	}, function(result)
		if result[1] ~= nil then

			MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @identifier',  {
				['@identifier'] = result[1].identifier
			}, function(result2)
				cb(result2, true)
				

			end)
		else
			cb(_U('unknown'), false)
		end
	end)
end)

ESX.RegisterServerCallback('esx_adminjob:getHouseByName', function(source, cb, name)
	local FullName = name.split(name," +")
	MySQL.Async.fetchAll('SELECT * FROM users WHERE firstname = @firstname AND lastname = @lastname', {
		['@firstname'] = FullName[1],
		['@lastname'] = FullName[2],
	}, function(result)
		if result[1] ~= nil then

			MySQL.Async.fetchAll("SELECT * FROM owned_properties WHERE owner = @identifier", {
				['@identifier'] = result[1].identifier,
			}, function(result2)
	
				cb(result2, true)
	
			end)

		else
			cb(_U('unknown'), false)
		end
	end)
end)

ESX.RegisterServerCallback('esx_adminjob:getVehicleFromPlate', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		if result[1] ~= nil then

			MySQL.Async.fetchAll('SELECT name, firstname, lastname FROM users WHERE identifier = @identifier',  {
				['@identifier'] = result[1].owner
			}, function(result2)

				if Config.EnableESXIdentity then
					cb(result2[1].firstname .. ' ' .. result2[1].lastname, true)
				else
					cb(result2[1].name, true)
				end

			end)
		else
			cb(_U('unknown'), false)
		end
	end)
end)

ESX.RegisterServerCallback('esx_adminjob:getArmoryWeapons', function(source, cb)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_admin', function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		cb(weapons)
	end)

end)

ESX.RegisterServerCallback('esx_adminjob:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)

	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)

		local content = '' .. xPlayer.name .. ' ???????????? ' .. ESX.GetWeaponLabel(weaponName) .. ' ????????????????????????'
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminPutArmoryWeapon', content, xPlayer.source, '^2')
	end

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_admin', function(store)

		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)

end)

ESX.RegisterServerCallback('esx_adminjob:removeArmoryWeapon', function(source, cb, weaponName)

	local xPlayer = ESX.GetPlayerFromId(source)

	xPlayer.addWeapon(weaponName, 500)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_admin', function(store)

		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)

	local content = '' .. xPlayer.name .. ' ???????????? ' .. ESX.GetWeaponLabel(weaponName) .. ' ????????? ?????????????????? ??????????????? 500 ?????????????????????'
	TriggerEvent('azael_dc-serverlogs:insertData', 'adminGetArmoryWeapon', content, xPlayer.source, '^3')
end)

ESX.RegisterServerCallback('esx_adminjob:buyWeapon', function(source, cb, weaponName, type, componentNum)
	local xPlayer = ESX.GetPlayerFromId(source)
	local authorizedWeapons, selectedWeapon = Config.AuthorizedWeapons[xPlayer.job.grade_name]

	for k,v in ipairs(authorizedWeapons) do
		if v.weapon == weaponName then
			selectedWeapon = v
			break
		end
	end

	if not selectedWeapon then
		print(('esx_adminjob: %s attempted to buy an invalid weapon.'):format(xPlayer.identifier))
		cb(false)
	end

	-- Weapon
	if type == 1 then
		if xPlayer.getMoney() >= selectedWeapon.price then
			xPlayer.removeMoney(selectedWeapon.price)
			xPlayer.addWeapon(weaponName, 100)

			local content = '' .. xPlayer.name .. ' ???????????? ' .. ESX.GetWeaponLabel(weaponName) .. ' ????????? ?????????????????? ??????????????? 100 ???????????? $' .. ESX.Math.GroupDigits(selectedWeapon.price) .. ''
			TriggerEvent('azael_dc-serverlogs:insertData', 'adminBuyWeapon', content, xPlayer.source, '^4')

			cb(true)
		else
			cb(false)
		end

	-- Weapon Component
	elseif type == 2 then
		local price = selectedWeapon.components[componentNum]
		local weaponNum, weapon = ESX.GetWeapon(weaponName)

		local component = weapon.components[componentNum]

		if component then
			if xPlayer.getMoney() >= price then
				xPlayer.removeMoney(price)
				xPlayer.addWeaponComponent(weaponName, component.name)

				local content = '' .. xPlayer.name .. ' ???????????? ' .. component.label .. ' ?????????????????????????????????????????????????????? ' .. ESX.GetWeaponLabel(weaponName) .. ' ???????????? $' .. ESX.Math.GroupDigits(price)  .. ''
				TriggerEvent('azael_dc-serverlogs:insertData', 'adminBuyWeapon', content, xPlayer.source, '^5')

				cb(true)
			else
				cb(false)
			end
		else
			print(('esx_adminjob: %s attempted to buy an invalid weapon component.'):format(xPlayer.identifier))
			cb(false)
		end
	end
end)


ESX.RegisterServerCallback('esx_adminjob:buyJobVehicle', function(source, cb, vehicleProps, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = getPriceFromHash(vehicleProps.model, xPlayer.job.grade_name, type)

	-- vehicle model not found
	if price == 0 then
		print(('esx_adminjob: %s attempted to exploit the shop! (invalid vehicle model)'):format(xPlayer.identifier))
		cb(false)
	end

	if xPlayer.getMoney() >= price then
		xPlayer.removeMoney(price)
		TriggerClientEvent("esx_inventoryhud:getOwnerVehicle", source)
		MySQL.Async.execute('INSERT INTO owned_vehicles (owner, vehicle, plate, type, job, `stored`) VALUES (@owner, @vehicle, @plate, @type, @job, @stored)', {
			['@owner'] = xPlayer.identifier,
			['@vehicle'] = json.encode(vehicleProps),
			['@plate'] = vehicleProps.plate,
			['@type'] = type,
			['@job'] = xPlayer.job.name,
			['@stored'] = true
		}, function (rowsChanged)
			cb(true)
		end)

		local content = '' .. xPlayer.name .. ' ?????????????????? ' .. vehicleProps.model .. ' ????????????????????? ' .. vehicleProps.plate .. ' ???????????? $' .. ESX.Math.GroupDigits(price) .. ''
		TriggerEvent('azael_dc-serverlogs:insertData', 'adminBuyVehicle', content, xPlayer.source, '^2')
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_adminjob:storeNearbyVehicle', function(source, cb, nearbyVehicles)
	local xPlayer = ESX.GetPlayerFromId(source)
	local foundPlate, foundNum

	for k,v in ipairs(nearbyVehicles) do
		local result = MySQL.Sync.fetchAll('SELECT plate FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = v.plate,
			['@job'] = xPlayer.job.name
		})

		if result[1] then
			foundPlate, foundNum = result[1].plate, k
			break
		end
	end

	if not foundPlate then
		cb(false)
	else
		MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = foundPlate,
			['@job'] = xPlayer.job.name
		}, function (rowsChanged)
			if rowsChanged == 0 then
				--print(('esx_adminjob: %s has exploited the garage!'):format(xPlayer.identifier))
				cb(false)
			else
				cb(true, foundNum)
			end
		end)
	end

end)

function getPriceFromHash(hashKey, jobGrade, type)
	if type == 'helicopter' then
		local vehicles = Config.AuthorizedHelicopters[jobGrade]

		for k,v in ipairs(vehicles) do
			if GetHashKey(v.model) == hashKey then
				return v.price
			end
		end
	elseif type == 'car' then
		local vehicles = Config.AuthorizedVehicles[jobGrade]
		local shared = Config.AuthorizedVehicles['Shared']

		for k,v in ipairs(vehicles) do
			if GetHashKey(v.model) == hashKey then
				return v.price
			end
		end

		for k,v in ipairs(shared) do
			if GetHashKey(v.model) == hashKey then
				return v.price
			end
		end
	end

	return 0
end

ESX.RegisterServerCallback('esx_adminjob:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_admin', function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('esx_adminjob:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb( { items = items } )
end)

--[[ AddEventHandler('playerDropped', function()
	-- Save the source in case we lose it (which happens a lot)
	local _source = source
	
	-- Did the player ever join?
	if _source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(_source)
		
		-- Is it worth telling all clients to refresh?
		if xPlayer ~= nil and xPlayer.job ~= nil and xPlayer.job.name == 'admin' then
			Citizen.Wait(5000)
			TriggerClientEvent('esx_adminjob:updateBlip', -1)
		end
	end	
end) ]]

--[[ RegisterServerEvent('esx_adminjob:spawned')
AddEventHandler('esx_adminjob:spawned', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	
	if xPlayer ~= nil and xPlayer.job ~= nil and xPlayer.job.name == 'admin' then
		Citizen.Wait(5000)
		TriggerClientEvent('esx_adminjob:updateBlip', -1)
	end
end) ]]

--[[ RegisterServerEvent('esx_adminjob:forceBlip')
AddEventHandler('esx_adminjob:forceBlip', function()
	TriggerClientEvent('esx_adminjob:updateBlip', -1)
end) ]]

--[[ AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(5000)
		TriggerClientEvent('esx_adminjob:updateBlip', -1)
	end
end) ]]

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_phone:removeNumber', 'admin')
	end
end)

RegisterServerEvent('esx_adminjob:message')
AddEventHandler('esx_adminjob:message', function(target, msg)
	TriggerClientEvent("pNotify:SendNotification", target, {
		text = msg,
		type = "success",
		timeout = 3000,
		layout = "bottomCenter",
		queue = "global"
	})
end)