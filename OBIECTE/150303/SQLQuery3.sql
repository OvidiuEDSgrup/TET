declare @x xml

--set @x=
--	(select distinct c.idContract, 'Aprobat' explicatii, 2 stare, GETDATE() data 
--	from necesaraprov n 
--		join contracte c on c.tip='RN' and c.numar=n.Numar and c.data=n.Data
--		join PozContracte p on p.idContract=c.idContract and p.idPozContract=n.Numar_pozitie
--	where Stare>=1
--	for xml raw, root('Date'))
set @x=(
select  c.numar, c.idContract, RTRIM(p.denstare) explicatii, p.stare stare, GETDATE() data 
--,*
	from contracte c
		cross apply 
			(select top (1) stare=coalesce(n.Stare,-15)*10,denstare=RTRIM(s.denumire) 
			from PozContracte p 
				left join necesaraprov n on c.numar=n.Numar and c.data=n.Data and p.idPozContract=n.Numar_pozitie
				outer apply (select top 1 stare from JurnalContracte jc where jc.idContract=c.idContract order by data desc,idJurnal desc) uj
				left join StariContracte s on s.tipContract=c.tip and s.stare=coalesce(n.stare,-15)
			where  c.tip='RN' and c.idContract=p.idContract and coalesce(n.Stare,-15)<>isnull(uj.stare,-15)
			order by coalesce(n.Stare,-15) desc
			) p
	--where c.numar like 'CJ910003'
	order by c.idContract
	for xml raw, root('Date'))
select @x

EXEC wScriuJurnalContracte @sesiune = '', @parXML = @x OUTPUT

/*Le trecem in starea de In Pregatire*/
	--if (select count(*) from #contractedeverificat)>0
	--begin
	--	declare @starePicking varchar(2),@docJurnal xml
	--	select @starePicking=max(stare) from staricontracte where tipcontract='CL' and transportabil=1
	--	SELECT @docJurnal = (
	--		SELECT idContract idContract, 'La coletizare' explicatii, @starePicking stare,GETDATE() data 
	--			from #contractedeverificat 
	--			outer apply (select top 1 idJurnal from JurnalContracte jc where jc.idContract=#ContracteDeVerificat.idContract and stare=@starePicking order by idJurnal desc) uj
	--			where uj.idJurnal is null
	--			FOR XML raw,root('Date'))
	--	EXEC wScriuJurnalContracte @sesiune = '', @parXML = @docJurnal OUTPUT
	--end