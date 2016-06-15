--***
create procedure wIaActivitatiMasini @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaActivitatiMasiniSP' and type='P')      
	exec wIaActivitatiMasiniSP @sesiune,@parXML      
else      
begin
if object_id('tempdb..#activitati') is not null drop table #activitati
declare @eroare varchar(1000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	declare	@codMasina varchar(20), @searchtext varchar(30)
	select 
		@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''),
		@searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

	set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'

	select top 100
	a.data, 
	rtrim(pa.Fisa) as fisa, 
	rtrim(pa.Tip) as tip, 
	CONVERT(varchar,pa.Data_plecarii,101) as data_plecarii,
	SUBSTRING(pa.Ora_plecarii,1,2)+':'+SUBSTRING(pa.Ora_plecarii,3,2) as ora_plecarii,
	CONVERT(varchar, pa.Data_sosirii,101) as data_sosirii,
	SUBSTRING(pa.Ora_sosirii,1,2)+':'+SUBSTRING(pa.Ora_sosirii,3,2) as ora_sosirii,

	rtrim(pa.explicatii) as explicatii ,
	(case when pa.tip='FP' then
	   (rtrim(pa.Plecare))   
	   end) as  plecare ,   
	(case when pa.tip='FP' then
	   (rtrim(pa.Sosire))
	   end) as  sosire, pa.Numar_pozitie,
		pa.idPozActivitati
	into #activitati
	from pozactivitati pa
		 inner join activitati a on a.Tip=pa.Tip and a.Fisa=pa.Fisa and a.Data=pa.Data
	where a.Masina=@codMasina 
		  and pa.tip<>'FI'
		  and explicatii like '%'+@searchtext+'%'
	
	select max(convert(varchar,a.data,101)) /*(? format)*/ data, max(a.fisa) fisa, max(a.tip) tip, max(a.data_plecarii) data_plecarii, max(a.ora_plecarii) ora_plecarii, 
			max(a.data_sosirii) data_sosirii, max(a.ora_sosirii) ora_sosirii,
			max(a.explicatii) explicatii, max(a.plecare) plecare, max(a.sosire) sosire, 
			convert(decimal(15),max((case when ea.element in ('orebord','kmbord') then ea.Valoare else 0 end))) as bord,
			convert(decimal(15),sum((case when ea.element in ('kmef1','kmef2','kmef3','ol') then ea.Valoare else 0 end))) as efectiv,
			a.idPozActivitati
			from #activitati a
			left join elemactivitati ea on a.fisa=ea.Fisa and a.data=ea.Data and a.Numar_pozitie=ea.Numar_pozitie and a.tip=ea.Tip
				and ea.Element in ('orebord','kmbord','kmef1','kmef2','kmef3','ol')
	group by a.idPozActivitati
	order by a.idPozActivitati
	for xml raw

end try
begin catch
	set @eroare='wIaActivitatiMasini (linia '+convert(varchar(20),ERROR_LINE())+'):'+char(13)+'  '+ERROR_MESSAGE()
end catch

if object_id('tempdb..#activitati') is not null drop table #activitati
if len(@eroare)>0 raiserror(@eroare,16,1)
end
