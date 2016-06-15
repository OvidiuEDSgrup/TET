--*** 
create procedure wOPAlinierePreturi @sesiune varchar(50), @parXML xml                
as              
/*Va alinia preturile pentru cele cu amanuntul la care pret_amanunt!=pret_amanunt_predator
Ex. apel: 
exec wOPAlinierePreturi '','<row gestiune="MAGN" dataj="2015-03-01" datas="2015-04-10" cod="A1"/>'
	*/
begin

declare @subunitate varchar(9),@gestiune varchar(9),@data datetime, @userASiS varchar(20),@pdataj datetime,@pdatas datetime,@pX xml,@cod varchar(20)

select @gestiune= ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(9)'), ''),
@pdataj = @parXML.value('(/*/@dataj)[1]', 'datetime'),
@pdatas = @parXML.value('(/*/@datas)[1]', 'datetime'),
@cod=ISNULL(@parXML.value('(/*/@cod)[1]', 'varchar(20)'), '')

begin try 

	exec wIaUtilizator @sesiune,@userASiS
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output              
		
	create table #pozAvize(gestiune varchar(20),data datetime,cod_produs varchar(20),cod_intrare varchar(20),pret_amanunt_predator float,tva_neexigibil float,pret_de_stoc float,cantitate float,pret_cu_amanuntul float,codintrareprim varchar(13),idPozdoc int)

	insert into #pozAvize
		select pozdoc.gestiune,pozdoc.data, pozdoc.cod,pozdoc.Cod_intrare,pozdoc.Pret_amanunt_predator,pozdoc.tva_neexigibil,pozdoc.Pret_de_stoc,pozdoc.cantitate,pozdoc.Pret_cu_amanuntul,'MA'+ltrim(str(pozdoc.idpozdoc)) as codintrareprim, pozdoc.idPozDoc
		from pozdoc
		inner join gestiuni g on g.subunitate=pozdoc.subunitate and g.Cod_gestiune=pozdoc.Gestiune
		where g.Tip_gestiune='A' 
		and (@gestiune='' or pozdoc.gestiune=@gestiune)
		and (@cod='' or pozdoc.Cod=@cod)
		and pozdoc.data between @pdataj and @pdatas 
		and pozdoc.Tip_miscare='E' and pozdoc.Tip in ('AP','AC','AE')
		and abs(pozdoc.cantitate)>=0.001 
		and abs(pozdoc.Pret_cu_amanuntul-pozdoc.Pret_amanunt_predator)>=0.02 -- scos: *(1-pozdoc.discount/100)
		and pozdoc.Pret_cu_amanuntul>0.0001
		--and not (pozdoc.tip='TE' and pozdoc.gestiune=pozdoc.gestiune_primitoare)

	if (select count(*) from #pozAvize)=0
	begin
		select 'Nu aveti alinieri de pret in perioada selectata' as textMesaj for xml raw, root('Mesaje')
		return
	end

	select gestiune, data -- documente distincte pe gestiune si data
		into #gestdata
		from #pozAvize
		group by gestiune, data
		order by data, gestiune

	select top 1 @gestiune=gestiune, @data=data from #gestdata

	while @gestiune is not null
	begin
	
		declare @numar varchar(20)
		select @numar='MA'+right(ltrim(rtrim(@gestiune)),6)

		declare @input XMl
		set @input=(select rtrim(@subunitate) as '@subunitate','TE' as '@tip',
			@numar as '@numar', @data as '@data','1' '@fara_luare_date',
			(
			 	select pr.gestiune as '@gestiune',pr.gestiune as '@gestprim',
				rtrim(pr.cod_produs) as '@cod',convert(decimal(12,5),pr.pret_de_stoc) as '@pstoc',
				convert(decimal(12,5),pr.cantitate) as '@cantitate',
				rtrim(pr.cod_intrare) as '@codintrare',convert(decimal(12,2),pr.tva_neexigibil) as '@tva_neexigibil',
				convert(decimal(12,5),pr.Pret_cu_amanuntul) as '@pamanunt',
				pr.codintrareprim as '@codiprimitor'
				from #pozAvize pr 
				where abs(pr.pret_amanunt_predator-pr.Pret_cu_amanuntul)>=0.001 and	pr.gestiune=@gestiune and pr.data=@data
					and pr.cod_intrare<>'' -- nu generam TE de la pozitie cu cod intrare necompletat - trebuie rezolvata altfel problema
				for xml Path,type)
			for xml Path,type)
	
		--Sterg documentul eventual generat anterior
		delete from pozdoc where subunitate=@subunitate and tip='TE' and numar=@numar and data=@data

		exec wScriuPozdoc @sesiune,@input --Merge foarte incet

		delete from #gestdata where gestiune=@gestiune and data=@data
		set @gestiune=null
		select top 1 @gestiune=gestiune, @data=data from #gestdata	
	end

	drop table #gestdata
		
	-- modificam pret_amanunt_predator si cod de intrare 
	
	update pozdoc set pret_amanunt_predator=pozdoc.pret_cu_amanuntul,cod_intrare='MA'+ltrim(str(pozdoc.idpozdoc)), idIntrare=pozdoc.idPozDoc
	from pozdoc
	inner join #pozAvize diez on diez.idPozdoc=pozdoc.idPozdoc

	drop table #pozAvize

end try        
begin catch 
	declare @eroare varchar(200) 
	set @eroare='wOPAlinierePreturi:'+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
end
