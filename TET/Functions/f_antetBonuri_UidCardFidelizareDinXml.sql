CREATE function f_antetBonuri_UidCardFidelizareDinXml (@bon xml)
		returns varchar(100)
		with SCHEMABINDING as
		begin 
			return @bon.value('(/date/document/fidelizare/@uidCardFidelizare)[1]','varchar(100)')
		end