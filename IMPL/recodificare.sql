	DECLARE @codVechi char(30), @codNou char(30), @pas int
	
	update nomencl_coduri_mari
	set codnou=''
	
	declare crs_nom cursor for
	select cod from nomencl_coduri_mari
	
	OPEN crs_nom
	FETCH NEXT FROM crs_nom INTO @codVechi
	
	WHILE @@FETCH_STATUS<>-1
	BEGIN
		--select top 1 @codVechi=cod from nomencl_coduri_mari
		set @codNou=LEFT(@codVechi,20)
		set @pas=0
		while @pas<702 
			and (exists (select 1 from nomencl n where cod=@codNou) 
				or exists (select 1 from nomencl_coduri_mari n where cod=@codNou)
				or exists (select 1 from nomencl_coduri_mari n where codnou=@codNou)) 
		begin
			set @pas=@pas+1
			set @codNou=RTrim(left(@codVechi,(case when @pas<=26 then 19 else 18 end)))+RTrim((case when @pas>26 then CHAR(64+(@pas-1)/26) else '' end))+CHAR(64+(@pas-1)%26+1)
		end
		--print @codnou
		--INSERT nomencl_coduri_coresp (codvechi,codnou)
		--VALUES (@codVechi,@codNou)
		update nomencl_coduri_mari
		set codnou=@codNou
		where current of crs_nom
		FETCH NEXT FROM crs_nom INTO @codVechi
	END
	
	CLOSE crs_nom
	DEALLOCATE crs_nom
	
	select codnou,* from nomencl_coduri_mari 
	--where codnou in 
	--(
 -- select codnou
 -- from nomencl_coduri_mari
 -- group by codnou
 -- having COUNT(*)>1)

--select top 0 n2.cod codvechi,n1.cod codnou
--into nomencl_coduri_coresp 
--from nomencl n1 join nomencl_coduri_mari n2 on n1.Cod=n2.Cod
	--alter table nomencl_coduri_mari add codnou char(20) not null default ''
	--select char(26)
--select ncc.codnou,ncc.codvechi,
--ncm.* from nomencl_coduri_coresp ncc join nomencl_coduri_mari ncm on ncc.codvechi=ncm.Cod