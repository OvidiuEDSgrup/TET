--***
create procedure wIaInterventii (@sesiune varchar(50),@parXML XML)
--(@datajos datetime, @datasus datetime, @pMasina varchar(20), @pElement varchar(20))
as  
if exists(select * from sysobjects where name='wIaInterventiiSP' and type='P')      
	exec wIaInterventiiSP @sesiune,@parXML      
else      

begin

set transaction isolation level READ UNCOMMITTED

declare @eroare varchar(1000),  @pMasina varchar(20), @pElement varchar(20), @datajos datetime, @datasus datetime, @den_masina varchar(50),
		@codMasina varchar(40), @tipinterventii varchar(50), @cautare varchar(200),  @denumire varchar(50),
		@tipMasina varchar(20), @grupa varchar(3)
set @eroare=''

begin try
	/*	--tst	pt teste
	declare @pMasina varchar(20), @pElement varchar(20), @datajos datetime, @datasus datetime
	select @datajos='2011-1-1',@datasus='2011-8-31', @pMasina='1'--,@pElement='casco'
		-- precedenta: select * from fisamasina(@datajos, @datasus, @pMasina, @pElement,null)
	--*/
	---------------------------------------
	declare @userASiS varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	
	set @codMasina=REPLACE(ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(40)'), ''), ' ', '%')
	set @grupa=(select max(grupa) from masini m where m.cod_masina=@codMasina)
    set @tipMasina=(select max(g.tip_masina) from grupemasini g where g.Grupa=@grupa)
/*	if isnull(rtrim(@tipMasina),'')='' and @codMasina<>''
			 raiserror ('Nu s-a reusit identificarea tipului masinii!',16,1)*/
	select top 100
		masina, den_masina, nr_inmatriculare, element, denumire, 
		--tip
		(case when tip='R' then 'Recomandare' else 'Efectuata' end) as tip
		, fisa, 
		convert(varchar(20),data,101)
		/*	rtrim(case when km>0.01 or tip<>'R'
							then convert(varchar(20),data,103) else '<'+convert(varchar(20),data,103)+'>' end)	*/
		as data
		, km, 
		(case when f.tipInterval='D' then
			(case when tip='R' and isnull(data,'1901-1-1')<getdate() then '#FF0000' when tip<>'R' then '#000000' else '#00CC00' end)
			else (case when tip='R' and km<f.bord then '#FF0000' when tip<>'R' then '#000000' else '#00CC00' end)
		end)
			culoare 
		,explicatii, (case when f.tipInterval='D' then 'Data' else 'Activitate' end) tipInterval,
		rtrim(f.tipMasina) tipMasina, f.bord
		from dbo.fiainterventii(@sesiune, @parxml) f
	order by convert(varchar(20),data,102),element
    for xml raw

end try
begin catch
	set @eroare='wIaInterventii (linia '+convert(varchar(10),error_line())+') '+char(10)+
		rtrim(error_message())
end catch
end	
	
if object_id('tempdb.dbo.#interventii')>0 drop table #interventii
if object_id('tempdb.dbo.#efectuate')>0 drop table #efectuate
if object_id('tempdb.dbo.#date_estimate')>0 drop table #date_estimate

if rtrim(@eroare)<>''
	raiserror(@eroare,16,1)
