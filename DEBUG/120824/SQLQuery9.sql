declare @p2 xml
set @p2=convert(xml,N'<row idAntetBon="1108" UID="D8EA4C23-86B6-5611-74A8-58EF0BD02FE8"/>')
exec wDescarcBon @sesiune='750C51CE47F27',@parXML=@p2